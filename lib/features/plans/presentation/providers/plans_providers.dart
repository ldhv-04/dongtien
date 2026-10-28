import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/notifications/notification_scheduler.dart';
import '../../../../domain/budgeting/billing_cycle_calculator.dart';
import '../../../../domain/budgeting/feasibility_advisor.dart';
import '../../../../domain/budgeting/goal_calculator.dart';
import '../../../../domain/forecasting/cash_flow_forecaster.dart';
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
      int ym = yearMonth ?? 0;
      if (yearMonth == null) {
        final settings = await (db.select(db.settings)
              ..where((s) => s.id.equals(1)))
            .getSingleOrNull();
        final periodStartDay = (settings?.periodStartDay ?? 1).clamp(1, 28);
        ym = BillingCycleCalculator.calculate(now, periodStartDay).yearMonth;
      }

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

  /// Deletes a monthly category budget limit.
  Future<void> deleteCategoryBudget({
    required int categoryId,
    int? yearMonth,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      int ym = yearMonth ?? 0;
      if (yearMonth == null) {
        final settings = await (db.select(db.settings)
              ..where((s) => s.id.equals(1)))
            .getSingleOrNull();
        final periodStartDay = (settings?.periodStartDay ?? 1).clamp(1, 28);
        ym = BillingCycleCalculator.calculate(now, periodStartDay).yearMonth;
      }

      await (db.delete(db.categoryBudgets)
            ..where((b) =>
                b.categoryId.equals(categoryId) & b.yearMonth.equals(ym)))
          .go();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deletes a savings goal envelope.
  /// If reserved balance > 0, releases the balance back to liquid cash (available-to-allocate)
  /// before archiving the envelope and clearing its target amount.
  Future<void> deleteSavingsGoal(int envelopeId) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final envelopeDao = ref.read(envelopeDaoProvider);

      await db.transaction(() async {
        final env = await (db.select(db.envelopes)
              ..where((e) => e.id.equals(envelopeId)))
            .getSingle();

        // 1. Release reserved balance back to Available-to-Allocate if positive
        if (env.reservedBalanceVnd > 0) {
          await envelopeDao.release(
            envelopeId: envelopeId,
            amountVnd: env.reservedBalanceVnd,
          );
        }

        // 2. Archive envelope and reset target to null (decouples from feasibility advisor)
        await (db.update(db.envelopes)..where((e) => e.id.equals(envelopeId)))
            .write(
          const EnvelopesCompanion(
            isArchived: Value(true),
            targetAmountVnd: Value(null),
            targetDateMs: Value(null),
          ),
        );
      });

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
              recurrence: const Value('NONE'),
              anchorDayOfMonth: Value(anchorDayOfMonth ?? dueDate.day),
              categoryId: Value(categoryId),
              linkedEnvelopeId: Value(linkedEnvelopeId),
              status: const Value('PENDING'),
              reminderDaysBefore: Value(reminderDaysBefore),
            ),
          );
      if (kind == 'BILL') {
        final scheduler = ref.read(notificationSchedulerProvider);
        await scheduler.reconcileFromDatabase(db);
      }
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deletes a scheduled item.
  /// If status is PAID_OR_RECEIVED, atomically voids and reverses the linked
  /// journal transaction via LedgerDao.voidTransaction (inverting postings and
  /// restoring any linked envelope SPEND balance) before deleting the scheduled item.
  Future<void> deleteScheduledItem(int scheduledItemId) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final dao = ref.read(ledgerDaoProvider);

      await db.transaction(() async {
        final item = await (db.select(db.scheduledItems)
              ..where((s) => s.id.equals(scheduledItemId)))
            .getSingleOrNull();

        if (item == null) return;

        // 1. If paid/received, void the ledger transaction
        if (item.status == 'PAID_OR_RECEIVED' &&
            item.paidTransactionId != null) {
          final tx = await (db.select(db.journalTransactions)
                ..where((t) => t.id.equals(item.paidTransactionId!)))
              .getSingleOrNull();
          if (tx != null && tx.status == 'POSTED') {
            await dao.voidTransaction(item.paidTransactionId!);
          }
        }

        // 2. Delete the scheduled item row
        await (db.delete(db.scheduledItems)
              ..where((s) => s.id.equals(scheduledItemId)))
            .go();
      });

      // 3. Reconcile notifications
      final scheduler = ref.read(notificationSchedulerProvider);
      await scheduler.reconcileFromDatabase(db);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates an existing scheduled item.
  /// If status is PENDING, simply updates the scheduled item record.
  /// If status is PAID_OR_RECEIVED, atomically:
  ///   1. Voids old paidTransactionId via LedgerDao.voidTransaction.
  ///   2. Posts the updated transaction with new amount/category/envelope and fresh idempotency key.
  ///   3. Updates scheduled item record with new values and new paidTransactionId.
  Future<void> updateScheduledItem({
    required int scheduledItemId,
    required String kind,
    required String title,
    required int amountVnd,
    required DateTime dueDate,
    int? categoryId,
    int? linkedEnvelopeId,
    int reminderDaysBefore = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final dao = ref.read(ledgerDaoProvider);

      int? alertCategoryId;

      await db.transaction(() async {
        final item = await (db.select(db.scheduledItems)
              ..where((s) => s.id.equals(scheduledItemId)))
            .getSingle();

        int? newPaidTxId = item.paidTransactionId;

        if (item.status == 'PAID_OR_RECEIVED') {
          // Step 1: Void the old transaction if POSTED
          if (item.paidTransactionId != null) {
            final oldTx = await (db.select(db.journalTransactions)
                  ..where((t) => t.id.equals(item.paidTransactionId!)))
                .getSingleOrNull();
            if (oldTx != null && oldTx.status == 'POSTED') {
              await dao.voidTransaction(item.paidTransactionId!);
            }
          }

          // Step 2: Determine account used in original transaction or fallback to liquid account
          int targetAccountId = 0;
          if (item.paidTransactionId != null) {
            final oldPostings = await (db.select(db.journalPostings)
                  ..where(
                      (p) => p.transactionId.equals(item.paidTransactionId!)))
                .get();
            final assetLeg = oldPostings.cast<JournalPosting?>().firstWhere(
                  (p) => kind == 'BILL' ? p!.creditVnd > 0 : p!.debitVnd > 0,
                  orElse: () => null,
                );
            if (assetLeg != null) {
              targetAccountId = assetLeg.accountId;
            }
          }
          if (targetAccountId == 0) {
            final accounts = await dao.getAccountsWithBalances();
            final liquid = accounts.where((a) => a.isLiquid).toList();
            targetAccountId = liquid.isNotEmpty ? liquid.first.id : 1;
          }

          // Step 3: Resolve category with strict isolation
          int targetCategoryId = 0;
          if (categoryId != null && categoryId > 0) {
            final existingCat = await (db.select(db.categories)
                  ..where((c) => c.id.equals(categoryId)))
                .getSingleOrNull();
            if (existingCat != null) {
              targetCategoryId = existingCat.id;
            }
          }
          if (targetCategoryId == 0 &&
              item.categoryId != null &&
              item.categoryId! > 0) {
            final existingCat = await (db.select(db.categories)
                  ..where((c) => c.id.equals(item.categoryId!)))
                .getSingleOrNull();
            if (existingCat != null) {
              targetCategoryId = existingCat.id;
            }
          }

          if (targetCategoryId == 0) {
            final cats = await (db.select(db.categories)
                  ..where((c) => c.kind
                      .equals(kind == 'PLANNED_INCOME' ? 'INCOME' : 'EXPENSE')))
                .get();
            if (kind == 'BILL') {
              final defaultCat = cats.cast<Category?>().firstWhere(
                    (c) => c!.name == 'Hoá đơn & Tiện ích',
                    orElse: () => cats.cast<Category?>().firstWhere(
                      (c) => c!.name == 'Nhà cửa',
                      orElse: () {
                        final nonFood =
                            cats.where((c) => c.name != 'Ăn uống').toList();
                        return nonFood.isNotEmpty
                            ? nonFood.first
                            : (cats.isNotEmpty ? cats.first : null);
                      },
                    ),
                  );
              targetCategoryId = defaultCat?.id ?? 1;
            } else {
              final defaultCat = cats.cast<Category?>().firstWhere(
                    (c) => c!.name == 'Lương',
                    orElse: () => cats.cast<Category?>().firstWhere(
                          (c) => c!.name == 'Thưởng',
                          orElse: () => cats.isNotEmpty ? cats.first : null,
                        ),
                  );
              targetCategoryId = defaultCat?.id ?? 1;
            }
          }

          if (kind == 'BILL') {
            alertCategoryId = targetCategoryId;
          }

          // Step 4: Post new replacement transaction
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final revKey = 'scheduled_pay_${item.id}_rev_$nowMs';

          if (kind == 'PLANNED_INCOME') {
            newPaidTxId = await dao.postTransactionCommand(
              PostTransactionCommand.income(
                receivingAssetAccountId: targetAccountId,
                categoryId: targetCategoryId,
                amountVnd: amountVnd,
                occurredAt: nowMs,
                description: title,
                idempotencyKey: revKey,
              ),
            );
          } else {
            // BILL
            int? envelopeToLink = linkedEnvelopeId;
            int partialEnvelopeSpend = 0;
            if (envelopeToLink != null) {
              final env = await (db.select(db.envelopes)
                    ..where((e) => e.id.equals(envelopeToLink!)))
                  .getSingleOrNull();
              if (env != null) {
                if (env.reservedBalanceVnd >= amountVnd ||
                    env.allowNegativeException) {
                  partialEnvelopeSpend = 0;
                } else {
                  partialEnvelopeSpend = math.max(0, env.reservedBalanceVnd);
                  envelopeToLink = null;
                }
              } else {
                envelopeToLink = null;
              }
            }

            newPaidTxId = await dao.postTransaction(
              txType: 'EXPENSE',
              description: title,
              occurredAt: nowMs,
              postings: PostingMatrix.buildExpense(
                sourceAccountId: targetAccountId,
                categoryId: targetCategoryId,
                amountVnd: amountVnd,
                envelopeId: envelopeToLink ?? linkedEnvelopeId,
              ),
              idempotencyKey: revKey,
              linkedEnvelopeId: envelopeToLink,
              envelopeMovementType: envelopeToLink != null ? 'SPEND' : null,
            );

            if (partialEnvelopeSpend > 0 && linkedEnvelopeId != null) {
              await db.into(db.envelopeMovements).insert(
                    EnvelopeMovementsCompanion.insert(
                      movementType: 'SPEND',
                      amountVnd: partialEnvelopeSpend,
                      sourceEnvelopeId: Value(linkedEnvelopeId),
                      linkedTransactionId: Value(newPaidTxId),
                      linkedObligationId: Value(item.id),
                      occurredAt: nowMs,
                    ),
                  );
              await db.customUpdate(
                'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
                variables: [
                  Variable.withInt(partialEnvelopeSpend),
                  Variable.withInt(linkedEnvelopeId),
                ],
                updates: {db.envelopes},
              );
            }
          }
        }

        // Step 5: Update scheduled item record
        await (db.update(db.scheduledItems)..where((s) => s.id.equals(item.id)))
            .write(
          ScheduledItemsCompanion(
            title: Value(title),
            kind: Value(kind),
            amountVnd: Value(amountVnd),
            dueDateMs: Value(dueDate.millisecondsSinceEpoch),
            anchorDayOfMonth: Value(dueDate.day),
            categoryId: Value(categoryId),
            linkedEnvelopeId: Value(linkedEnvelopeId),
            paidTransactionId: Value(newPaidTxId),
            reminderDaysBefore: Value(reminderDaysBefore),
          ),
        );
      });

      // Step 6: Reconcile notifications and threshold alerts
      final scheduler = ref.read(notificationSchedulerProvider);
      await scheduler.reconcileFromDatabase(db);
      if (alertCategoryId != null) {
        await scheduler.checkCategoryBudgetAlert(
          db: db,
          categoryId: alertCategoryId!,
        );
      }

      state = const AsyncValue.data(null);
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

      int? alertCategoryId;
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

        // Resolve category with strict isolation (Option B)
        int targetCategoryId = 0;
        if (item.categoryId != null && item.categoryId! > 0) {
          final existingCat = await (db.select(db.categories)
                ..where((c) => c.id.equals(item.categoryId!)))
              .getSingleOrNull();
          if (existingCat != null) {
            targetCategoryId = existingCat.id;
          }
        }

        if (targetCategoryId == 0) {
          final isBill = item.kind == 'BILL';
          final desiredKind = isBill ? 'EXPENSE' : 'INCOME';
          final cats = await (db.select(db.categories)
                ..where((c) => c.kind.equals(desiredKind)))
              .get();

          if (isBill) {
            // Default legacy/null bill category:
            // 1. 'Hoá đơn & Tiện ích'
            // 2. 'Nhà cửa'
            // 3. Any non-food expense category if available
            // 4. NEVER cats.first ('Ăn uống') unless it is the only category in db
            final defaultBillCat = cats.cast<Category?>().firstWhere(
                  (c) => c!.name == 'Hoá đơn & Tiện ích',
                  orElse: () => cats.cast<Category?>().firstWhere(
                    (c) => c!.name == 'Nhà cửa',
                    orElse: () {
                      final nonFood =
                          cats.where((c) => c.name != 'Ăn uống').toList();
                      return nonFood.isNotEmpty
                          ? nonFood.first
                          : (cats.isNotEmpty ? cats.first : null);
                    },
                  ),
                );
            targetCategoryId = defaultBillCat?.id ?? 1;
          } else {
            // Default legacy/null income category:
            // 1. 'Lương'
            // 2. 'Thưởng'
            final defaultIncomeCat = cats.cast<Category?>().firstWhere(
                  (c) => c!.name == 'Lương',
                  orElse: () => cats.cast<Category?>().firstWhere(
                        (c) => c!.name == 'Thưởng',
                        orElse: () => cats.isNotEmpty ? cats.first : null,
                      ),
                );
            targetCategoryId = defaultIncomeCat?.id ?? 1;
          }
        }

        if (item.kind == 'BILL') {
          alertCategoryId = targetCategoryId;
        }

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final payKey = 'scheduled_pay_${item.id}';
        int createdTxId;

        if (item.kind == 'PLANNED_INCOME') {
          createdTxId = await dao.postTransactionCommand(
            PostTransactionCommand.income(
              receivingAssetAccountId: targetAccountId,
              categoryId: targetCategoryId,
              amountVnd: item.amountVnd,
              occurredAt: nowMs,
              description: item.title,
              idempotencyKey: payKey,
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
            idempotencyKey: payKey,
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

        return createdTxId;
      });

      final scheduler = ref.read(notificationSchedulerProvider);
      await scheduler.reconcileFromDatabase(db);
      if (alertCategoryId != null) {
        await scheduler.checkCategoryBudgetAlert(
          db: db,
          categoryId: alertCategoryId!,
        );
      }

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
