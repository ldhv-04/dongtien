import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../domain/budgeting/feasibility_advisor.dart';
import '../../../../domain/budgeting/goal_calculator.dart';
import '../../../../domain/forecasting/cash_flow_forecaster.dart';
import '../../../../domain/forecasting/recurrence_calculator.dart';
import '../../../../domain/ledger/account_kind.dart';
import '../../../../domain/ledger/post_transaction_command.dart';
import '../../../../domain/ledger/posting_matrix.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../envelopes/providers/envelope_providers.dart';

/// Selected segment on the Plans screen (0 = Budgets, 1 = Goals, 2 = Obligations & Forecast).
final plansSegmentIndexProvider = StateProvider<int>((ref) => 0);

/// Selected forecast horizon days (30, 60, or 90).
final forecastHorizonDaysProvider = StateProvider<int>((ref) => 30);

/// Stream of all scheduled items (both BILL and PLANNED_INCOME).
final allScheduledItemsStreamProvider =
    StreamProvider<List<ScheduledItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.scheduledItems)
        ..orderBy([(s) => OrderingTerm(expression: s.dueDateMs)]))
      .watch();
});

/// Savings Goals Feasibility Evaluation provider.
final feasibilityEvaluationProvider =
    Provider<AsyncValue<FeasibilityEvaluation>>((ref) {
  final envelopesAsync = ref.watch(envelopesStreamProvider);
  final summaryAsync = ref.watch(virtualFundsSummaryProvider);

  if (envelopesAsync.isLoading || summaryAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (envelopesAsync.hasError) {
    return AsyncValue.error(envelopesAsync.error!, envelopesAsync.stackTrace!);
  }

  final envelopes = envelopesAsync.value ?? [];
  final available = math.max(0, summaryAsync.value?.availableToAllocate ?? 0);
  final now = DateTime.now();

  final List<ActiveGoalItem> goals = [];
  for (final e in envelopes) {
    if (e.targetAmountVnd != null && e.targetAmountVnd! > 0) {
      final targetDt = e.targetDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(e.targetDateMs!)
          : DateTime(now.year, now.month + 6, now.day);
      final remainingMonths = GoalCalculator.calculateRemainingMonths(
        now,
        targetDt,
      );
      goals.add(
        ActiveGoalItem(
          id: e.id,
          name: e.name,
          targetAmount: VndMoney(math.max(0, e.targetAmountVnd!)),
          currentReserved: VndMoney(math.max(0, e.reservedBalanceVnd)),
          remainingPeriods: remainingMonths,
          priority: e.priority,
        ),
      );
    }
  }

  return AsyncValue.data(
    FeasibilityAdvisor.evaluatePlan(
      goals: goals,
      monthlyCapacity: VndMoney(available),
    ),
  );
});

/// 30/60/90-day Cash Flow Forecast provider.
final cashFlowForecastProvider =
    Provider<AsyncValue<CashFlowForecastResult>>((ref) {
  final liquidAsync = ref.watch(liquidAssetsStreamProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final itemsAsync = ref.watch(allScheduledItemsStreamProvider);
  final horizonDays = ref.watch(forecastHorizonDaysProvider);

  if (liquidAsync.isLoading ||
      settingsAsync.isLoading ||
      itemsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (liquidAsync.hasError) {
    return AsyncValue.error(liquidAsync.error!, liquidAsync.stackTrace!);
  }

  final liquid = liquidAsync.value ?? 0;
  final buffer = settingsAsync.value?.minimumCashBufferVnd ?? 0;
  final items = itemsAsync.value ?? [];

  final domainItems = items.map((s) {
    return ForecastScheduledItem(
      id: s.id,
      kind: ScheduledItemKind.fromString(s.kind),
      title: s.title,
      amount: VndMoney(s.amountVnd),
      dueDate: DateTime.fromMillisecondsSinceEpoch(s.dueDateMs),
      recurrence: s.recurrence,
      anchorDayOfMonth: s.anchorDayOfMonth,
      status: s.status,
    );
  }).toList();

  final result = CashFlowForecaster.project(
    startingLiquidAssets: VndMoney(liquid),
    minimumCashBuffer: VndMoney(buffer),
    scheduledItems: domainItems,
    startDate: DateTime.now(),
    horizonDays: horizonDays,
  );

  return AsyncValue.data(result);
});

/// Controller for Plans mutations (Budgets, Goals advisor one-tap actions, Scheduled Obligations).
class PlansController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Creates or updates a monthly category budget.
  Future<void> upsertCategoryBudget({
    required int categoryId,
    required int limitVnd,
    int? yearMonth,
    int alertThresholdPct = 80,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final ym = yearMonth ?? (now.year * 100 + now.month);

      final existing = await (db.select(db.categoryBudgets)
            ..where((b) =>
                b.categoryId.equals(categoryId) & b.yearMonth.equals(ym)))
          .getSingleOrNull();

      if (existing != null) {
        await (db.update(db.categoryBudgets)
              ..where((b) => b.id.equals(existing.id)))
            .write(
          CategoryBudgetsCompanion(
            limitVnd: Value(limitVnd),
            alertThresholdPct: Value(alertThresholdPct),
          ),
        );
      } else {
        await db.into(db.categoryBudgets).insert(
              CategoryBudgetsCompanion.insert(
                categoryId: categoryId,
                yearMonth: ym,
                limitVnd: limitVnd,
                alertThresholdPct: Value(alertThresholdPct),
              ),
            );
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// One-tap Calculator 1: Extends deadline of a goal to fit capacity.
  Future<void> applyExtendDeadline({
    required ActiveGoalItem goal,
    required VndMoney monthlyCapacity,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final effectiveCap = monthlyCapacity.amount > 0
          ? monthlyCapacity
          : VndMoney(math.max(1, goal.shortfall.amount ~/ 12));
      final newMonths = FeasibilityAdvisor.calculateExtendedDeadline(
        targetAmount: goal.targetAmount,
        currentReserved: goal.currentReserved,
        allocatedMonthlyCapacity: effectiveCap,
      );
      final now = DateTime.now();
      final newTargetDate = DateTime(
        now.year,
        now.month + math.max(1, newMonths),
        now.day,
      );
      await (db.update(db.envelopes)..where((e) => e.id.equals(goal.id))).write(
        EnvelopesCompanion(
          targetDateMs: Value(newTargetDate.millisecondsSinceEpoch),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// One-tap Calculator 2: Lowers target amount of a goal to fit capacity.
  Future<void> applyLowerTarget({
    required ActiveGoalItem goal,
    required VndMoney monthlyCapacity,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final lowered = FeasibilityAdvisor.calculateLoweredTarget(
        targetAmount: goal.targetAmount,
        currentReserved: goal.currentReserved,
        remainingPeriods: math.max(1, goal.remainingPeriods),
        allocatedMonthlyCapacity: monthlyCapacity,
      );
      final safeTarget = math.max(1, lowered.amount);
      await (db.update(db.envelopes)..where((e) => e.id.equals(goal.id))).write(
        EnvelopesCompanion(targetAmountVnd: Value(safeTarget)),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// One-tap Calculator 3: Pauses lower-priority goals that exceed capacity.
  Future<void> applyPauseLowerPriorityGoals({
    required List<ActiveGoalItem> goals,
    required VndMoney monthlyCapacity,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final actions = FeasibilityAdvisor.recommendGoalPruning(
        goals: goals,
        monthlyCapacity: monthlyCapacity,
      );
      for (final action in actions) {
        if (action.shouldPause) {
          await (db.update(db.envelopes)
                ..where((e) => e.id.equals(action.goal.id)))
              .write(
            const EnvelopesCompanion(targetAmountVnd: Value(null)),
          );
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Creates a new scheduled bill or planned income item.
  Future<int> createScheduledItem({
    required String kind, // 'BILL' or 'PLANNED_INCOME'
    required String title,
    required int amountVnd,
    required DateTime dueDate,
    String recurrence = 'NONE',
    int? anchorDayOfMonth,
    int? categoryId,
    int? linkedEnvelopeId,
    int reminderDaysBefore = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final id = await db.into(db.scheduledItems).insert(
            ScheduledItemsCompanion.insert(
              kind: kind,
              title: title,
              amountVnd: amountVnd,
              dueDateMs: dueDate.millisecondsSinceEpoch,
              recurrence: Value(recurrence),
              anchorDayOfMonth: Value(anchorDayOfMonth ?? dueDate.day),
              categoryId: Value(categoryId),
              linkedEnvelopeId: Value(linkedEnvelopeId),
              status: const Value('PENDING'),
              reminderDaysBefore: Value(reminderDaysBefore),
            ),
          );
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Marks a scheduled item as paid/received, atomically posting the real ledger transaction,
  /// consuming up to available envelope reserve (if linked), and advancing recurrence.
  Future<int> markScheduledItemPaid({
    required int scheduledItemId,
    int? accountId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final dao = ref.read(ledgerDaoProvider);

      final txId = await db.transaction(() async {
        final item = await (db.select(db.scheduledItems)
              ..where((s) => s.id.equals(scheduledItemId)))
            .getSingle();

        if (item.status != 'PENDING') {
          return item.paidTransactionId ?? 0;
        }

        // Resolve liquid account to pay from / receive into
        int targetAccountId = accountId ?? 0;
        if (targetAccountId == 0) {
          final accounts = await dao.getAccountsWithBalances();
          final liquid = accounts.where((a) => a.isLiquid).toList();
          if (liquid.isNotEmpty) {
            targetAccountId = liquid.first.id;
          } else {
            // Create a default Cash account if none exists yet
            targetAccountId = await db.into(db.ledgerAccounts).insert(
                  LedgerAccountsCompanion.insert(
                    name: 'Tiền mặt',
                    kind: AccountKind.assetCash.dbValue,
                    isLiquid: const Value(true),
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  ),
                );
          }
        }

        // Resolve category
        int targetCategoryId = item.categoryId ?? 0;
        if (targetCategoryId == 0) {
          final cats = await (db.select(db.categories)
                ..where((c) => c.kind.equals(
                    item.kind == 'PLANNED_INCOME' ? 'INCOME' : 'EXPENSE')))
              .get();
          targetCategoryId = cats.isNotEmpty ? cats.first.id : 1;
        }

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        int createdTxId;

        if (item.kind == 'PLANNED_INCOME') {
          createdTxId = await dao.postTransactionCommand(
            PostTransactionCommand.income(
              receivingAssetAccountId: targetAccountId,
              categoryId: targetCategoryId,
              amountVnd: item.amountVnd,
              occurredAt: nowMs,
              description: item.title,
            ),
          );
        } else {
          // BILL payment
          // Check linked envelope balance
          int? envelopeToLink = item.linkedEnvelopeId;
          int partialEnvelopeSpend = 0;

          if (envelopeToLink != null) {
            final targetEnvId = envelopeToLink;
            final env = await (db.select(db.envelopes)
                  ..where((e) => e.id.equals(targetEnvId)))
                .getSingleOrNull();
            if (env != null) {
              if (env.reservedBalanceVnd >= item.amountVnd ||
                  env.allowNegativeException) {
                // Standard full spend via postTransactionCommand
                partialEnvelopeSpend = 0;
              } else {
                // Partial coverage (Scenario 11: envelope has 1.0M, bill is 1.5M)
                partialEnvelopeSpend = math.max(0, env.reservedBalanceVnd);
                envelopeToLink = null;
              }
            } else {
              envelopeToLink = null;
            }
          }

          createdTxId = await dao.postTransaction(
            txType: 'EXPENSE',
            description: item.title,
            occurredAt: nowMs,
            postings: PostingMatrix.buildExpense(
              sourceAccountId: targetAccountId,
              categoryId: targetCategoryId,
              amountVnd: item.amountVnd,
              envelopeId: envelopeToLink ?? item.linkedEnvelopeId,
            ),
            linkedEnvelopeId: envelopeToLink,
            envelopeMovementType: envelopeToLink != null ? 'SPEND' : null,
          );

          if (partialEnvelopeSpend > 0 && item.linkedEnvelopeId != null) {
            await db.into(db.envelopeMovements).insert(
                  EnvelopeMovementsCompanion.insert(
                    movementType: 'SPEND',
                    amountVnd: partialEnvelopeSpend,
                    sourceEnvelopeId: Value(item.linkedEnvelopeId),
                    linkedTransactionId: Value(createdTxId),
                    linkedObligationId: Value(item.id),
                    occurredAt: nowMs,
                  ),
                );
            await db.customUpdate(
              'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
              variables: [
                Variable.withInt(partialEnvelopeSpend),
                Variable.withInt(item.linkedEnvelopeId!),
              ],
              updates: {db.envelopes},
            );
          }
        }

        // Update scheduled item status to PAID_OR_RECEIVED
        await (db.update(db.scheduledItems)..where((s) => s.id.equals(item.id)))
            .write(
          ScheduledItemsCompanion(
            status: const Value('PAID_OR_RECEIVED'),
            paidTransactionId: Value(createdTxId),
          ),
        );

        // If recurring, insert next occurrence preserving anchorDayOfMonth
        if (item.recurrence != 'NONE') {
          final currentDue =
              DateTime.fromMillisecondsSinceEpoch(item.dueDateMs);
          final nextDue = RecurrenceCalculator.computeNextDueDate(
            currentDueDate: currentDue,
            recurrence: item.recurrence,
            anchorDayOfMonth: item.anchorDayOfMonth,
          );
          await db.into(db.scheduledItems).insert(
                ScheduledItemsCompanion.insert(
                  kind: item.kind,
                  title: item.title,
                  amountVnd: item.amountVnd,
                  dueDateMs: nextDue.millisecondsSinceEpoch,
                  recurrence: Value(item.recurrence),
                  anchorDayOfMonth:
                      Value(item.anchorDayOfMonth ?? currentDue.day),
                  categoryId: Value(item.categoryId),
                  linkedEnvelopeId: Value(item.linkedEnvelopeId),
                  status: const Value('PENDING'),
                  reminderDaysBefore: Value(item.reminderDaysBefore),
                ),
              );
        }

        return createdTxId;
      });

      state = const AsyncValue.data(null);
      return txId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final plansControllerProvider =
    AsyncNotifierProvider<PlansController, void>(PlansController.new);
