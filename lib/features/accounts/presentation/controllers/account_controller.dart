import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../domain/ledger/account_kind.dart';
import '../../../../domain/ledger/post_transaction_command.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// Controller for creating and updating Cash, Bank, and Credit Card accounts.
class AccountController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> createAccount({
    required String name,
    required AccountKind kind,
    int creditLimitVnd = 0,
    int openingBalanceVnd = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final dao = ref.read(ledgerDaoProvider);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final accountId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: name,
              kind: kind.dbValue,
              isLiquid: Value(kind.isLiquid),
              creditLimit: Value(creditLimitVnd),
              isArchived: const Value(false),
              createdAt: nowMs,
            ),
          );

      if (openingBalanceVnd > 0) {
        if (kind.isLiquid) {
          await dao.postTransactionCommand(
            PostTransactionCommand.openingAsset(
              assetAccountId: accountId,
              amountVnd: openingBalanceVnd,
              occurredAt: nowMs,
            ),
          );
        } else if (kind == AccountKind.liabilityCreditCard) {
          await dao.postTransactionCommand(
            PostTransactionCommand.openingDebt(
              creditCardAccountId: accountId,
              amountVnd: openingBalanceVnd,
              occurredAt: nowMs,
            ),
          );
        }
      }

      state = const AsyncValue.data(null);
      return accountId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateAccount({
    required int id,
    required String name,
    int creditLimitVnd = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      await (db.update(db.ledgerAccounts)..where((a) => a.id.equals(id))).write(
        LedgerAccountsCompanion(
          name: Value(name),
          creditLimit: Value(creditLimitVnd),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, void>(AccountController.new);
