import 'package:flutter/foundation.dart';
import '../../../../domain/ledger/transaction_type.dart';
import 'transaction_item.dart';

/// Bucket of transactions occurring on a single calendar day.
@immutable
class DayGroupedTransactions {
  final DateTime date;
  final List<TransactionItem> items;
  final int dailyNetVnd;

  const DayGroupedTransactions({
    required this.date,
    required this.items,
    required this.dailyNetVnd,
  });

  static List<DayGroupedTransactions> groupByDay(List<TransactionItem> items) {
    final Map<DateTime, List<TransactionItem>> map = {};
    for (final item in items) {
      final dt = item.occurredAt;
      final dayKey = DateTime(dt.year, dt.month, dt.day);
      map.putIfAbsent(dayKey, () => []).add(item);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((day) {
      final dayItems = map[day]!;
      int net = 0;
      for (final item in dayItems) {
        if (item.type == TransactionType.income ||
            item.type == TransactionType.refund) {
          net += item.amountVnd;
        } else if (item.type == TransactionType.expense) {
          net -= item.amountVnd;
        }
      }
      return DayGroupedTransactions(
        date: day,
        items: dayItems,
        dailyNetVnd: net,
      );
    }).toList();
  }
}
