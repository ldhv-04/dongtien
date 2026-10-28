import sqlite3
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

print("=================================================================")
print("DRIFT SCHEMA & RELATIONAL INVARIANTS PROBE (Milestone M1)")
print("=================================================================")

db = sqlite3.connect(':memory:')
db.isolation_level = None
db.execute("PRAGMA foreign_keys = ON;")

# Verify PRAGMA foreign_keys is enabled
fk_status = db.execute("PRAGMA foreign_keys;").fetchone()[0]
print(f"[*] PRAGMA foreign_keys = {fk_status} (Expected: 1)")
assert fk_status == 1

# ==============================================================================
# 1. DDL CREATION FOR ALL 9 TABLES
# ==============================================================================

ddl_statements = [
    # 1. ledger_accounts
    """
    CREATE TABLE ledger_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        kind TEXT NOT NULL CHECK(kind IN ('ASSET_CASH', 'ASSET_BANK', 'LIABILITY_CREDIT_CARD', 'INCOME', 'EXPENSE', 'EQUITY_OPENING')),
        is_liquid INTEGER NOT NULL DEFAULT 0 CHECK(is_liquid IN (0, 1)),
        credit_limit INTEGER NOT NULL DEFAULT 0 CHECK(credit_limit >= 0),
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1)),
        created_at INTEGER NOT NULL
    );
    """,

    # 2. categories
    """
    CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        kind TEXT NOT NULL CHECK(kind IN ('INCOME', 'EXPENSE')),
        ledger_account_id INTEGER NOT NULL REFERENCES ledger_accounts(id) ON DELETE RESTRICT,
        icon_code INTEGER NOT NULL,
        color_hex TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1))
    );
    """,

    # 3. journal_transactions
    """
    CREATE TABLE journal_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tx_type TEXT NOT NULL CHECK(tx_type IN ('OPENING_BALANCE', 'INCOME', 'EXPENSE', 'TRANSFER', 'CREDIT_CARD_PAYMENT', 'REFUND', 'REVERSAL')),
        status TEXT NOT NULL DEFAULT 'POSTED' CHECK(status IN ('POSTED', 'SUPERSEDED', 'VOIDED')),
        description TEXT NOT NULL DEFAULT '',
        occurred_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        idempotency_key TEXT UNIQUE,
        reverses_tx_id INTEGER REFERENCES journal_transactions(id) ON DELETE SET NULL,
        replaced_by_tx_id INTEGER REFERENCES journal_transactions(id) ON DELETE SET NULL
    );
    """,

    # 4. journal_postings
    """
    CREATE TABLE journal_postings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL REFERENCES journal_transactions(id) ON DELETE CASCADE,
        account_id INTEGER NOT NULL REFERENCES ledger_accounts(id) ON DELETE RESTRICT,
        debit_vnd INTEGER NOT NULL DEFAULT 0 CHECK(debit_vnd >= 0),
        credit_vnd INTEGER NOT NULL DEFAULT 0 CHECK(credit_vnd >= 0),
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        envelope_id INTEGER REFERENCES envelopes(id) ON DELETE SET NULL,
        CONSTRAINT chk_posting_one_sided CHECK (
            (debit_vnd > 0 AND credit_vnd == 0) OR
            (credit_vnd > 0 AND debit_vnd == 0)
        )
    );
    """,

    # 5. envelopes
    """
    CREATE TABLE envelopes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        policy TEXT NOT NULL CHECK(policy IN ('PROTECTED', 'FLEXIBLE')),
        reserved_balance_vnd INTEGER NOT NULL DEFAULT 0,
        allow_negative_exception INTEGER NOT NULL DEFAULT 0 CHECK(allow_negative_exception IN (0, 1)),
        target_amount_vnd INTEGER CHECK(target_amount_vnd IS NULL OR target_amount_vnd > 0),
        target_date_ms INTEGER,
        period_limit_vnd INTEGER CHECK(period_limit_vnd IS NULL OR period_limit_vnd > 0),
        rollover_enabled INTEGER NOT NULL DEFAULT 0 CHECK(rollover_enabled IN (0, 1)),
        priority INTEGER NOT NULL DEFAULT 1 CHECK(priority >= 1),
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1))
    );
    """,

    # 6. envelope_movements
    """
    CREATE TABLE envelope_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movement_type TEXT NOT NULL CHECK(movement_type IN ('ALLOCATE', 'RELEASE', 'TRANSFER', 'SPEND', 'REFUND_RESTORE', 'REVERSAL')),
        amount_vnd INTEGER NOT NULL CHECK(amount_vnd > 0),
        source_envelope_id INTEGER REFERENCES envelopes(id) ON DELETE RESTRICT,
        dest_envelope_id INTEGER REFERENCES envelopes(id) ON DELETE RESTRICT,
        linked_transaction_id INTEGER REFERENCES journal_transactions(id) ON DELETE SET NULL,
        linked_obligation_id INTEGER REFERENCES scheduled_items(id) ON DELETE SET NULL,
        occurred_at INTEGER NOT NULL
    );
    """,

    # 7. category_budgets
    """
    CREATE TABLE category_budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
        year_month INTEGER NOT NULL,
        limit_vnd INTEGER NOT NULL CHECK(limit_vnd > 0),
        alert_threshold_pct INTEGER NOT NULL DEFAULT 80 CHECK(alert_threshold_pct >= 1 AND alert_threshold_pct <= 100)
    );
    """,
    "CREATE UNIQUE INDEX idx_category_budgets_unique ON category_budgets (category_id, year_month);",

    # 8. scheduled_items
    """
    CREATE TABLE scheduled_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL CHECK(kind IN ('BILL', 'PLANNED_INCOME')),
        title TEXT NOT NULL,
        amount_vnd INTEGER NOT NULL CHECK(amount_vnd > 0),
        due_date_ms INTEGER NOT NULL,
        recurrence TEXT NOT NULL DEFAULT 'NONE' CHECK(recurrence IN ('NONE', 'WEEKLY', 'MONTHLY', 'YEARLY')),
        anchor_day_of_month INTEGER CHECK(anchor_day_of_month IS NULL OR (anchor_day_of_month >= 1 AND anchor_day_of_month <= 31)),
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        linked_envelope_id INTEGER REFERENCES envelopes(id) ON DELETE SET NULL,
        status TEXT NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING', 'PAID_OR_RECEIVED', 'SKIPPED')),
        paid_transaction_id INTEGER REFERENCES journal_transactions(id) ON DELETE SET NULL,
        reminder_days_before INTEGER NOT NULL DEFAULT 1 CHECK(reminder_days_before >= 0)
    );
    """,

    # 9. settings
    """
    CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK(id == 1),
        minimum_cash_buffer_vnd INTEGER NOT NULL DEFAULT 0 CHECK(minimum_cash_buffer_vnd >= 0),
        period_start_day INTEGER NOT NULL DEFAULT 1 CHECK(period_start_day >= 1 AND period_start_day <= 31),
        daily_reminder_hour INTEGER NOT NULL DEFAULT 20 CHECK(daily_reminder_hour >= 0 AND daily_reminder_hour <= 23),
        daily_reminder_minute INTEGER NOT NULL DEFAULT 0 CHECK(daily_reminder_minute >= 0 AND daily_reminder_minute <= 59),
        notifications_enabled INTEGER NOT NULL DEFAULT 0 CHECK(notifications_enabled IN (0, 1)),
        schema_version INTEGER NOT NULL DEFAULT 1
    );
    """
]

# Execute DDL in dependency order
for stmt in ddl_statements:
    db.execute(stmt)

print("[✓] Successfully created all 9 Drift tables and indexes.")

# Verify all 9 tables exist in sqlite_master
tables = [r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';").fetchall()]
print(f"[*] Created tables ({len(tables)}): {tables}")
assert len(tables) == 9
expected_tables = {
    'ledger_accounts', 'categories', 'journal_transactions', 'journal_postings',
    'envelopes', 'envelope_movements', 'category_budgets', 'scheduled_items', 'settings'
}
assert set(tables) == expected_tables

# ==============================================================================
# 2. PROBING CHECK CONSTRAINTS
# ==============================================================================
print("\n>>> Probing CHECK Constraints...")

# Probe 2.1: journal_postings check constraint
# Valid cases
db.execute("INSERT INTO ledger_accounts (id, name, kind, is_liquid, credit_limit, is_archived, created_at) VALUES (1, 'Cash', 'ASSET_CASH', 1, 0, 0, 1729900000000);")
db.execute("INSERT INTO ledger_accounts (id, name, kind, is_liquid, credit_limit, is_archived, created_at) VALUES (2, 'Expense', 'EXPENSE', 0, 0, 0, 1729900000000);")
db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at) VALUES (1, 'EXPENSE', 'POSTED', 1729900000000, 1729900000000);")

# Valid debit posting
db.execute("INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (1, 2, 100000, 0);")
# Valid credit posting
db.execute("INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (1, 1, 0, 100000);")
print("[✓] Valid journal postings (debit>0, credit=0 and debit=0, credit>0) passed.")

# Invalid: debit=0, credit=0
try:
    db.execute("INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (1, 1, 0, 0);")
    assert False, "Should have thrown CHECK constraint error for 0,0"
except sqlite3.IntegrityError as e:
    print(f"[✓] Zero-sided posting rejected as expected: {e}")

# Invalid: debit>0 AND credit>0
try:
    db.execute("INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (1, 1, 50000, 50000);")
    assert False, "Should have thrown CHECK constraint error for two-sided posting"
except sqlite3.IntegrityError as e:
    print(f"[✓] Two-sided posting rejected as expected: {e}")

# Invalid: negative debit
try:
    db.execute("INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (1, 1, -1000, 0);")
    assert False, "Should have thrown CHECK constraint error for negative debit"
except sqlite3.IntegrityError as e:
    print(f"[✓] Negative debit rejected as expected: {e}")

# Probe 2.2: category_budgets unique index (category_id, year_month)
db.execute("INSERT INTO categories (id, name, kind, ledger_account_id, icon_code, color_hex, is_default, is_archived) VALUES (1, 'Ăn uống', 'EXPENSE', 2, 58200, '#00A86B', 1, 0);")
db.execute("INSERT INTO category_budgets (id, category_id, year_month, limit_vnd, alert_threshold_pct) VALUES (1, 1, 202610, 5000000, 80);")
try:
    db.execute("INSERT INTO category_budgets (id, category_id, year_month, limit_vnd, alert_threshold_pct) VALUES (2, 1, 202610, 6000000, 80);")
    assert False, "Should have thrown UNIQUE constraint error for (category_id, year_month)"
except sqlite3.IntegrityError as e:
    print(f"[✓] Duplicate (category_id, year_month) rejected as expected: {e}")

# Different month is allowed
db.execute("INSERT INTO category_budgets (id, category_id, year_month, limit_vnd, alert_threshold_pct) VALUES (2, 1, 202611, 6000000, 80);")
print("[✓] Different year_month allowed.")

# Probe 2.3: scheduled_items anchor_day_of_month 1..31 check
# Valid 1, 31, NULL
db.execute("INSERT INTO scheduled_items (id, kind, title, amount_vnd, due_date_ms, recurrence, anchor_day_of_month) VALUES (1, 'BILL', 'Tiền nhà', 5000000, 1729900000000, 'MONTHLY', 1);")
db.execute("INSERT INTO scheduled_items (id, kind, title, amount_vnd, due_date_ms, recurrence, anchor_day_of_month) VALUES (2, 'BILL', 'Tiền mạng', 300000, 1729900000000, 'MONTHLY', 31);")
db.execute("INSERT INTO scheduled_items (id, kind, title, amount_vnd, due_date_ms, recurrence, anchor_day_of_month) VALUES (3, 'BILL', 'Mua một lần', 100000, 1729900000000, 'NONE', NULL);")
print("[✓] Valid anchor_day_of_month (1, 31, NULL) passed.")

# Invalid anchor_day_of_month = 0
try:
    db.execute("INSERT INTO scheduled_items (id, kind, title, amount_vnd, due_date_ms, recurrence, anchor_day_of_month) VALUES (4, 'BILL', 'Lỗi 0', 100000, 1729900000000, 'MONTHLY', 0);")
    assert False, "Should have thrown CHECK constraint error for anchor_day = 0"
except sqlite3.IntegrityError as e:
    print(f"[✓] anchor_day_of_month = 0 rejected as expected: {e}")

# Invalid anchor_day_of_month = 32
try:
    db.execute("INSERT INTO scheduled_items (id, kind, title, amount_vnd, due_date_ms, recurrence, anchor_day_of_month) VALUES (5, 'BILL', 'Lỗi 32', 100000, 1729900000000, 'MONTHLY', 32);")
    assert False, "Should have thrown CHECK constraint error for anchor_day = 32"
except sqlite3.IntegrityError as e:
    print(f"[✓] anchor_day_of_month = 32 rejected as expected: {e}")

# Probe 2.4: settings singleton check id == 1
# Valid id = 1
db.execute("INSERT INTO settings (id, minimum_cash_buffer_vnd, period_start_day) VALUES (1, 1000000, 1);")
print("[✓] Valid settings (id=1) inserted.")

# Invalid id = 2
try:
    db.execute("INSERT INTO settings (id, minimum_cash_buffer_vnd, period_start_day) VALUES (2, 2000000, 1);")
    assert False, "Should have thrown CHECK constraint error for id = 2"
except sqlite3.IntegrityError as e:
    print(f"[✓] Settings id = 2 rejected as expected: {e}")

# Invalid duplicate id = 1
try:
    db.execute("INSERT INTO settings (id, minimum_cash_buffer_vnd, period_start_day) VALUES (1, 3000000, 1);")
    assert False, "Should have thrown PRIMARY KEY error for duplicate id = 1"
except sqlite3.IntegrityError as e:
    print(f"[✓] Second row with id = 1 rejected as expected: {e}")

# ==============================================================================
# 3. PROBING FOREIGN KEY INTEGRITY & CASCADES
# ==============================================================================
print("\n>>> Probing Foreign Key Integrity & Cascades...")

# FK violation: referencing non-existent ledger_account
try:
    db.execute("INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (1, 9999, 100000, 0);")
    assert False, "Should have thrown FK error for non-existent account"
except sqlite3.IntegrityError as e:
    print(f"[✓] FK violation on non-existent account caught: {e}")

# FK violation: deleting referenced ledger_account (RESTRICT)
try:
    db.execute("DELETE FROM ledger_accounts WHERE id = 1;")
    assert False, "Should have thrown RESTRICT FK error on deleting referenced ledger_account"
except sqlite3.IntegrityError as e:
    print(f"[✓] Deleting referenced ledger_account blocked by RESTRICT: {e}")

# CASCADE delete: deleting journal_transactions cascades to journal_postings
tx_postings_count = db.execute("SELECT COUNT(*) FROM journal_postings WHERE transaction_id = 1;").fetchone()[0]
assert tx_postings_count == 2
db.execute("DELETE FROM journal_transactions WHERE id = 1;")
tx_postings_after = db.execute("SELECT COUNT(*) FROM journal_postings WHERE transaction_id = 1;").fetchone()[0]
print(f"[*] Postings before tx delete: {tx_postings_count}, after: {tx_postings_after}")
assert tx_postings_after == 0
print("[✓] CASCADE delete from journal_transactions to journal_postings verified.")

# ==============================================================================
# 4. PROBING SELF-REFERENCING FKs & DEFERRAL (reverses_tx_id, replaced_by_tx_id)
# ==============================================================================
print("\n>>> Probing Self-Referencing FKs & Deferral Rules...")

# Case 4.1: Normal sequential insertion (T1 inserted first, then R1 reverses T1)
db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at) VALUES (10, 'EXPENSE', 'POSTED', 1729900000000, 1729900000000);")
db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at, reverses_tx_id) VALUES (11, 'REVERSAL', 'POSTED', 1729900000000, 1729900000000, 10);")
print("[✓] Sequential reversal insertion (R1 -> T1) succeeded.")

# Case 4.2: T1 updated to point replaced_by_tx_id to T2 after T2 is created
db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at) VALUES (12, 'EXPENSE', 'POSTED', 1729900000000, 1729900000000);")
db.execute("UPDATE journal_transactions SET status = 'SUPERSEDED', replaced_by_tx_id = 12 WHERE id = 10;")
print("[✓] Editing T1 -> T2 with replaced_by_tx_id pointer succeeded.")

# Case 4.3: Forward-referencing / Mutual reference with PRAGMA defer_foreign_keys
# Test without deferral first: inserting T20 pointing to non-existent T21 fails immediately
try:
    db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at, replaced_by_tx_id) VALUES (20, 'EXPENSE', 'SUPERSEDED', 1729900000000, 1729900000000, 21);")
    assert False, "Should have thrown FK error for non-existent forward reference"
except sqlite3.IntegrityError as e:
    print(f"[✓] Forward reference rejected immediately when deferral is off: {e}")

# Now test with PRAGMA defer_foreign_keys = ON inside a transaction
db.execute("BEGIN TRANSACTION;")
db.execute("PRAGMA defer_foreign_keys = ON;")
# Forward reference T20 -> T21 (T21 does not exist yet!)
db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at, replaced_by_tx_id) VALUES (20, 'EXPENSE', 'SUPERSEDED', 1729900000000, 1729900000000, 21);")
# Now insert T21 before commit
db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at) VALUES (21, 'EXPENSE', 'POSTED', 1729900000000, 1729900000000);")
# Commit should succeed because T21 exists by commit time
db.execute("COMMIT;")
print("[✓] PRAGMA defer_foreign_keys = ON successfully deferred FK check until COMMIT, allowing forward reference.")

# Test deferral violation at COMMIT time
db.execute("BEGIN TRANSACTION;")
db.execute("PRAGMA defer_foreign_keys = ON;")
db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at, replaced_by_tx_id) VALUES (30, 'EXPENSE', 'SUPERSEDED', 1729900000000, 1729900000000, 9999);")
try:
    db.execute("COMMIT;")
    assert False, "Commit should fail when deferred FK is still unresolved"
except sqlite3.IntegrityError as e:
    db.execute("ROLLBACK;")
    print(f"[✓] Deferred FK violation caught at COMMIT time: {e}")

# ==============================================================================
# 5. PROBING 64-BIT INTEGER VND OVERFLOW IN SQLITE
# ==============================================================================
print("\n>>> Probing 64-bit Integer VND Overflow Guard in SQLite...")
MAX_SAFE_VND = 9_000_000_000_000_000

# SQLite INTEGER natively supports up to 64-bit signed integers (-2^63 to 2^63 - 1 = ~9.22e18)
db.execute("INSERT INTO ledger_accounts (id, name, kind, is_liquid, credit_limit, created_at) VALUES (99, 'Big Vault', 'ASSET_BANK', 1, 0, 1729900000000);")
db.execute("INSERT INTO journal_transactions (id, tx_type, status, occurred_at, created_at) VALUES (99, 'OPENING_BALANCE', 'POSTED', 1729900000000, 1729900000000);")
db.execute(f"INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (99, 99, {MAX_SAFE_VND}, 0);")
retrieved_amount = db.execute("SELECT debit_vnd FROM journal_postings WHERE transaction_id = 99;").fetchone()[0]
print(f"[*] Stored MAX_SAFE_VND: {MAX_SAFE_VND}, Retrieved: {retrieved_amount}")
assert retrieved_amount == MAX_SAFE_VND
print("[✓] SQLite preserves exact 64-bit integer 9 quadrillion VND without float precision loss.")

# ==============================================================================
# 6. PROBING IDEMPOTENCY KEY UNIQUE CONSTRAINT
# ==============================================================================
print("\n>>> Probing Idempotency Key Constraint...")
db.execute("INSERT INTO journal_transactions (id, tx_type, status, description, occurred_at, created_at, idempotency_key) VALUES (101, 'EXPENSE', 'POSTED', 'Coffee', 1729900000000, 1729900000000, 'idemp-tx-001');")
try:
    db.execute("INSERT INTO journal_transactions (id, tx_type, status, description, occurred_at, created_at, idempotency_key) VALUES (102, 'EXPENSE', 'POSTED', 'Coffee again', 1729900000000, 1729900000000, 'idemp-tx-001');")
    assert False, "Should have rejected duplicate idempotency key"
except sqlite3.IntegrityError as e:
    print(f"[✓] Duplicate idempotency key rejected by UNIQUE constraint: {e}")

# Null idempotency keys are allowed multiple times
db.execute("INSERT INTO journal_transactions (id, tx_type, status, description, occurred_at, created_at, idempotency_key) VALUES (103, 'EXPENSE', 'POSTED', 'No key 1', 1729900000000, 1729900000000, NULL);")
db.execute("INSERT INTO journal_transactions (id, tx_type, status, description, occurred_at, created_at, idempotency_key) VALUES (104, 'EXPENSE', 'POSTED', 'No key 2', 1729900000000, 1729900000000, NULL);")
print("[✓] Multiple NULL idempotency keys permitted.")

print("\n=================================================================")
print("ALL DRIFT SCHEMA & RELATIONAL INVARIANT PROBES PASSED 100%!")
print("=================================================================")
