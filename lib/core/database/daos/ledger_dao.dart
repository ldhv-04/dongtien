import 'package:drift/drift.dart';
import '../../../domain/envelopes/available_to_allocate.dart';
import '../../../domain/ledger/account_kind.dart';
import '../../../domain/ledger/ledger_exceptions.dart';
import '../../../domain/ledger/post_transaction_command.dart';
import '../../../domain/ledger/posting_leg.dart';
import '../../../domain/ledger/posting_matrix.dart';
import '../app_database.dart';

part 'ledger_dao.g.dart';

/// Account model bundled with its dynamically computed ledger balance.
class AccountWithBalance {
  final int id;
  final String name;
  final AccountKind kind;
  final bool isLiquid;
  final int creditLimit;
  final int balanceVnd;

  const AccountWithBalance({
    required this.id,
    required this.name,
    required this.kind,
    required this.isLiquid,
    required this.creditLimit,
    required this.balanceVnd,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountWithBalance &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          kind == other.kind &&
          isLiquid == other.isLiquid &&
          creditLimit == other.creditLimit &&
          balanceVnd == other.balanceVnd;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        kind,
        isLiquid,
        creditLimit,
        balanceVnd,
      );

  @override
  String toString() =>
      'AccountWithBalance(id: $id, name: "$name", kind: ${kind.name}, isLiquid: $isLiquid, balance: $balanceVnd ₫)';
}

@DriftAccessor(tables: [
  LedgerAccounts,
  Categories,
  JournalTransactions,
  JournalPostings,
  Envelopes,
  EnvelopeMovements,
  Settings,
])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.db);

  /// Posts a balanced journal transaction atomically inside an SQLite transaction.
  ///
  /// Invariant: Asserts `SUM(debit_vnd) == SUM(credit_vnd)`.
  Future<int> postTransaction({
    required String txType,
    required String description,
    required int occurredAt,
    required List<PostingLeg> postings,
    String? idempotencyKey,
    int? linkedEnvelopeId,
    String? envelopeMovementType, // 'SPEND' or 'REFUND_RESTORE'
  }) async {
    // 1. Pure Dart Invariant Assertion
    PostingMatrix.assertBalanced(postings);

    return db.transaction(() async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 2. Validate Linked Envelope & Deficit if SPEND
      int movementAmount = 0;
      if (linkedEnvelopeId != null && envelopeMovementType != null) {
        // Calculate the movement amount from postings
        for (final leg in postings) {
          if (leg.envelopeId == linkedEnvelopeId) {
            movementAmount += leg.debitVnd > 0 ? leg.debitVnd : leg.creditVnd;
          }
        }
        if (movementAmount == 0) {
          movementAmount = postings.fold<int>(
            0,
            (max, leg) => leg.debitVnd > max
                ? leg.debitVnd
                : (leg.creditVnd > max ? leg.creditVnd : max),
          );
        }

        if (envelopeMovementType == 'SPEND') {
          final targetEnv = await (select(envelopes)
                ..where((e) => e.id.equals(linkedEnvelopeId)))
              .getSingleOrNull();
          if (targetEnv == null) {
            throw InvalidTransactionException(
              'Linked envelope $linkedEnvelopeId not found',
            );
          }

          if (movementAmount > 0) {
            AvailableToAllocateCalculator.validateSpending(
              spendAmountVnd: movementAmount,
              reservedBalanceVnd: targetEnv.reservedBalanceVnd,
              allowNegativeException: targetEnv.allowNegativeException,
              envelopeId: linkedEnvelopeId,
            );
          }
        }
      }

      // 3. Insert Transaction Record
      final txId = await into(journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: txType,
          status: const Value('POSTED'),
          description: Value(description),
          occurredAt: occurredAt,
          createdAt: nowMs,
          idempotencyKey: Value(idempotencyKey),
        ),
      );

      // 4. Batch Insert All Posting Legs
      await batch((b) {
        for (final leg in postings) {
          b.insert(
            journalPostings,
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: leg.accountId,
              debitVnd: Value(leg.debitVnd),
              creditVnd: Value(leg.creditVnd),
              categoryId: Value(leg.categoryId),
              envelopeId: Value(leg.envelopeId ?? linkedEnvelopeId),
            ),
          );
        }
      });

      // 5. Handle Linked Envelope Movement if specified
      if (linkedEnvelopeId != null &&
          envelopeMovementType != null &&
          movementAmount > 0) {
        if (envelopeMovementType == 'SPEND') {
          await into(envelopeMovements).insert(
            EnvelopeMovementsCompanion.insert(
              movementType: 'SPEND',
              amountVnd: movementAmount,
              sourceEnvelopeId: Value(linkedEnvelopeId),
              linkedTransactionId: Value(txId),
              occurredAt: occurredAt,
            ),
          );
          await customUpdate(
            'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
            variables: [
              Variable.withInt(movementAmount),
              Variable.withInt(linkedEnvelopeId),
            ],
            updates: {envelopes},
          );
        } else if (envelopeMovementType == 'REFUND_RESTORE') {
          await into(envelopeMovements).insert(
            EnvelopeMovementsCompanion.insert(
              movementType: 'REFUND_RESTORE',
              amountVnd: movementAmount,
              destEnvelopeId: Value(linkedEnvelopeId),
              linkedTransactionId: Value(txId),
              occurredAt: occurredAt,
            ),
          );
          await customUpdate(
            'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ? WHERE id = ?',
            variables: [
              Variable.withInt(movementAmount),
              Variable.withInt(linkedEnvelopeId),
            ],
            updates: {envelopes},
          );
        }
      }

      return txId;
    });
  }

  /// Convenience method to post a type-safe [PostTransactionCommand].
  Future<int> postTransactionCommand(PostTransactionCommand command) {
    return postTransaction(
      txType: command.txType.dbValue,
      description: command.description,
      occurredAt: command.occurredAt,
      postings: command.postings,
      idempotencyKey: command.idempotencyKey,
      linkedEnvelopeId: command.linkedEnvelopeId,
      envelopeMovementType: command.envelopeMovementType,
    );
  }

  /// Voids an active transaction and creates an audit REVERSAL record.
  ///
  /// Preserves ledger history: original transaction status -> 'VOIDED',
  /// reversal transaction -> 'POSTED' with inverted postings and offsetting envelope movements.
  Future<int> voidTransaction(int transactionId) async {
    return db.transaction(() async {
      final target = await (select(journalTransactions)
            ..where((t) => t.id.equals(transactionId)))
          .getSingleOrNull();

      if (target == null) {
        throw InvalidTransactionException(
            'Transaction $transactionId not found');
      }
      if (target.status != 'POSTED') {
        throw InvalidTransactionException(
          'Cannot void transaction in status "${target.status}". Only POSTED transactions can be voided.',
        );
      }
      if (target.txType == 'REVERSAL') {
        throw const InvalidTransactionException(
          'Cannot void a REVERSAL transaction. Reversals are immutable audit records.',
        );
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Mark target VOIDED
      await (update(journalTransactions)
            ..where((t) => t.id.equals(transactionId)))
          .write(
        const JournalTransactionsCompanion(status: Value('VOIDED')),
      );

      // 2. Insert REVERSAL Transaction
      final reversalTxId = await into(journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'REVERSAL',
          status: const Value('POSTED'),
          description: Value('Hoàn tác: ${target.description}'),
          occurredAt: target.occurredAt,
          createdAt: nowMs,
          reversesTxId: Value(target.id),
        ),
      );

      // 3. Fetch & Invert Postings
      final originalPostings = await (select(journalPostings)
            ..where((p) => p.transactionId.equals(transactionId)))
          .get();

      await batch((b) {
        for (final p in originalPostings) {
          b.insert(
            journalPostings,
            JournalPostingsCompanion.insert(
              transactionId: reversalTxId,
              accountId: p.accountId,
              debitVnd: Value(p.creditVnd),
              creditVnd: Value(p.debitVnd),
              categoryId: Value(p.categoryId),
              envelopeId: Value(p.envelopeId),
            ),
          );
        }
      });

      // 4. Reverse Linked Envelope Movements
      final movements = await (select(envelopeMovements)
            ..where((m) => m.linkedTransactionId.equals(transactionId)))
          .get();

      for (final m in movements) {
        if (m.movementType == 'SPEND' && m.sourceEnvelopeId != null) {
          // Restore spent amount
          await into(envelopeMovements).insert(
            EnvelopeMovementsCompanion.insert(
              movementType: 'REVERSAL',
              amountVnd: m.amountVnd,
              destEnvelopeId: Value(m.sourceEnvelopeId),
              linkedTransactionId: Value(reversalTxId),
              occurredAt: nowMs,
            ),
          );
          await customUpdate(
            'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ? WHERE id = ?',
            variables: [
              Variable.withInt(m.amountVnd),
              Variable.withInt(m.sourceEnvelopeId!),
            ],
            updates: {envelopes},
          );
        } else if (m.movementType == 'REFUND_RESTORE' &&
            m.destEnvelopeId != null) {
          // Re-deduct restored amount
          await into(envelopeMovements).insert(
            EnvelopeMovementsCompanion.insert(
              movementType: 'REVERSAL',
              amountVnd: m.amountVnd,
              sourceEnvelopeId: Value(m.destEnvelopeId),
              linkedTransactionId: Value(reversalTxId),
              occurredAt: nowMs,
            ),
          );
          await customUpdate(
            'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
            variables: [
              Variable.withInt(m.amountVnd),
              Variable.withInt(m.destEnvelopeId!),
            ],
            updates: {envelopes},
          );
        }
      }

      return reversalTxId;
    });
  }

  /// Edits an active transaction by voiding the original and posting a replacement transaction.
  ///
  /// State transitions:
  /// - Original transaction status -> 'SUPERSEDED'
  /// - Original replaced_by_tx_id -> newTxId
  /// - Reversal transaction created for original
  /// - Replacement transaction created with status 'POSTED'
  Future<int> editTransaction({
    required int originalTxId,
    required String txType,
    required String description,
    required int occurredAt,
    required List<PostingLeg> newPostings,
    int? linkedEnvelopeId,
    String? envelopeMovementType,
  }) async {
    return db.transaction(() async {
      // 1. Void & reverse original
      await voidTransaction(originalTxId);

      // 2. Update original status from VOIDED to SUPERSEDED
      await (update(journalTransactions)
            ..where((t) => t.id.equals(originalTxId)))
          .write(
        const JournalTransactionsCompanion(status: Value('SUPERSEDED')),
      );

      // 3. Post replacement transaction
      final newTxId = await postTransaction(
        txType: txType,
        description: description,
        occurredAt: occurredAt,
        postings: newPostings,
        linkedEnvelopeId: linkedEnvelopeId,
        envelopeMovementType: envelopeMovementType,
      );

      // 4. Link replaced_by_tx_id on original
      await (update(journalTransactions)
            ..where((t) => t.id.equals(originalTxId)))
          .write(
        JournalTransactionsCompanion(replacedByTxId: Value(newTxId)),
      );

      return newTxId;
    });
  }

  /// Derives dynamic balance for a single account from all journal postings.
  ///
  /// - Asset / Expense: SUM(debit_vnd) - SUM(credit_vnd)
  /// - Liability / Income / Equity: SUM(credit_vnd) - SUM(debit_vnd)
  Future<int> getAccountBalance(int accountId) async {
    final account = await (select(ledgerAccounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingle();

    final result = await customSelect(
      'SELECT COALESCE(SUM(debit_vnd), 0) AS total_debit, '
      'COALESCE(SUM(credit_vnd), 0) AS total_credit '
      'FROM journal_postings WHERE account_id = ?',
      variables: [Variable.withInt(accountId)],
      readsFrom: {journalPostings},
    ).getSingle();

    final debit = result.read<int>('total_debit');
    final credit = result.read<int>('total_credit');
    final kind = AccountKind.fromDbValue(account.kind);

    return kind.isDebitNormal ? (debit - credit) : (credit - debit);
  }

  /// Watches all active accounts paired with their derived dynamic balances.
  Stream<List<AccountWithBalance>> watchAccountsWithBalances() {
    return customSelect(
      'SELECT a.id, a.name, a.kind, a.is_liquid, a.credit_limit, a.is_archived, '
      'COALESCE(SUM(p.debit_vnd), 0) AS total_debit, '
      'COALESCE(SUM(p.credit_vnd), 0) AS total_credit '
      'FROM ledger_accounts a '
      'LEFT JOIN journal_postings p ON a.id = p.account_id '
      'WHERE a.is_archived = 0 '
      'GROUP BY a.id ORDER BY a.id ASC',
      readsFrom: {ledgerAccounts, journalPostings},
    ).watch().map((rows) {
      return rows.map((r) {
        final kind = AccountKind.fromDbValue(r.read<String>('kind'));
        final debit = r.read<int>('total_debit');
        final credit = r.read<int>('total_credit');
        final balance =
            kind.isDebitNormal ? (debit - credit) : (credit - debit);

        return AccountWithBalance(
          id: r.read<int>('id'),
          name: r.read<String>('name'),
          kind: kind,
          isLiquid: r.read<bool>('is_liquid'),
          creditLimit: r.read<int>('credit_limit'),
          balanceVnd: balance,
        );
      }).toList();
    });
  }

  /// Reads active accounts paired with derived dynamic balances once.
  Future<List<AccountWithBalance>> getAccountsWithBalances() async {
    final rows = await customSelect(
      'SELECT a.id, a.name, a.kind, a.is_liquid, a.credit_limit, a.is_archived, '
      'COALESCE(SUM(p.debit_vnd), 0) AS total_debit, '
      'COALESCE(SUM(p.credit_vnd), 0) AS total_credit '
      'FROM ledger_accounts a '
      'LEFT JOIN journal_postings p ON a.id = p.account_id '
      'WHERE a.is_archived = 0 '
      'GROUP BY a.id ORDER BY a.id ASC',
      readsFrom: {ledgerAccounts, journalPostings},
    ).get();

    return rows.map((r) {
      final kind = AccountKind.fromDbValue(r.read<String>('kind'));
      final debit = r.read<int>('total_debit');
      final credit = r.read<int>('total_credit');
      final balance = kind.isDebitNormal ? (debit - credit) : (credit - debit);

      return AccountWithBalance(
        id: r.read<int>('id'),
        name: r.read<String>('name'),
        kind: kind,
        isLiquid: r.read<bool>('is_liquid'),
        creditLimit: r.read<int>('credit_limit'),
        balanceVnd: balance,
      );
    }).toList();
  }

  /// Watches total liquid assets across active accounts where is_liquid == 1.
  Stream<int> watchTotalLiquidAssets() {
    return watchAccountsWithBalances().map((accounts) {
      return accounts
          .where((a) => a.isLiquid)
          .fold<int>(0, (sum, a) => sum + a.balanceVnd);
    });
  }

  /// Reads total liquid assets once.
  Future<int> getTotalLiquidAssets() async {
    final accounts = await getAccountsWithBalances();
    return accounts
        .where((a) => a.isLiquid)
        .fold<int>(0, (sum, a) => sum + a.balanceVnd);
  }

  /// Watches net worth: Total Assets - Total Liabilities.
  Stream<int> watchNetWorth() {
    return watchAccountsWithBalances().map((accounts) {
      int totalAssets = 0;
      int totalLiabilities = 0;
      for (final a in accounts) {
        if (a.kind == AccountKind.assetCash ||
            a.kind == AccountKind.assetBank) {
          totalAssets += a.balanceVnd;
        } else if (a.kind == AccountKind.liabilityCreditCard) {
          totalLiabilities += a.balanceVnd;
        }
      }
      return totalAssets - totalLiabilities;
    });
  }

  /// Reads net worth once.
  Future<int> getNetWorth() async {
    final accounts = await getAccountsWithBalances();
    int totalAssets = 0;
    int totalLiabilities = 0;
    for (final a in accounts) {
      if (a.kind == AccountKind.assetCash || a.kind == AccountKind.assetBank) {
        totalAssets += a.balanceVnd;
      } else if (a.kind == AccountKind.liabilityCreditCard) {
        totalLiabilities += a.balanceVnd;
      }
    }
    return totalAssets - totalLiabilities;
  }

  /// Clean UI Transaction stream (filters out VOIDED, SUPERSEDED, and REVERSAL).
  Stream<List<JournalTransaction>> watchCleanTransactions() {
    return (select(journalTransactions)
          ..where((t) =>
              t.status.equals('POSTED') & t.txType.equals('REVERSAL').not())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Clean UI Transaction query.
  Future<List<JournalTransaction>> getCleanTransactions() {
    return (select(journalTransactions)
          ..where((t) =>
              t.status.equals('POSTED') & t.txType.equals('REVERSAL').not())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .get();
  }
}
