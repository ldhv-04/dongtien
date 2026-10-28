# Handoff Report: Database Seeding & In-Memory Test Architecture (Milestone M1)

**Agent**: `explorer_m1_3`  
**Role**: Database Seeding & In-Memory Test Explorer  
**Milestone**: M1 (Scaffold & Drift Database Schema)  
**Target Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_3\handoff.md`  

---

## 1. Observation

### 1.1 Authoritative Requirements & Schema Specifications
From `build_spec/dongtien_build_spec.md` (§4.2 Drift Tables & Constraints):
```text
102: ### 4.2 Drift Tables & Constraints
103: Enable `PRAGMA foreign_keys = ON;` inside `MigrationStrategy.beforeOpen`.
104: 1. `ledger_accounts`:
105:    - `id` (PK, integer autoIncrement), `name` (text), `kind` (`ASSET_CASH`, `ASSET_BANK`, `LIABILITY_CREDIT_CARD`, `INCOME`, `EXPENSE`, `EQUITY_OPENING`), `is_liquid` (bool: true only for `ASSET_CASH` and `ASSET_BANK`), `credit_limit` (int, default 0, informational only), `is_archived` (bool), `created_at` (int epoch ms).
106: 2. `categories`:
107:    - `id` (PK), `name` (text), `kind` (`INCOME`, `EXPENSE`), `ledger_account_id` (FK -> `ledger_accounts.id`), `icon_code` (int), `color_hex` (text), `is_default` (bool), `is_archived` (bool).
...
112:    - Constraint: `(debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0)`.
...
121: 9. `settings`:
122:    - Single-row configuration (`id = 1`): `minimum_cash_buffer_vnd` (int default 0), `period_start_day` (int default 1), `daily_reminder_hour` (int default 20), `daily_reminder_minute` (int default 0), `notifications_enabled` (bool default false), `schema_version` (int).
```

From `docs/ARCHITECTURE_AND_RULES.md` (§1.2 Chart of Accounts & §3.1 Dynamic Balances):
```text
20: ### 1.2 Chart of Accounts
21: Every ledger account is classified into one of six distinct kinds:
...
28: | `INCOME` | Credit | Inflows from salary, bonus, investments | `false` |
29: | `EXPENSE` | Debit | Outflows for goods, services, utilities | `false` |
30: | `EQUITY_OPENING` | Credit | Balancing equity for initial starting balances | `false` |
...
32: #### Liquid Asset Invariant
33: An account has `is_liquid == true` if and only if its kind is `ASSET_CASH` or `ASSET_BANK`. Credit card accounts, regardless of their available limit, are liabilities and NEVER marked liquid.
...
144: Balances are calculated on the fly using SQL aggregate queries across all postings in `journal_postings`:
147:   Asset / Expense: SUM(debit_vnd) - SUM(credit_vnd)
151:   Liability / Income / Equity: SUM(credit_vnd) - SUM(debit_vnd)
```

From `docs/DESIGN_AND_TEST_PLAN.md` (§1.5 Material Icons & §1.3 Semantic Colors):
```text
226: | Category: Ăn uống | Bowl & Chopsticks | `Icons.restaurant` |
227: | Category: Di chuyển | Car Outline | `Icons.directions_car_outlined` |
228: | Category: Hoá đơn | Receipt Document | `Icons.receipt_long_outlined` |
229: | Category: Nhà cửa | House Outline | `Icons.home_work_outlined` |
230: | Category: Mua sắm | Shopping Bag | `Icons.shopping_bag_outlined` |
231: | Category: Y tế | Hospital Cross | `Icons.local_hospital_outlined` |
232: | Category: Lương | Work Briefcase | `Icons.work_outline` |
233: | Category: Thưởng | Gift Box | `Icons.card_giftcard_outlined` |
```

### 1.2 Independent SQLite In-Memory Simulation Verification
To verify the exact SQLite constraints, foreign key enforcement, and dynamic balance calculations, an in-memory SQLite script was executed (`.agents/teamwork/explorer_m1_3/test_sqlite_simulation.py`):
```text
Accounts seeded: 3, Categories seeded: 8, Settings: 1, Tx: 0, Postings: 0
Initial balances strictly 0 verified!
FK check PASSED for category ledger_account_id: FOREIGN KEY constraint failed
Check constraint PASSED for posting debit/credit both positive: CHECK constraint failed: (debit_vnd > 0 AND credit_vnd = 0) OR (credit_vnd > 0 AND debit_vnd = 0)
Check constraint PASSED for posting debit==0 and credit==0: CHECK constraint failed: (debit_vnd > 0 AND credit_vnd = 0) OR (credit_vnd > 0 AND debit_vnd = 0)
Idempotency unique check PASSED: UNIQUE constraint failed: journal_transactions.idempotency_key
CategoryBudgets unique (category_id, year_month) check PASSED: UNIQUE constraint failed: category_budgets.category_id, category_budgets.year_month
Cash balance: 10000000 VND, Equity balance: 10000000 VND
ALL SQLITE IN-MEMORY INVARIANTS AND TEST SCENARIOS VERIFIED 100% SUCCESSFULLY!
```

---

## 2. Logic Chain

1. **System Accounts Requirement (Observation 1.1)**:
   The database schema mandates that each category in `categories` contains a foreign key `ledger_account_id` referencing `ledger_accounts.id`. Furthermore, the double-entry Posting Matrix mandates that `OPENING_BALANCE` transactions credit `EQUITY_OPENING`. Therefore, before any category or opening transaction can be created, 3 foundational system accounts must exist in `ledger_accounts`:
   - Account 1: `EQUITY_OPENING` (`kind = 'EQUITY_OPENING'`, `name = 'Vốn ban đầu'`, `is_liquid = false`, `credit_limit = 0`).
   - Account 2: Default Income Account (`kind = 'INCOME'`, `name = 'Thu nhập'`, `is_liquid = false`, `credit_limit = 0`).
   - Account 3: Default Expense Account (`kind = 'EXPENSE'`, `name = 'Chi tiêu'`, `is_liquid = false`, `credit_limit = 0`).

2. **Strictly 0 ₫ Initial Balances Invariant (Observation 1.1 & 1.2)**:
   Account balances are never stored in mutable columns on `ledger_accounts`; they are derived strictly via SQL aggregation over `journal_postings`:
   $$\text{Balance}_{\text{Asset/Expense}} = \sum \text{debit\_vnd} - \sum \text{credit\_vnd}$$
   $$\text{Balance}_{\text{Equity/Income/Liability}} = \sum \text{credit\_vnd} - \sum \text{debit\_vnd}$$
   In `MigrationStrategy.onCreate`, **zero** records are inserted into `journal_transactions` or `journal_postings`. Thus, every account balance evaluates to exactly `0 ₫`, operating income is `0 ₫`, net expenses are `0 ₫`, and liquid assets are `0 ₫` without any fake transactions.

3. **Topological Seeding Order (Observation 1.1)**:
   Foreign key relationships dictate the strict insertion sequence during `onCreate`:
   - Step A: Insert 3 system accounts into `ledger_accounts` (no FK dependencies).
   - Step B: Insert 8 Vietnamese categories into `categories` referencing the seeded Income/Expense accounts (`ledger_account_id = 2` and `ledger_account_id = 3`).
   - Step C: Insert singleton settings into `settings` (`id = 1`, no FK dependencies).

4. **Category Icon Codepoints & Semantic Color Tokens (Observation 1.1)**:
   Each default category is mapped to its exact Material Icons integer `codePoint` and semantic hex color token:
   - `Lương` (Income): `Icons.work_outline` (`0xe6f3` / `59123`), Verdant `#4E886F`.
   - `Thưởng` (Income): `Icons.card_giftcard_outlined` (`0xeeb8` / `61112`), Marigold `#EE8D00`.
   - `Ăn uống` (Expense): `Icons.restaurant` (`0xe532` / `58674`), Ember `#E86B1C`.
   - `Di chuyển` (Expense): `Icons.directions_car_outlined` (`0xef50` / `61264`), Sandstone `#D99650`.
   - `Hoá đơn & Tiện ích` (Expense): `Icons.receipt_long_outlined` (`0xf2eb` / `62187`), Marigold `#FAA800`.
   - `Nhà cửa` (Expense): `Icons.home_work_outlined` (`0xf0dc` / `61660`), Charcoal `#65605C`.
   - `Mua sắm` (Expense): `Icons.shopping_bag_outlined` (`0xf37d` / `62333`), Ember `#FD8240`.
   - `Y tế` (Expense): `Icons.local_hospital_outlined` (`0xf166` / `61798`), Ruby `#E0462F`.

5. **In-Memory Database Test Architecture (Observation 1.2)**:
   Using `NativeDatabase.memory(setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'))` inside `setUp()` ensures an isolated, transient SQLite database per test. Testing must assert:
   - FK enforcement prevents orphan inserts into `categories`, `journal_postings`, and `envelope_movements`.
   - CHECK constraints on `journal_postings` reject simultaneous debit & credit or both zero.
   - Unique constraints on `idempotency_key` and composite `(category_id, year_month)`.
   - Dynamic account balance derivation on balanced double-entry transactions.

---

## 3. Caveats

1. **Build Runner Timing**: Drift companion classes (`LedgerAccountsCompanion`, `CategoriesCompanion`, `SettingsCompanion`) are generated by `build_runner` (`app_database.g.dart`). If `onCreate` needs to run before `build_runner` has generated code, direct raw SQL statements via `batch.customStatement(...)` can be used as an interchangeable bootstrap fallback. Both blueprints are provided below.
2. **SQLite FK Timing in Drift**: Drift executes `MigrationStrategy.beforeOpen` *after* `MigrationStrategy.onCreate`. To ensure foreign keys are active even if custom statements run during tests, `NativeDatabase.memory` is initialized with `setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;')`.
3. **No other caveats.**

---

## 4. Conclusion & Concrete Blueprints

### 4.1 Seeding Blueprint (`lib/core/database/app_database.dart`)

```dart
import 'package:drift/drift.dart';

// Table declarations (LedgerAccounts, Categories, JournalTransactions, etc.)...

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LedgerAccounts,
  Categories,
  JournalTransactions,
  JournalPostings,
  Envelopes,
  EnvelopeMovements,
  CategoryBudgets,
  ScheduledItems,
  Settings,
])
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

/// Seeds the 3 foundational system accounts, 8 default Vietnamese categories,
/// and the singleton settings row. Guarantees 0 ₫ initial balances.
Future<void> seedInitialData(AppDatabase db) async {
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  // 1. Seed System Accounts in ledger_accounts
  final equityOpeningId = await db.into(db.ledgerAccounts).insert(
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
```

### 4.2 In-Memory Database Test Suite Blueprint (`test/database/app_database_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:dongtien/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('1. Drift Fresh Database Initialization & Vietnamese Seeding', () {
    test('fresh database creates all 9 tables', () async {
      expect(await db.select(db.ledgerAccounts).get(), isNotNull);
      expect(await db.select(db.categories).get(), isNotNull);
      expect(await db.select(db.journalTransactions).get(), isNotNull);
      expect(await db.select(db.journalPostings).get(), isNotNull);
      expect(await db.select(db.envelopes).get(), isNotNull);
      expect(await db.select(db.envelopeMovements).get(), isNotNull);
      expect(await db.select(db.categoryBudgets).get(), isNotNull);
      expect(await db.select(db.scheduledItems).get(), isNotNull);
      expect(await db.select(db.settings).get(), isNotNull);
    });

    test('3 system accounts are seeded with correct attributes', () async {
      final accounts = await db.select(db.ledgerAccounts).get();
      expect(accounts.length, equals(3));

      final equityOpening = accounts.firstWhere((a) => a.kind == 'EQUITY_OPENING');
      expect(equityOpening.id, equals(1));
      expect(equityOpening.name, equals('Vốn ban đầu'));
      expect(equityOpening.isLiquid, isFalse);
      expect(equityOpening.creditLimit, equals(0));
      expect(equityOpening.isArchived, isFalse);

      final defaultIncome = accounts.firstWhere((a) => a.kind == 'INCOME');
      expect(defaultIncome.id, equals(2));
      expect(defaultIncome.name, equals('Thu nhập'));
      expect(defaultIncome.isLiquid, isFalse);
      expect(defaultIncome.creditLimit, equals(0));

      final defaultExpense = accounts.firstWhere((a) => a.kind == 'EXPENSE');
      expect(defaultExpense.id, equals(3));
      expect(defaultExpense.name, equals('Chi tiêu'));
      expect(defaultExpense.isLiquid, isFalse);
      expect(defaultExpense.creditLimit, equals(0));
    });

    test('8 default Vietnamese categories are seeded with correct icons, colors, and FKs', () async {
      final categories = await db.select(db.categories).get();
      expect(categories.length, equals(8));

      // 2 Income Categories
      final salary = categories.firstWhere((c) => c.name == 'Lương');
      expect(salary.kind, equals('INCOME'));
      expect(salary.ledgerAccountId, equals(2));
      expect(salary.iconCode, equals(0xe6f3));
      expect(salary.colorHex, equals('#4E886F'));
      expect(salary.isDefault, isTrue);

      final bonus = categories.firstWhere((c) => c.name == 'Thưởng');
      expect(bonus.kind, equals('INCOME'));
      expect(bonus.ledgerAccountId, equals(2));
      expect(bonus.iconCode, equals(0xeeb8));
      expect(bonus.colorHex, equals('#EE8D00'));
      expect(bonus.isDefault, isTrue);

      // 6 Expense Categories
      final expenseNames = ['Ăn uống', 'Di chuyển', 'Hoá đơn & Tiện ích', 'Nhà cửa', 'Mua sắm', 'Y tế'];
      for (final name in expenseNames) {
        final cat = categories.firstWhere((c) => c.name == name);
        expect(cat.kind, equals('EXPENSE'));
        expect(cat.ledgerAccountId, equals(3));
        expect(cat.isDefault, isTrue);
        expect(cat.isArchived, isFalse);
      }
    });

    test('singleton settings row is initialized with id = 1 and default values', () async {
      final settingsList = await db.select(db.settings).get();
      expect(settingsList.length, equals(1));

      final s = settingsList.single;
      expect(s.id, equals(1));
      expect(s.minimumCashBufferVnd, equals(0));
      expect(s.periodStartDay, equals(1));
      expect(s.dailyReminderHour, equals(20));
      expect(s.dailyReminderMinute, equals(0));
      expect(s.notificationsEnabled, isFalse);
      expect(s.schemaVersion, equals(1));
    });

    test('initial state has strictly 0 transactions and 0 ₫ balances', () async {
      final txs = await db.select(db.journalTransactions).get();
      final postings = await db.select(db.journalPostings).get();
      final envelopes = await db.select(db.envelopes).get();

      expect(txs.isEmpty, isTrue);
      expect(postings.isEmpty, isTrue);
      expect(envelopes.isEmpty, isTrue);
    });
  });

  group('2. Foreign Key Enforcement (PRAGMA foreign_keys = ON;)', () {
    test('inserting category with non-existent ledger_account_id throws SqliteException', () async {
      expect(
        () async {
          await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Orphan Category',
              kind: 'EXPENSE',
              ledgerAccountId: 9999, // Non-existent
              iconCode: 0xe532,
              colorHex: '#000000',
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test('inserting journal posting with non-existent transaction_id throws SqliteException', () async {
      expect(
        () async {
          await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: 9999,
              accountId: 1,
              debitVnd: const Value(100000),
              creditVnd: const Value(0),
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test('inserting journal posting with non-existent account_id throws SqliteException', () async {
      final txId = await db.into(db.journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'EXPENSE',
          description: 'Tx',
          occurredAt: 1,
          createdAt: 1,
        ),
      );

      expect(
        () async {
          await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: 9999, // Non-existent account
              debitVnd: const Value(100000),
              creditVnd: const Value(0),
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });
  });

  group('3. Journal Postings Constraints & Balanced Double-Entry Postings', () {
    test('inserting posting with debit > 0 AND credit > 0 throws SqliteException (CHECK constraint)', () async {
      final txId = await db.into(db.journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'EXPENSE',
          description: 'Invalid Posting',
          occurredAt: 1,
          createdAt: 1,
        ),
      );

      expect(
        () async {
          await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: 1,
              debitVnd: const Value(50000),
              creditVnd: const Value(50000), // Violates CHECK
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('inserting posting with debit == 0 AND credit == 0 throws SqliteException (CHECK constraint)', () async {
      final txId = await db.into(db.journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'EXPENSE',
          description: 'Invalid Zero Posting',
          occurredAt: 1,
          createdAt: 1,
        ),
      );

      expect(
        () async {
          await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: 1,
              debitVnd: const Value(0),
              creditVnd: const Value(0), // Violates CHECK
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('balanced transaction insertion and dynamic account balance derivation succeeds', () async {
      // Create user cash account
      final cashId = await db.into(db.ledgerAccounts).insert(
        LedgerAccountsCompanion.insert(
          name: 'Tiền mặt',
          kind: 'ASSET_CASH',
          isLiquid: const Value(true),
          createdAt: 1,
        ),
      );

      // Insert OPENING_BALANCE transaction of 10.000.000 ₫
      final txId = await db.into(db.journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'OPENING_BALANCE',
          description: 'Số dư ban đầu tiền mặt',
          occurredAt: 100,
          createdAt: 100,
        ),
      );

      // Balanced postings: Debit Asset Cash 10M, Credit EQUITY_OPENING 10M
      await db.batch((batch) {
        batch.insert(
          db.journalPostings,
          JournalPostingsCompanion.insert(
            transactionId: txId,
            accountId: cashId,
            debitVnd: const Value(10000000),
            creditVnd: const Value(0),
          ),
        );
        batch.insert(
          db.journalPostings,
          JournalPostingsCompanion.insert(
            transactionId: txId,
            accountId: 1, // EQUITY_OPENING
            debitVnd: const Value(0),
            creditVnd: const Value(10000000),
          ),
        );
      });

      // Assert sum(debit) == sum(credit)
      final postings = await (db.select(db.journalPostings)..where((p) => p.transactionId.equals(txId))).get();
      final totalDebit = postings.fold<int>(0, (sum, p) => sum + p.debitVnd);
      final totalCredit = postings.fold<int>(0, (sum, p) => sum + p.creditVnd);
      expect(totalDebit, equals(10000000));
      expect(totalCredit, equals(10000000));
      expect(totalDebit, equals(totalCredit));

      // Derive cash balance: sum(debit) - sum(credit)
      final cashPostings = await (db.select(db.journalPostings)..where((p) => p.accountId.equals(cashId))).get();
      final cashBalance = cashPostings.fold<int>(0, (sum, p) => sum + p.debitVnd - p.creditVnd);
      expect(cashBalance, equals(10000000));

      // Derive equity balance: sum(credit) - sum(debit)
      final equityPostings = await (db.select(db.journalPostings)..where((p) => p.accountId.equals(1))).get();
      final equityBalance = equityPostings.fold<int>(0, (sum, p) => sum + p.creditVnd - p.debitVnd);
      expect(equityBalance, equals(10000000));
    });
  });

  group('4. Unique Constraints & Relational Integrity', () {
    test('idempotency_key rejects duplicate non-null submissions', () async {
      await db.into(db.journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'EXPENSE',
          description: 'Tx 1',
          occurredAt: 1,
          createdAt: 1,
          idempotencyKey: const Value('unique-key-123'),
        ),
      );

      expect(
        () async {
          await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: 'Tx 2 duplicate',
              occurredAt: 2,
              createdAt: 2,
              idempotencyKey: const Value('unique-key-123'),
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('UNIQUE constraint failed'),
        )),
      );
    });

    test('multiple null idempotency_key transactions are permitted', () async {
      final id1 = await db.into(db.journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'EXPENSE',
          description: 'Tx 1 (null key)',
          occurredAt: 1,
          createdAt: 1,
        ),
      );
      final id2 = await db.into(db.journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'EXPENSE',
          description: 'Tx 2 (null key)',
          occurredAt: 2,
          createdAt: 2,
        ),
      );
      expect(id1, isNotNull);
      expect(id2, isNotNull);
      expect(id1, isNot(equals(id2)));
    });

    test('composite unique (category_id, year_month) on category_budgets is enforced', () async {
      await db.into(db.categoryBudgets).insert(
        CategoryBudgetsCompanion.insert(
          categoryId: 1,
          yearMonth: 202610,
          limitVnd: 5000000,
        ),
      );

      expect(
        () async {
          await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: 1,
              yearMonth: 202610, // Duplicate month for same category
              limitVnd: 6000000,
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('UNIQUE constraint failed'),
        )),
      );
    });
  });
}
```

---

## 5. Verification Method

1. **In-Memory SQLite Verification Script**:
   Execute the verification simulation script directly:
   ```powershell
   python .agents\teamwork\explorer_m1_3\test_sqlite_simulation.py
   ```
   *Expected Result*: Exits with code 0, printing:
   `ALL SQLITE IN-MEMORY INVARIANTS AND TEST SCENARIOS VERIFIED 100% SUCCESSFULLY!`

2. **Automated Dart / Flutter Test Execution (Once M1 scaffolded)**:
   ```powershell
   flutter test test/database/app_database_test.dart
   ```
   *Expected Result*: All 12 tests across 4 groups pass with 0 failures.

3. **Invalidation Conditions**:
   - Any transaction or posting inserted during `onCreate` (violates 0 ₫ initial balance invariant).
   - Any category created without a valid `ledger_account_id` foreign key.
   - Any failure of `PRAGMA foreign_keys = ON;` to block orphan records.
