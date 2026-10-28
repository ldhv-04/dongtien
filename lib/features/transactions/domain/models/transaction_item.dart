import 'package:flutter/foundation.dart' hide Category;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../domain/ledger/transaction_type.dart';

/// Enriched presentation model for a clean journal transaction.
@immutable
class TransactionItem {
  final JournalTransaction transaction;
  final int amountVnd;
  final TransactionType type;
  final Category? category;
  final AccountWithBalance? sourceAccount;
  final AccountWithBalance? destinationAccount;
  final Envelope? linkedEnvelope;
  final List<JournalPosting> postings;

  const TransactionItem({
    required this.transaction,
    required this.amountVnd,
    required this.type,
    this.category,
    this.sourceAccount,
    this.destinationAccount,
    this.linkedEnvelope,
    this.postings = const [],
  });

  int get id => transaction.id;
  String get description => transaction.description;
  DateTime get occurredAt =>
      DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
  String? get idempotencyKey => transaction.idempotencyKey;
}
