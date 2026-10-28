import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/envelope_dao.dart';
import 'daos/ledger_dao.dart';

part 'app_database.g.dart';

// =============================================================================
// 1. LEDGER ACCOUNTS TABLE
// =============================================================================
class LedgerAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  BoolColumn get isLiquid => boolean().withDefault(const Constant(false))();
  IntColumn get creditLimit => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('ASSET_CASH', 'ASSET_BANK', 'LIABILITY_CREDIT_CARD', 'INCOME', 'EXPENSE', 'EQUITY_OPENING'))",
      ];
}

// =============================================================================
// 2. CATEGORIES TABLE
// =============================================================================
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  IntColumn get ledgerAccountId =>
      integer().references(LedgerAccounts, #id, onDelete: KeyAction.restrict)();
  IntColumn get iconCode => integer()();
  TextColumn get colorHex => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('INCOME', 'EXPENSE'))",
      ];
}

// =============================================================================
// 3. JOURNAL TRANSACTIONS TABLE
// =============================================================================
@TableIndex(name: 'idx_tx_status_type', columns: {#status, #txType})
@TableIndex(name: 'idx_tx_occurred_at', columns: {#occurredAt})
class JournalTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get txType => text()();
  TextColumn get status => text().withDefault(const Constant('POSTED'))();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get occurredAt => integer()();
  IntColumn get createdAt => integer()();
  TextColumn get idempotencyKey => text().nullable().unique()();
  @ReferenceName('reversedTransactions')
  IntColumn get reversesTxId => integer()
      .nullable()
      .references(JournalTransactions, #id, onDelete: KeyAction.setNull)();
  @ReferenceName('replacedByTransactions')
  IntColumn get replacedByTxId => integer()
      .nullable()
      .references(JournalTransactions, #id, onDelete: KeyAction.setNull)();

  @override
  List<String> get customConstraints => [
        "CHECK (tx_type IN ('OPENING_BALANCE', 'INCOME', 'EXPENSE', 'TRANSFER', 'CREDIT_CARD_PAYMENT', 'REFUND', 'REVERSAL'))",
        "CHECK (status IN ('POSTED', 'SUPERSEDED', 'VOIDED'))",
      ];
}

// =============================================================================
// 4. JOURNAL POSTINGS TABLE
// =============================================================================
@TableIndex(name: 'idx_postings_tx', columns: {#transactionId})
@TableIndex(name: 'idx_postings_acc', columns: {#accountId})
@TableIndex(name: 'idx_postings_cat', columns: {#categoryId})
@TableIndex(name: 'idx_postings_env', columns: {#envelopeId})
class JournalPostings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer()
      .references(JournalTransactions, #id, onDelete: KeyAction.cascade)();
  IntColumn get accountId =>
      integer().references(LedgerAccounts, #id, onDelete: KeyAction.restrict)();
  IntColumn get debitVnd => integer().withDefault(const Constant(0))();
  IntColumn get creditVnd => integer().withDefault(const Constant(0))();
  IntColumn get categoryId => integer()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get envelopeId => integer()
      .nullable()
      .references(Envelopes, #id, onDelete: KeyAction.setNull)();

  @override
  List<String> get customConstraints => [
        'CONSTRAINT chk_posting_one_sided CHECK ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))',
      ];
}

// =============================================================================
// 5. ENVELOPES TABLE (VIRTUAL FUNDS)
// =============================================================================
class Envelopes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get policy => text()();
  IntColumn get reservedBalanceVnd =>
      integer().withDefault(const Constant(0))();
  BoolColumn get allowNegativeException =>
      boolean().withDefault(const Constant(false))();
  IntColumn get targetAmountVnd => integer().nullable()();
  IntColumn get targetDateMs => integer().nullable()();
  IntColumn get periodLimitVnd => integer().nullable()();
  BoolColumn get rolloverEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
        "CHECK (policy IN ('PROTECTED', 'FLEXIBLE'))",
      ];
}

// =============================================================================
// 6. ENVELOPE MOVEMENTS TABLE
// =============================================================================
@TableIndex(name: 'idx_movements_source', columns: {#sourceEnvelopeId})
@TableIndex(name: 'idx_movements_dest', columns: {#destEnvelopeId})
@TableIndex(name: 'idx_movements_tx', columns: {#linkedTransactionId})
class EnvelopeMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get movementType => text()();
  IntColumn get amountVnd => integer()();
  @ReferenceName('sourceEnvelopeMovements')
  IntColumn get sourceEnvelopeId => integer()
      .nullable()
      .references(Envelopes, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('destEnvelopeMovements')
  IntColumn get destEnvelopeId => integer()
      .nullable()
      .references(Envelopes, #id, onDelete: KeyAction.restrict)();
  IntColumn get linkedTransactionId => integer()
      .nullable()
      .references(JournalTransactions, #id, onDelete: KeyAction.setNull)();
  IntColumn get linkedObligationId => integer()
      .nullable()
      .references(ScheduledItems, #id, onDelete: KeyAction.setNull)();
  IntColumn get occurredAt => integer()();

  @override
  List<String> get customConstraints => [
        'CHECK (amount_vnd > 0)',
        "CHECK (movement_type IN ('ALLOCATE', 'RELEASE', 'TRANSFER', 'SPEND', 'REFUND_RESTORE', 'REVERSAL'))",
      ];
}

// =============================================================================
// 7. CATEGORY BUDGETS TABLE
// =============================================================================
@TableIndex(
  name: 'idx_category_budgets_unique',
  columns: {#categoryId, #yearMonth},
  unique: true,
)
class CategoryBudgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get yearMonth => integer()();
  IntColumn get limitVnd => integer()();
  IntColumn get alertThresholdPct =>
      integer().withDefault(const Constant(80))();

  @override
  List<String> get customConstraints => [
        'CHECK (limit_vnd > 0)',
        'CHECK (alert_threshold_pct >= 1 AND alert_threshold_pct <= 100)',
      ];
}

// =============================================================================
// 8. SCHEDULED ITEMS TABLE (OBLIGATIONS & PLANNED INCOME)
// =============================================================================
@TableIndex(name: 'idx_scheduled_due_status', columns: {#dueDateMs, #status})
class ScheduledItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  IntColumn get amountVnd => integer()();
  IntColumn get dueDateMs => integer()();
  TextColumn get recurrence => text().withDefault(const Constant('NONE'))();
  IntColumn get anchorDayOfMonth => integer().nullable()();
  IntColumn get categoryId => integer()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get linkedEnvelopeId => integer()
      .nullable()
      .references(Envelopes, #id, onDelete: KeyAction.setNull)();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  IntColumn get paidTransactionId => integer()
      .nullable()
      .references(JournalTransactions, #id, onDelete: KeyAction.setNull)();
  IntColumn get reminderDaysBefore =>
      integer().withDefault(const Constant(1))();

  @override
  List<String> get customConstraints => [
        'CHECK (amount_vnd > 0)',
        'CHECK (anchor_day_of_month IS NULL OR (anchor_day_of_month >= 1 AND anchor_day_of_month <= 31))',
        'CHECK (reminder_days_before >= 0)',
        "CHECK (kind IN ('BILL', 'PLANNED_INCOME'))",
        "CHECK (recurrence IN ('NONE', 'WEEKLY', 'MONTHLY', 'YEARLY'))",
        "CHECK (status IN ('PENDING', 'PAID_OR_RECEIVED', 'SKIPPED'))",
      ];
}

// =============================================================================
// 9. SETTINGS TABLE (SINGLETON)
// =============================================================================
class Settings extends Table {
  IntColumn get id => integer()();
  IntColumn get minimumCashBufferVnd =>
      integer().withDefault(const Constant(0))();
  IntColumn get periodStartDay => integer().withDefault(const Constant(1))();
  IntColumn get dailyReminderHour =>
      integer().withDefault(const Constant(20))();
  IntColumn get dailyReminderMinute =>
      integer().withDefault(const Constant(0))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (id == 1)',
        'CHECK (minimum_cash_buffer_vnd >= 0)',
        'CHECK (period_start_day >= 1 AND period_start_day <= 31)',
        'CHECK (daily_reminder_hour >= 0 AND daily_reminder_hour <= 23)',
        'CHECK (daily_reminder_minute >= 0 AND daily_reminder_minute <= 59)',
      ];
}

// =============================================================================
// APP DATABASE DEFINITION & MIGRATION STRATEGY
// =============================================================================
@DriftDatabase(
  tables: [
    LedgerAccounts,
    Categories,
    JournalTransactions,
    JournalPostings,
    Envelopes,
    EnvelopeMovements,
    CategoryBudgets,
    ScheduledItems,
    Settings,
  ],
  daos: [
    LedgerDao,
    EnvelopeDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
        onCreate: (m) async {
          await m.createAll();
          await seedInitialData(this);
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'dongtien_db');
}

/// Seeds the 3 foundational system accounts, 8 default Vietnamese categories,
/// and the singleton settings row. Guarantees 0 ₫ initial balances.
Future<void> seedInitialData(AppDatabase db) async {
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  // 1. Seed System Accounts in ledger_accounts
  await db.into(db.ledgerAccounts).insert(
        LedgerAccountsCompanion.insert(
          id: const Value(1),
          name: 'Vốn ban đầu',
          kind: 'EQUITY_OPENING',
          isLiquid: const Value(false),
          creditLimit: const Value(0),
          isArchived: const Value(false),
          createdAt: nowMs,
        ),
      );

  final defaultIncomeId = await db.into(db.ledgerAccounts).insert(
        LedgerAccountsCompanion.insert(
          id: const Value(2),
          name: 'Thu nhập',
          kind: 'INCOME',
          isLiquid: const Value(false),
          creditLimit: const Value(0),
          isArchived: const Value(false),
          createdAt: nowMs,
        ),
      );

  final defaultExpenseId = await db.into(db.ledgerAccounts).insert(
        LedgerAccountsCompanion.insert(
          id: const Value(3),
          name: 'Chi tiêu',
          kind: 'EXPENSE',
          isLiquid: const Value(false),
          creditLimit: const Value(0),
          isArchived: const Value(false),
          createdAt: nowMs,
        ),
      );

  // 2. Seed 8 Default Vietnamese Categories
  final defaultCategories = [
    // Income Categories
    CategoriesCompanion.insert(
      name: 'Lương',
      kind: 'INCOME',
      ledgerAccountId: defaultIncomeId,
      iconCode: 0xe6f3, // Icons.work_outline
      colorHex: '#4E886F', // Verdant
      isDefault: const Value(true),
      isArchived: const Value(false),
    ),
    CategoriesCompanion.insert(
      name: 'Thưởng',
      kind: 'INCOME',
      ledgerAccountId: defaultIncomeId,
      iconCode: 0xeeb8, // Icons.card_giftcard_outlined
      colorHex: '#EE8D00', // Marigold
      isDefault: const Value(true),
      isArchived: const Value(false),
    ),
    // Expense Categories
    CategoriesCompanion.insert(
      name: 'Ăn uống',
      kind: 'EXPENSE',
      ledgerAccountId: defaultExpenseId,
      iconCode: 0xe532, // Icons.restaurant
      colorHex: '#E86B1C', // Ember
      isDefault: const Value(true),
      isArchived: const Value(false),
    ),
    CategoriesCompanion.insert(
      name: 'Di chuyển',
      kind: 'EXPENSE',
      ledgerAccountId: defaultExpenseId,
      iconCode: 0xef50, // Icons.directions_car_outlined
      colorHex: '#D99650', // Sandstone
      isDefault: const Value(true),
      isArchived: const Value(false),
    ),
    CategoriesCompanion.insert(
      name: 'Hoá đơn & Tiện ích',
      kind: 'EXPENSE',
      ledgerAccountId: defaultExpenseId,
      iconCode: 0xf2eb, // Icons.receipt_long_outlined
      colorHex: '#FAA800', // Marigold
      isDefault: const Value(true),
      isArchived: const Value(false),
    ),
    CategoriesCompanion.insert(
      name: 'Nhà cửa',
      kind: 'EXPENSE',
      ledgerAccountId: defaultExpenseId,
      iconCode: 0xf0dc, // Icons.home_work_outlined
      colorHex: '#65605C', // Charcoal
      isDefault: const Value(true),
      isArchived: const Value(false),
    ),
    CategoriesCompanion.insert(
      name: 'Mua sắm',
      kind: 'EXPENSE',
      ledgerAccountId: defaultExpenseId,
      iconCode: 0xf37d, // Icons.shopping_bag_outlined
      colorHex: '#FD8240', // Ember
      isDefault: const Value(true),
      isArchived: const Value(false),
    ),
    CategoriesCompanion.insert(
      name: 'Y tế',
      kind: 'EXPENSE',
      ledgerAccountId: defaultExpenseId,
      iconCode: 0xf166, // Icons.local_hospital_outlined
      colorHex: '#E0462F', // Ruby
      isDefault: const Value(true),
      isArchived: const Value(false),
    ),
  ];

  await db.batch((batch) {
    batch.insertAll(db.categories, defaultCategories);
  });

  // 3. Seed Singleton Settings (id = 1)
  await db.into(db.settings).insert(
        SettingsCompanion.insert(
          id: const Value(1),
          minimumCashBufferVnd: const Value(0),
          periodStartDay: const Value(1),
          dailyReminderHour: const Value(20),
          dailyReminderMinute: const Value(0),
          notificationsEnabled: const Value(false),
          schemaVersion: const Value(1),
        ),
      );
}
