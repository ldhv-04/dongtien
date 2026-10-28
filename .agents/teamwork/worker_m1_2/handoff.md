# Milestone M1 Bugfix Handoff Report: VndFormatter Corrections & Verification

**Agent**: `worker_m1_2`  
**Role**: VndFormatter Bugfix & Verification Engineer  
**Date**: 2026-10-27T18:38:00Z  
**Target Handoff Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1_2\handoff.md`  

---

## 1. Observation

### 1.1 Baseline Failure Reproduction
Prior to applying code modifications, running the adversarial test suite against `c:\Users\coihu12\Documents\App\test\unit\vnd_money_adversarial_test.dart` yielded 2 test failures out of 28:
- **Command**:
  ```powershell
  & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_adversarial_test.dart
  ```
- **Verbatim Error 1 (BUG-M1-01: Multi-sign parsing)**:
  ```text
  00:00 +23 -1: Adversarial Stress Test: VndFormatter Parsing Multiple consecutive signs should be rejected (BUG REPRODUCTION) [E]
    Expected: null
      Actual: <1000>
    BUG: Double minus "--1000" parsed as positive 1000
    
    package:matcher                                     expect
    package:flutter_test/src/widget_tester.dart 480:18  expect
    test\unit\vnd_money_adversarial_test.dart 348:7     main.<fn>.<fn>
  ```
- **Verbatim Error 2 (BUG-M1-02: Docstring contract mismatch)**:
  ```text
  00:00 +25 -2: Adversarial Stress Test: VndFormatter Parsing parse() throws VndOverflowException on overflow per docstring (BUG REPRODUCTION) [E]
    Expected: throws <Instance of 'VndOverflowException'>
      Actual: <Closure: () => int>
       Which: threw FormatException:<FormatException: Cannot parse VND amount from: "9.000.000.000.000.001 ₫">
              stack package:dongtien/core/money/vnd_formatter.dart 79:7  VndFormatter.parse
              test\unit\vnd_money_adversarial_test.dart 389:28     main.<fn>.<fn>.<fn>
              package:matcher                                      expect
              package:flutter_test/src/widget_tester.dart 480:18   expect
              test\unit\vnd_money_adversarial_test.dart 388:7      main.<fn>.<fn>
              
              which is not an instance of 'VndOverflowException'
    Docstring specifies throwing VndOverflowException on overflow, but currently throws FormatException
  ```

### 1.2 Code Inspection
In `c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart`:
- `tryParse` stripped only the first sign via `sanitized.substring(1).trim()`, leaving subsequent signs intact for Dart's `int.tryParse()`, allowing `--1000` to be parsed as `-1000` and inverted by `isNegative ? -parsed : parsed` into positive `1000`.
- `parse` blindly caught `result == null` from `tryParse` and threw `FormatException`, never raising `VndOverflowException` even when amounts strictly exceeded `±9_000_000_000_000_000`.

### 1.3 Changes Made
1. **`lib/core/money/vnd_formatter.dart`**:
   - In `tryParse`: Added strict check immediately after leading sign extraction:
     ```dart
     if (sanitized.contains('-') || sanitized.contains('+')) {
       return null;
     }
     ```
   - In `parse`: Added overflow detection covering both 64-bit integer overflows and arbitrary-precision `BigInt` overflows exceeding `VndMoney.maxSafeVnd` / `VndMoney.minSafeVnd`:
     ```dart
     final int? rawInt = int.tryParse(sanitized);
     if (rawInt != null &&
         (rawInt > VndMoney.maxSafeVnd || -rawInt < VndMoney.minSafeVnd)) {
       throw const VndOverflowException(
         'VND amount exceeds max safe limit (±${VndMoney.maxSafeVnd} ₫)',
       );
     }

     final BigInt? rawBigInt = BigInt.tryParse(sanitized);
     if (rawBigInt != null &&
         (rawBigInt > BigInt.from(VndMoney.maxSafeVnd) ||
             -rawBigInt < BigInt.from(VndMoney.minSafeVnd))) {
       throw const VndOverflowException(
         'VND amount exceeds max safe limit (±${VndMoney.maxSafeVnd} ₫)',
       );
     }
     ```
2. **`test/unit/vnd_money_test.dart`**:
   - Added unit test cases under `Parsing Currency Strings` validating consecutive sign rejection and `VndOverflowException` throwing.
3. **`test/unit/vnd_money_adversarial_test.dart`**:
   - Formatted using `dart format`.

---

## 2. Logic Chain

1. **Step 1 (BUG-M1-01 Fix)**:
   - *Observation*: Input `'--1000'` has first `-` removed, leaving `'-1000'`.
   - *Reasoning*: A valid currency string can have at most one leading sign. If `sanitized.contains('-') || sanitized.contains('+')` evaluates to true after leading sign extraction, the string contains multiple or embedded signs and must be rejected as invalid input.
   - *Outcome*: `VndFormatter.tryParse('--1000')`, `tryParse('++1000')`, `tryParse('+-1000')`, and `tryParse('- - 1000')` return `null`.

2. **Step 2 (BUG-M1-02 Fix)**:
   - *Observation*: The docstring of `parse()` declares: `Throws [VndOverflowException] if the parsed amount exceeds [VndMoney.maxSafeVnd]`.
   - *Reasoning*: When `tryParse()` returns `null`, the failure may be due to syntactic formatting errors or monetary overflow beyond `±9_000_000_000_000_000`. By sanitizing currency notations/separators and parsing the raw numeric value with `int.tryParse` and `BigInt.tryParse`, numerical overflows specifically throw `const VndOverflowException(...)`, preserving the interface contract while still throwing `FormatException` on invalid text or multiple signs.
   - *Outcome*: `VndFormatter.parse('9.000.000.000.000.001 ₫')` throws `VndOverflowException`.

3. **Step 3 (Lint & Formatting Compliance)**:
   - *Observation*: `flutter analyze` reported `prefer_const_constructors` for `VndOverflowException`.
   - *Reasoning*: Because `${VndMoney.maxSafeVnd}` interpolates a `static const int`, the message string is a compile-time constant, enabling `const VndOverflowException(...)`.
   - *Outcome*: `flutter analyze` reports `No issues found!`.

---

## 3. Caveats

- No caveats. The implementation relies entirely on native Dart integer / BigInt parsing and String manipulation, with zero external dependencies and zero platform channel requirements.

---

## 4. Conclusion

Both reported bugs in `VndFormatter` (BUG-M1-01 and BUG-M1-02) have been resolved with genuine, minimal logic:
- `VndFormatter.tryParse` rejects consecutive and embedded signs.
- `VndFormatter.parse` honors its docstring exception contract, throwing `VndOverflowException` on overflow and `FormatException` on syntax errors.
- 100% of unit, adversarial, and database tests pass.
- Static analysis and formatting gates pass with zero warnings, errors, or unformatted files.

---

## 5. Verification Method

To independently verify this implementation:

1. **Run Adversarial Stress Test Suite**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_adversarial_test.dart
   ```
   *Expected output*: `00:00 +28: All tests passed!`

2. **Run Baseline Unit Test Suite**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_test.dart
   ```
   *Expected output*: `00:00 +33: All tests passed!`

3. **Run Drift Database Test Suite**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/database/app_database_test.dart
   ```
   *Expected output*: `00:00 +14: All tests passed!`

4. **Run Static Analysis Gate**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" analyze
   ```
   *Expected output*: `No issues found!`

5. **Run Formatting Compliance Gate**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe" format --output=none --set-exit-if-changed .
   ```
   *Expected output*: `Formatted 8 files (0 changed)` with exit code 0.
