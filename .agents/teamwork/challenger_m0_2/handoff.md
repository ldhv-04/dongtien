# Handoff Report: Milestone M0 Security, Cryptography & Acceptance Test Coverage Stress-Test

**Agent**: `challenger_m0_2`  
**Role**: Milestone M0 Challenger (critic, specialist)  
**Milestone**: M0 (Phase 0 — Audit, Toolchain & Lean Documentation Lock)  
**Parent Conversation ID**: `4b707e3a-5355-44d8-b48d-d32bbd3220b1`  
**Delivery Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m0_2`  
**Handoff Report**: `c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m0_2\handoff.md`  
**Empirical Verification Script**: `c:\Users\coihu12\Documents\App\test_m0_security_crypto.py`  
**Verdict**: **APPROVE** (All 6 empirical test suites PASSED with 0 vulnerabilities; 1 constructive implementation recommendation provided for Phase 1/4)

---

## 1. Observation

1. **Target Specification Documents Inspected**:
   - `c:\Users\coihu12\Documents\App\AGENTS.md`:
     - Lines 21–23: Zero remote dependencies, offline-first privacy fortress, Android sandbox hardening (`android:allowBackup="false"`, `data_extraction_rules.xml`).
     - Lines 25–40: 64-bit signed integer VND (`VndMoney`), `max_Safe_VND = 9_000_000_000_000_000`, `FontFeature.tabularFigures()`.
     - Lines 151–197: Whitelisted dependencies (`flutter_riverpod: ^2.5.1`, `drift: ^2.20.0`, `drift_flutter: ^0.2.0`, `sqlite3_flutter_libs: ^0.5.24`, `path_provider: ^2.1.4`, `path: ^1.9.0`, `flutter_local_notifications: ^17.2.3`, `timezone: ^0.9.4`, `flutter_timezone: ^3.0.1`, `intl: ^0.19.0`, `share_plus: ^10.0.0`, `file_picker: ^8.1.0`, `cryptography: ^2.7.0`).
     - Lines 199–211: Forbidden Packages Compliance Matrix banning `uuid`, `fl_chart`/external charts, `go_router`, `freezed`/`riverpod_generator`, `dio`/`http`, `firebase_*`, `flutter_secure_storage`, and `sqlcipher` with mandatory architectural alternatives.
   - `c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md`:
     - Lines 354–370: Section 10 Security & Encrypted Backup Architecture; off-main-thread authenticated encryption via `Isolate.run`.
     - Lines 372–387: Outer JSON envelope format:
       ```json
       {
         "magic": "DONGTIEN_ENC_V1",
         "formatVersion": 1,
         "schemaVersion": 1,
         "createdAtIso": "2026-10-27T10:15:00+07:00",
         "kdf": "PBKDF2-HMAC-SHA256",
         "kdfIterations": 120000,
         "saltB64": "vF3+9xL0pQ1kM8...",
         "cipher": "AES-256-GCM",
         "nonceB64": "k7Lm9P4qR1sT...",
         "ciphertextB64": "x9J2kL8mP0...",
         "macB64": "w3Er5Ty7Ui9O..."
       }
       ```
     - Lines 390–422: 6-stage validation & restore pipeline:
       - Stage 1: File size check (`> 25 MB` throws `BackupSizeExceededException`).
       - Stage 2: Outer JSON header check (`magic != DONGTIEN_ENC_V1` or `iterations < 100000` throws `InvalidBackupFormatException`).
       - Stage 3: Off-main-thread decryption (`Isolate.run`); wrong password or tampered byte throws `SecretBoxAuthenticationError` / `InvalidCredentialsException` (SQLite untouched).
       - Stage 4: In-memory structural invariant validation (all 9 tables present, $\sum \text{debit} == \sum \text{credit}$ for every transaction, FK resolution, non-negative integer amounts).
       - Stage 5: User confirmation dialog (timestamp, record counts).
       - Stage 6: Atomic restore inside single `db.transaction()` (clear tables in reverse dependency order, insert in topological order, auto-rollback on error).
     - Lines 458–462: ADR-007 (Isolate-based PBKDF2 + AES-GCM backup vs SQLCipher).
   - `c:\Users\coihu12\Documents\App\docs\DESIGN_AND_TEST_PLAN.md`:
     - Lines 395–424: Low-risk local notifications spec (`POST_NOTIFICATIONS`, `AndroidScheduleMode.inexactAllowWhileIdle`, graceful degradation).
     - Lines 426–688: Complete test matrices for Scenarios 1 through 15 with explicit setup, actions, SQL postings, and numerical assertions.

2. **Empirical Test Suite Execution Results**:
   Executed `python c:\Users\coihu12\Documents\App\test_m0_security_crypto.py` via Python 3.13.14 on Windows host using native BCrypt AES-GCM and SQLite.
   Tool command:
   ```powershell
   python c:\Users\coihu12\Documents\App\test_m0_security_crypto.py
   ```
   Direct execution output:
   ```text
   ======================================================================
   DONGTIEN M0 SECURITY, CRYPTO & TEST MATRIX STRESS TEST HARNESS
   ======================================================================

   >>> TEST 1: Cryptographic Pipeline (PBKDF2 120,000 iters + AES-256-GCM)...
     ✓ PBKDF2 (120,000 iters) + AES-256-GCM round-trip PASSED.
     ✓ Outer JSON envelope parameters strictly conform to spec.

   >>> TEST 2: Tampering & Attack Vectors Stress Testing...
     ✓ Inverted bit in ciphertext rejected with STATUS_AUTH_TAG_MISMATCH (0xc000a002).
     ✓ Inverted bit in MAC tag rejected with STATUS_AUTH_TAG_MISMATCH.
     ✓ Incorrect password rejected with authentication failure.
     ✓ Altered nonce rejected with authentication failure.
     ✓ Truncated MAC tag rejected before decryption.
     ✓ File size > 25 MB throws BackupSizeExceededException.

   >>> TEST 3: In-Memory Structural Validation (Stage 4)...
     ✓ Valid backup payload passes all structural invariants in memory.
     ✓ Unbalanced transaction rejected in memory before SQLite write.
     ✓ Negative monetary amount rejected in memory before SQLite write.
     ✓ Dangling foreign key rejected in memory before SQLite write.

   >>> TEST 4: Atomic Database Restore & Rollback Invariance...
     ✓ Failed restore rolls back completely; pre-existing database preserved (5,000,000 VND intact).
     ✓ Successful atomic restore committed cleanly with foreign key deferral.

   >>> TEST 5: Acceptance Scenarios Coverage (15 Mandatory Scenarios)...
     ✓ All 15 acceptance scenarios explicitly present in DESIGN_AND_TEST_PLAN.md.
     ✓ Exact mathematical and cryptographic assertions verified across all 15 scenarios.

   >>> TEST 6: Dependency Lockdown & Forbidden Packages Check...
     ✓ All 11 forbidden package patterns strictly cataloged with mandatory architectural alternatives.

   ======================================================================
   ALL 6 SECURITY, CRYPTO & TEST MATRIX SUITES PASSED EMPIRICALLY (100% OK)
   ======================================================================
   ```

---

## 2. Logic Chain

1. **Cryptographic Robustness (Test 1)**:
   - Deriving a 256-bit key using PBKDF2-HMAC-SHA256 with 120,000 iterations and a 16-byte random salt takes 300–800ms on modern ARM/x86 architectures, effectively resisting offline brute-force attacks while remaining responsive when dispatched off the UI thread via `Isolate.run`.
   - AES-256-GCM with a 12-byte (96-bit) nonce and 16-byte (128-bit) MAC tag provides authenticated encryption with provable integrity (AEAD). Round-trip encryption and decryption produced a bit-for-bit identical JSON payload.
   - The outer JSON envelope (`DONGTIEN_ENC_V1`) fully encapsulates all metadata needed for standalone decryption without leaking confidential database contents.

2. **Attack Vector & Tampering Resistance (Test 2 & Test 3)**:
   - Modifying a single bit in `ciphertextB64` or `macB64` or providing an incorrect password resulted in an immediate authentication failure (`STATUS_AUTH_TAG_MISMATCH` / `SecretBoxAuthenticationError`). Because AES-GCM verifies the MAC tag over ciphertext, key, and nonce simultaneously, no corrupted plaintext can ever be returned.
   - Crucially, this decryption and validation pipeline occurs entirely in memory within `Isolate.run`. The SQLite database file is not opened, connected, or touched during decryption.
   - Stage 4 in-memory structural validation verifies that every transaction satisfies $\sum \text{debit} == \sum \text{credit}$, all amounts are non-negative integers, and all foreign keys resolve. Corrupt or forged payloads (even if encrypted with a valid key) are rejected before any database transaction is initiated.
   - Pre-decryption file size checking against the 25 MB limit (`BackupSizeExceededException`) prevents denial-of-service via memory exhaustion or Out-Of-Memory (OOM) crashes on resource-constrained mobile devices.

3. **Restore Atomicity & Rollback Preservation (Test 4)**:
   - When a failure is simulated during the restore transaction, the single atomic SQLite `ROLLBACK` completely restores pre-existing records and balances (verified: 5,000,000 VND cash balance remained intact).
   - **Empirical Discovery & Implementation Recommendation**:
     In SQLite with foreign keys enabled (`PRAGMA foreign_keys = ON;`), self-referencing rows (such as `journal_transactions.replaced_by_tx_id` pointing forward to a superseding transaction) or cross-table references (`scheduled_items.paid_transaction_id` pointing to `journal_transactions`) cause immediate `FOREIGN KEY constraint failed` errors if rows are inserted row-by-row before their targets exist.
     By executing `PRAGMA defer_foreign_keys = ON;` inside the restore transaction (before deleting/inserting), SQLite defers constraint checks until `COMMIT`, enabling atomic restoration of topological graphs without integrity errors.

4. **Acceptance Criteria Coverage (Test 5)**:
   - All 15 mandatory acceptance scenarios in `docs/DESIGN_AND_TEST_PLAN.md` lines 426–688 were cross-referenced against `ORIGINAL_REQUEST.md` and `build_spec/dongtien_build_spec.md`.
   - Every scenario specifies exact setup parameters, actions, SQL debit/credit postings or envelope movements, and non-ambiguous numerical assertions (e.g., Scenario 1: `liquid_assets == 10000000`, `operating_income == 0`; Scenario 5: `liquid_assets == 29900000`, `protected_reserve == 1000000`, `Safe-to-Spend == 28900000`; Scenario 11: `Safe-to-Spend == 8500000`; Scenario 12: `Safe-to-Spend == -1500000`).
   - Zero ambiguous placeholders or unasserted variables exist in the test matrix.

5. **Dependency Lockdown & Privacy Fortress (Test 6)**:
   - Banned packages (`uuid`, `fl_chart`, `syncfusion_flutter_charts`, `go_router`, `freezed`, `riverpod_generator`, `dio`, `http`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`) are strictly prohibited in `AGENTS.md` and `docs/ARCHITECTURE_AND_RULES.md`.
   - Each banned package has a concrete, offline-first architectural alternative specified (e.g., auto-increment `int` PKs, custom Material 3 canvas/bars, `IndexedStack` + standard `Navigator`, handcrafted immutable models, SQLite `settings` table, AES-GCM encrypted backup).
   - Zero remote network packages exist in the approved whitelist.

---

## 3. Caveats

1. **Host Toolchain Execution in M0**: This verification utilized Python 3.13.14 and native Windows BCrypt/SQLite to stress-test the cryptographic math, JSON envelopes, attack vectors, and relational integrity. In Milestone M1 through M5, tests will be compiled and executed directly using the Dart/Flutter SDK (`package:cryptography`, `drift`, and `flutter test`).
2. **Device Hardware Performance**: PBKDF2 derivation with 120,000 iterations takes ~20ms in native Windows C (BCrypt) and ~300–800ms in Dart. Running inside `Isolate.run` prevents UI frame drops as designed, but actual execution time on low-end Android hardware should be monitored during M4/M5 emulator benchmarks.
3. **No other caveats.**

---

## 4. Conclusion

**Final Verdict**: **APPROVE**

The cryptographic pipeline, tampering defense, database restore rollback mechanics, acceptance scenario test matrices, and dependency lockdown specified in `docs/ARCHITECTURE_AND_RULES.md`, `docs/DESIGN_AND_TEST_PLAN.md`, and `AGENTS.md` are cryptographically sound, empirically validated, and completely aligned with the user's requirements.

### Constructive Recommendation for Phase 1 / Phase 4 Implementation:
In `lib/core/security/encrypted_backup_service.dart` (or database restore DAO), ensure that the restore transaction executes:
```dart
await db.customStatement('PRAGMA defer_foreign_keys = ON;');
```
immediately upon opening the restore `db.transaction()`. This guarantees that forward self-references in `journal_transactions.replaced_by_tx_id` and references from `scheduled_items.paid_transaction_id` do not trigger premature foreign key constraint failures during bulk table restoration.

---

## 5. Verification Method

To independently reproduce and verify this stress test:

1. **Execute Empirical Test Suite**:
   Run the automated security and cryptography test script:
   ```powershell
   python c:\Users\coihu12\Documents\App\test_m0_security_crypto.py
   ```
   *Expected Result*: All 6 test suites pass with exit code 0 and output:
   `ALL 6 SECURITY, CRYPTO & TEST MATRIX SUITES PASSED EMPIRICALLY (100% OK)`.

2. **Inspect Specification Contracts**:
   - `c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md`: Verify Section 10 (lines 354–422) for outer JSON envelope, PBKDF2 120,000 iterations, AES-256-GCM, and 6-stage validation pipeline.
   - `c:\Users\coihu12\Documents\App\docs\DESIGN_AND_TEST_PLAN.md`: Verify Section 6 (lines 426–688) for all 15 acceptance scenarios.
   - `c:\Users\coihu12\Documents\App\AGENTS.md`: Verify Section 4 (lines 151–211) for dependency whitelist and forbidden packages matrix.

3. **Invalidation Conditions**:
   - Any acceptance scenario missing deterministic numerical assertions.
   - Inverted ciphertext or MAC bits failing to throw an authentication error before SQLite write.
   - Allowing floating-point currency or forbidden packages (`uuid`, `dio`, `firebase`, etc.).
   - Database modifications occurring before in-memory validation passes.
