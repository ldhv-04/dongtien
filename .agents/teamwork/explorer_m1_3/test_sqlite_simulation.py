import sqlite3

def run_tests():
    conn = sqlite3.connect(':memory:')
    conn.execute('PRAGMA foreign_keys = ON;')

    # 1. Create tables
    conn.execute('''
    CREATE TABLE ledger_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      is_liquid INTEGER NOT NULL DEFAULT 0,
      credit_limit INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    );
    ''')

    conn.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      ledger_account_id INTEGER NOT NULL REFERENCES ledger_accounts(id),
      icon_code INTEGER NOT NULL,
      color_hex TEXT NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 1,
      is_archived INTEGER NOT NULL DEFAULT 0
    );
    ''')

    conn.execute('''
    CREATE TABLE journal_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tx_type TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'POSTED',
      description TEXT NOT NULL,
      occurred_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      idempotency_key TEXT UNIQUE,
      reverses_tx_id INTEGER REFERENCES journal_transactions(id),
      replaced_by_tx_id INTEGER REFERENCES journal_transactions(id)
    );
    ''')

    conn.execute('''
    CREATE TABLE envelopes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      policy TEXT NOT NULL,
      reserved_balance_vnd INTEGER NOT NULL DEFAULT 0,
      allow_negative_exception INTEGER NOT NULL DEFAULT 0,
      target_amount_vnd INTEGER,
      target_date_ms INTEGER,
      period_limit_vnd INTEGER,
      rollover_enabled INTEGER NOT NULL DEFAULT 0,
      priority INTEGER NOT NULL DEFAULT 1,
      is_archived INTEGER NOT NULL DEFAULT 0
    );
    ''')

    conn.execute('''
    CREATE TABLE journal_postings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL REFERENCES journal_transactions(id),
      account_id INTEGER NOT NULL REFERENCES ledger_accounts(id),
      debit_vnd INTEGER NOT NULL DEFAULT 0,
      credit_vnd INTEGER NOT NULL DEFAULT 0,
      category_id INTEGER REFERENCES categories(id),
      envelope_id INTEGER REFERENCES envelopes(id),
      CHECK ((debit_vnd > 0 AND credit_vnd = 0) OR (credit_vnd > 0 AND debit_vnd = 0))
    );
    ''')

    conn.execute('''
    CREATE TABLE category_budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL REFERENCES categories(id),
      year_month INTEGER NOT NULL,
      limit_vnd INTEGER NOT NULL,
      alert_threshold_pct INTEGER NOT NULL DEFAULT 80,
      UNIQUE(category_id, year_month),
      CHECK (limit_vnd > 0)
    );
    ''')

    conn.execute('''
    CREATE TABLE settings (
      id INTEGER PRIMARY KEY DEFAULT 1,
      minimum_cash_buffer_vnd INTEGER NOT NULL DEFAULT 0,
      period_start_day INTEGER NOT NULL DEFAULT 1,
      daily_reminder_hour INTEGER NOT NULL DEFAULT 20,
      daily_reminder_minute INTEGER NOT NULL DEFAULT 0,
      notifications_enabled INTEGER NOT NULL DEFAULT 0,
      schema_version INTEGER NOT NULL DEFAULT 1
    );
    ''')

    # 2. Seed data
    now = 1730000000000
    conn.execute('INSERT INTO ledger_accounts (id, name, kind, is_liquid, credit_limit, is_archived, created_at) VALUES (1, ?, ?, 0, 0, 0, ?)', ('Vốn ban đầu', 'EQUITY_OPENING', now))
    conn.execute('INSERT INTO ledger_accounts (id, name, kind, is_liquid, credit_limit, is_archived, created_at) VALUES (2, ?, ?, 0, 0, 0, ?)', ('Thu nhập', 'INCOME', now))
    conn.execute('INSERT INTO ledger_accounts (id, name, kind, is_liquid, credit_limit, is_archived, created_at) VALUES (3, ?, ?, 0, 0, 0, ?)', ('Chi tiêu', 'EXPENSE', now))

    cats = [
      ('Lương', 'INCOME', 2, 0xe6f3, '#4E886F'),
      ('Thưởng', 'INCOME', 2, 0xeeb8, '#EE8D00'),
      ('Ăn uống', 'EXPENSE', 3, 0xe532, '#E86B1C'),
      ('Di chuyển', 'EXPENSE', 3, 0xef50, '#D99650'),
      ('Hoá đơn & Tiện ích', 'EXPENSE', 3, 0xf2eb, '#FAA800'),
      ('Nhà cửa', 'EXPENSE', 3, 0xf0dc, '#65605C'),
      ('Mua sắm', 'EXPENSE', 3, 0xf37d, '#FD8240'),
      ('Y tế', 'EXPENSE', 3, 0xf166, '#E0462F')
    ]
    for name, kind, acc_id, icon, color in cats:
      conn.execute('INSERT INTO categories (name, kind, ledger_account_id, icon_code, color_hex, is_default, is_archived) VALUES (?, ?, ?, ?, ?, 1, 0)', (name, kind, acc_id, icon, color))

    conn.execute('INSERT INTO settings (id, minimum_cash_buffer_vnd, period_start_day, daily_reminder_hour, daily_reminder_minute, notifications_enabled, schema_version) VALUES (1, 0, 1, 20, 0, 0, 1)')

    conn.commit()

    # Assertions
    accounts = conn.execute('SELECT count(*) FROM ledger_accounts').fetchone()[0]
    categories = conn.execute('SELECT count(*) FROM categories').fetchone()[0]
    settings_row = conn.execute('SELECT count(*) FROM settings').fetchone()[0]
    tx_count = conn.execute('SELECT count(*) FROM journal_transactions').fetchone()[0]
    postings_count = conn.execute('SELECT count(*) FROM journal_postings').fetchone()[0]

    print(f'Accounts seeded: {accounts}, Categories seeded: {categories}, Settings: {settings_row}, Tx: {tx_count}, Postings: {postings_count}')
    assert accounts == 3, f"Expected 3 accounts, got {accounts}"
    assert categories == 8, f"Expected 8 categories, got {categories}"
    assert settings_row == 1, f"Expected 1 settings row, got {settings_row}"
    assert tx_count == 0, f"Expected 0 transactions, got {tx_count}"
    assert postings_count == 0, f"Expected 0 postings, got {postings_count}"

    # Verify initial balances derived are all 0
    # Formula:
    # Asset/Expense: sum(debit) - sum(credit)
    # Income/Liability/Equity: sum(credit) - sum(debit)
    for acc_id in [1, 2, 3]:
        debits = conn.execute('SELECT COALESCE(SUM(debit_vnd), 0) FROM journal_postings WHERE account_id = ?', (acc_id,)).fetchone()[0]
        credits = conn.execute('SELECT COALESCE(SUM(credit_vnd), 0) FROM journal_postings WHERE account_id = ?', (acc_id,)).fetchone()[0]
        assert debits == 0 and credits == 0, f"Account {acc_id} has non-zero postings!"
    print('Initial balances strictly 0 verified!')

    # Test FK enforcement
    try:
      conn.execute('INSERT INTO categories (name, kind, ledger_account_id, icon_code, color_hex) VALUES (?, ?, ?, ?, ?)', ('Fail', 'INCOME', 999, 0, ''))
      assert False, 'FK check FAILED: allowed invalid ledger_account_id'
    except sqlite3.IntegrityError as e:
      print('FK check PASSED for category ledger_account_id:', e)

    # Test Check constraint
    conn.execute('INSERT INTO journal_transactions (id, tx_type, description, occurred_at, created_at) VALUES (1, "EXPENSE", "Test", 1, 1)')
    try:
      conn.execute('INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (1, 1, 100, 100)')
      assert False, 'Check constraint FAILED: allowed debit > 0 and credit > 0'
    except sqlite3.IntegrityError as e:
      print('Check constraint PASSED for posting debit/credit both positive:', e)

    try:
      conn.execute('INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (1, 1, 0, 0)')
      assert False, 'Check constraint FAILED: allowed debit == 0 and credit == 0'
    except sqlite3.IntegrityError as e:
      print('Check constraint PASSED for posting debit==0 and credit==0:', e)

    # Test idempotency_key uniqueness
    conn.execute('INSERT INTO journal_transactions (id, tx_type, description, occurred_at, created_at, idempotency_key) VALUES (2, "INCOME", "Salary", 1, 1, "key-1")')
    try:
      conn.execute('INSERT INTO journal_transactions (id, tx_type, description, occurred_at, created_at, idempotency_key) VALUES (3, "INCOME", "Duplicate", 1, 1, "key-1")')
      assert False, 'Idempotency unique check FAILED'
    except sqlite3.IntegrityError as e:
      print('Idempotency unique check PASSED:', e)

    # Test category_budgets composite unique constraint
    conn.execute('INSERT INTO category_budgets (category_id, year_month, limit_vnd) VALUES (1, 202610, 5000000)')
    try:
      conn.execute('INSERT INTO category_budgets (category_id, year_month, limit_vnd) VALUES (1, 202610, 6000000)')
      assert False, 'CategoryBudgets composite unique check FAILED'
    except sqlite3.IntegrityError as e:
      print('CategoryBudgets unique (category_id, year_month) check PASSED:', e)

    # Test valid balanced transaction
    # Opening Balance: Debit Asset Cash (10M), Credit EQUITY_OPENING (10M)
    conn.execute('INSERT INTO ledger_accounts (id, name, kind, is_liquid, credit_limit, is_archived, created_at) VALUES (4, "Tiền mặt", "ASSET_CASH", 1, 0, 0, ?)', (now,))
    conn.execute('INSERT INTO journal_transactions (id, tx_type, description, occurred_at, created_at) VALUES (10, "OPENING_BALANCE", "Opening", 1, 1)')
    conn.execute('INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (10, 4, 10000000, 0)')
    conn.execute('INSERT INTO journal_postings (transaction_id, account_id, debit_vnd, credit_vnd) VALUES (10, 1, 0, 10000000)')
    conn.commit()

    # Verify balance derivation
    cash_debit = conn.execute('SELECT COALESCE(SUM(debit_vnd), 0) FROM journal_postings WHERE account_id = 4').fetchone()[0]
    cash_credit = conn.execute('SELECT COALESCE(SUM(credit_vnd), 0) FROM journal_postings WHERE account_id = 4').fetchone()[0]
    cash_balance = cash_debit - cash_credit
    assert cash_balance == 10000000, f"Expected 10M cash balance, got {cash_balance}"

    equity_debit = conn.execute('SELECT COALESCE(SUM(debit_vnd), 0) FROM journal_postings WHERE account_id = 1').fetchone()[0]
    equity_credit = conn.execute('SELECT COALESCE(SUM(credit_vnd), 0) FROM journal_postings WHERE account_id = 1').fetchone()[0]
    equity_balance = equity_credit - equity_debit
    assert equity_balance == 10000000, f"Expected 10M equity balance, got {equity_balance}"

    print(f'Cash balance: {cash_balance} VND, Equity balance: {equity_balance} VND')
    print('ALL SQLITE IN-MEMORY INVARIANTS AND TEST SCENARIOS VERIFIED 100% SUCCESSFULLY!')

if __name__ == '__main__':
    run_tests()
