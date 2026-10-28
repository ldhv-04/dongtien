import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../domain/ledger/account_kind.dart';
import '../../../../domain/ledger/posting_matrix.dart';
import '../../../../domain/ledger/transaction_type.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/models/day_grouped_transactions.dart';
import '../../domain/models/transaction_item.dart';

/// Stream of clean transactions (POSTED and not REVERSAL).
final cleanTransactionsStreamProvider =
    StreamProvider<List<JournalTransaction>>((ref) {
  return ref.watch(ledgerDaoProvider).watchCleanTransactions();
});

/// Stream of all journal postings.
final allPostingsStreamProvider = StreamProvider<List<JournalPosting>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.journalPostings).watch();
});

/// Stream of all active categories.
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)..where((c) => c.isArchived.equals(false)))
      .watch();
});

/// Stream of net worth.
final netWorthStreamProvider = StreamProvider<int>((ref) {
  return ref.watch(ledgerDaoProvider).watchNetWorth();
});

/// Filter state for the Transactions screen.
class TransactionFilterState {
  final String searchQuery;
  final TransactionType? typeFilter;
  final int? accountIdFilter;
  final int? categoryIdFilter;
  final int? envelopeIdFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({
    this.searchQuery = '',
    this.typeFilter,
    this.accountIdFilter,
    this.categoryIdFilter,
    this.envelopeIdFilter,
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    String? searchQuery,
    TransactionType? typeFilter,
    int? accountIdFilter,
    int? categoryIdFilter,
    int? envelopeIdFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearAccount = false,
    bool clearCategory = false,
    bool clearEnvelope = false,
    bool clearDates = false,
  }) {
    return TransactionFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      accountIdFilter:
          clearAccount ? null : (accountIdFilter ?? this.accountIdFilter),
      categoryIdFilter:
          clearCategory ? null : (categoryIdFilter ?? this.categoryIdFilter),
      envelopeIdFilter:
          clearEnvelope ? null : (envelopeIdFilter ?? this.envelopeIdFilter),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

class TransactionFilterNotifier extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() => const TransactionFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(TransactionType? type) {
    state = state.copyWith(typeFilter: type, clearType: type == null);
  }

  void setAccountFilter(int? accountId) {
    state = state.copyWith(
        accountIdFilter: accountId, clearAccount: accountId == null);
  }

  void setCategoryFilter(int? categoryId) {
    state = state.copyWith(
        categoryIdFilter: categoryId, clearCategory: categoryId == null);
  }

  void setEnvelopeFilter(int? envelopeId) {
    state = state.copyWith(
        envelopeIdFilter: envelopeId, clearEnvelope: envelopeId == null);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      clearDates: start == null && end == null,
    );
  }

  void resetFilters() {
    state = const TransactionFilterState();
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilterState>(
  TransactionFilterNotifier.new,
);

/// Enriched & filtered transactions provider.
final enrichedTransactionsProvider =
    Provider<AsyncValue<List<TransactionItem>>>((ref) {
  final txAsync = ref.watch(cleanTransactionsStreamProvider);
  final postingsAsync = ref.watch(allPostingsStreamProvider);
  final accountsAsync = ref.watch(accountsWithBalancesStreamProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  final envelopesAsync = ref.watch(envelopesStreamProvider);
  final filter = ref.watch(transactionFilterProvider);

  if (txAsync.isLoading ||
      postingsAsync.isLoading ||
      accountsAsync.isLoading ||
      categoriesAsync.isLoading ||
      envelopesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (txAsync.hasError) {
    return AsyncValue.error(txAsync.error!, txAsync.stackTrace!);
  }

  final rawTxs = txAsync.value ?? <JournalTransaction>[];
  final rawPostings = postingsAsync.value ?? <JournalPosting>[];
  final accountMap = <int, AccountWithBalance>{
    for (final a in accountsAsync.value ?? <AccountWithBalance>[]) a.id: a,
  };
  final categoryMap = <int, Category>{
    for (final c in categoriesAsync.value ?? <Category>[]) c.id: c,
  };
  final envelopeMap = <int, Envelope>{
    for (final e in envelopesAsync.value ?? <Envelope>[]) e.id: e,
  };

  final postingsByTx = <int, List<JournalPosting>>{};
  for (final p in rawPostings) {
    postingsByTx.putIfAbsent(p.transactionId, () => []).add(p);
  }

  final List<TransactionItem> items = [];

  for (final tx in rawTxs) {
    final txPostings = postingsByTx[tx.id] ?? [];
    final type = TransactionType.fromDbValue(tx.txType);

    int amountVnd = 0;
    Category? category;
    Envelope? linkedEnvelope;
    AccountWithBalance? sourceAccount;
    AccountWithBalance? destinationAccount;

    for (final p in txPostings) {
      if (p.debitVnd > amountVnd) {
        amountVnd = p.debitVnd;
      }
      if (p.categoryId != null && category == null) {
        category = categoryMap[p.categoryId!];
      }
      if (p.envelopeId != null && linkedEnvelope == null) {
        linkedEnvelope = envelopeMap[p.envelopeId!];
      }
    }

    for (final p in txPostings) {
      final acc = accountMap[p.accountId];
      if (acc == null) continue;
      final isSystem = acc.id == PostingMatrix.equityOpeningAccountId ||
          acc.id == PostingMatrix.defaultIncomeAccountId ||
          acc.id == PostingMatrix.defaultExpenseAccountId ||
          acc.kind == AccountKind.income ||
          acc.kind == AccountKind.expense ||
          acc.kind == AccountKind.equityOpening;
      if (isSystem) continue;

      if (p.creditVnd > 0) {
        sourceAccount = acc;
      } else if (p.debitVnd > 0) {
        destinationAccount = acc;
      }
    }

    final item = TransactionItem(
      transaction: tx,
      amountVnd: amountVnd,
      type: type,
      category: category,
      sourceAccount: sourceAccount,
      destinationAccount: destinationAccount,
      linkedEnvelope: linkedEnvelope,
      postings: txPostings,
    );

    // Apply filters
    if (filter.typeFilter != null && item.type != filter.typeFilter) {
      continue;
    }
    if (filter.accountIdFilter != null) {
      final matchesAccount = item.sourceAccount?.id == filter.accountIdFilter ||
          item.destinationAccount?.id == filter.accountIdFilter;
      if (!matchesAccount) continue;
    }
    if (filter.categoryIdFilter != null &&
        item.category?.id != filter.categoryIdFilter) {
      continue;
    }
    if (filter.envelopeIdFilter != null &&
        item.linkedEnvelope?.id != filter.envelopeIdFilter) {
      continue;
    }
    if (filter.startDate != null &&
        item.occurredAt.isBefore(filter.startDate!)) {
      continue;
    }
    if (filter.endDate != null && item.occurredAt.isAfter(filter.endDate!)) {
      continue;
    }
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      final descMatch = item.description.toLowerCase().contains(q);
      final catMatch = item.category?.name.toLowerCase().contains(q) ?? false;
      final srcMatch =
          item.sourceAccount?.name.toLowerCase().contains(q) ?? false;
      final dstMatch =
          item.destinationAccount?.name.toLowerCase().contains(q) ?? false;
      if (!descMatch && !catMatch && !srcMatch && !dstMatch) {
        continue;
      }
    }

    items.add(item);
  }

  return AsyncValue.data(items);
});

/// Day-grouped transactions provider.
final dayGroupedTransactionsProvider =
    Provider<AsyncValue<List<DayGroupedTransactions>>>((ref) {
  final enrichedAsync = ref.watch(enrichedTransactionsProvider);
  return enrichedAsync.whenData(DayGroupedTransactions.groupByDay);
});
