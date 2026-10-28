# Milestone M1 Adversarial Challenge Report: Money & Integer Arithmetic

**Agent**: `challenger_m1_1`  
**Role**: Milestone M1 Challenger (Money & Integer Arithmetic Stress-Tester)  
**Date**: 2026-10-27T18:20:00Z  
**Verdict**: **REQUEST_CHANGES**  
**Target Handoff Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_1\handoff.md`

---

## 1. Observation

### 1.1 Baseline Test Suite Execution
- **Command**: `& "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_test.dart`
- **Result**: Passed 30 of 30 tests in 4 seconds.
- **Log snippet**:
  ```text
  00:00 +0: loading C:/Users/coihu12/Documents/App/test/unit/vnd_money_test.dart
  ...
  00:00 +30: All tests passed!
  ```

### 1.2 Adversarial Test Suite Execution
- **Harness File**: `c:\Users\coihu12\Documents\App\test\unit\vnd_money_adversarial_test.dart`
- **Command**: `& "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_adversarial_test.dart`
- **Result**: 26 passed, 2 failed out of 28 test cases.
- **Verbatim Failure 1 (Multi-sign parsing bug)**:
  ```text
  00:00 +23 -1: Adversarial Stress Test: VndFormatter Parsing Multiple consecutive signs should be rejected (BUG REPRODUCTION) [E]
    Expected: null
      Actual: <1000>
    BUG: Double minus "--1000" parsed as positive 1000
    
    package:matcher                                     expect
    package:flutter_test/src/widget_tester.dart 480:18  expect
    test\unit\vnd_money_adversarial_test.dart 348:7     main.<fn>.<fn>
  ```
- **Verbatim Failure 2 (Exception contract mismatch)**:
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

### 1.3 Code Inspection
1. **Target File**: `c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart`
   - Lines 91–98:
     ```dart
     // Check for negative sign
     bool isNegative = false;
     if (sanitized.startsWith('-')) {
       isNegative = true;
       sanitized = sanitized.substring(1).trim();
     } else if (sanitized.startsWith('+')) {
       sanitized = sanitized.substring(1).trim();
     }
     ```
   - Lines 100–108:
     ```dart
     // Remove currency symbol, spaces, non-breaking spaces, and dots
     sanitized = sanitized
         .replaceAll('₫', '')
         .replaceAll('VND', '')
         .replaceAll('vnd', '')
         .replaceAll('.', '')
         .replaceAll(',', '')
         .replaceAll(' ', '')
         .replaceAll('\u00A0', '');
     ```
   - Lines 112–115:
     ```dart
     final int? parsed = int.tryParse(sanitized);
     if (parsed == null) return null;

     final int finalAmount = isNegative ? -parsed : parsed;
     ```
   - Lines 75–82:
     ```dart
     /// Throws [FormatException] if the input cannot be parsed.
     /// Throws [VndOverflowException] if the parsed amount exceeds [VndMoney.maxSafeVnd].
     static int parse(String input) {
       final int? result = tryParse(input);
       if (result == null) {
         throw FormatException('Cannot parse VND amount from: "$input"');
       }
       return result;
     }
     ```

2. **Target File**: `c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart`
   - All boundary checks `±9_000_000_000_000_000` (`maxSafeVnd` / `minSafeVnd`), integer arithmetic operators (`+`, `-`, `*`, `~/`), zero decimal guarantee, and `VndOverflowException` defenses function as specified.

---

## 2. Logic Chain

1. **Premise 1 (Input Sanitization Invariant)**:
   In financial systems, an amount string with multiple signs (such as `--1000`, `++1000`, `+-1000`, `- - 1000`) is malformed input. It must either be rejected outright (`tryParse` returns `null`) or throw an exception. It must never silently invert economic polarity.

2. **Observation Linking**:
   - When `input = '--1000'`, line 93 of `vnd_formatter.dart` detects the first `-` (`sanitized.startsWith('-') == true`), records `isNegative = true`, and strips it: `sanitized = sanitized.substring(1).trim()` -> `'-1000'`.
   - The subsequent `replaceAll` calls (lines 100–108) do not strip `-`. So `sanitized` remains `'-1000'`.
   - Line 112 calls Dart standard `int.tryParse(sanitized)`. Because Dart's `int.tryParse` natively supports a leading `-`, it successfully parses `'-1000'` as integer `-1000`.
   - Line 115 evaluates `finalAmount = isNegative ? -parsed : parsed`. With `isNegative == true` and `parsed == -1000`, `finalAmount = -(-1000) = 1000` (positive 1000 VND).
   - Identical logic applies to `++1000` (evaluates to `1000`), `+-1000` (evaluates to `-1000`), and `'- - 1000'` (spaces stripped, evaluates to `1000`).

3. **Premise 2 (Public Interface Contract Invariant)**:
   The public docstring of `VndFormatter.parse()` explicitly states:
   `Throws [VndOverflowException] if the parsed amount exceeds [VndMoney.maxSafeVnd].`
   Callers rely on this contract to differentiate between syntax errors (`FormatException`) and numerical overflow (`VndOverflowException`).

4. **Observation Linking**:
   - In `vnd_formatter.dart` lines 117–120, `tryParse` returns `null` when `finalAmount > VndMoney.maxSafeVnd || finalAmount < VndMoney.minSafeVnd`.
   - In line 77, `parse` calls `tryParse`. When `tryParse` returns `null` due to overflow, line 78 catches `result == null` and throws `FormatException`.
   - Therefore, `VndOverflowException` is never thrown by `VndFormatter.parse`, violating its interface contract.

---

## 3. Challenge Report

### Challenge Summary
**Overall risk assessment**: **MEDIUM** (Arithmetic engine is solid; text parser has edge-case bugs).

### Challenges

#### [Medium] Challenge 1: Double-Sign Injection in `VndFormatter.tryParse`
- **Assumption challenged**: That stripping the first leading sign and passing the remainder to `int.tryParse` safely parses signed strings.
- **Attack scenario**: User or automated input enters `--50.000 ₫` (or accidentally types double minus) into transaction entry or search filter.
- **Blast radius**: The negative amount is inverted to positive `50.000 ₫` instead of being rejected, potentially turning an expense into income or an invalid filter into an unintended match.
- **Mitigation**:
  Add an explicit guard immediately after removing the leading sign:
  ```dart
  if (sanitized.contains('-') || sanitized.contains('+')) {
    return null;
  }
  ```

#### [Low] Challenge 2: Docstring Contract Divergence in `VndFormatter.parse`
- **Assumption challenged**: That `VndFormatter.parse` throws `VndOverflowException` on overflow as documented.
- **Attack scenario**: Caller invokes `VndFormatter.parse(userInput)` inside `try ... on VndOverflowException catch (e)` to display an overflow warning dialog.
- **Blast radius**: The `VndOverflowException` handler is never reached; unhandled `FormatException` crashes the flow or falls into a generic error toast.
- **Mitigation**:
  Update `VndFormatter.parse` to detect overflow before throwing `FormatException`:
  ```dart
  static int parse(String input) {
    final int? result = tryParse(input);
    if (result != null) return result;

    // Check if the parse failure was specifically due to overflow
    String sanitized = input.trim();
    if (sanitized.startsWith('-') || sanitized.startsWith('+')) {
      sanitized = sanitized.substring(1).trim();
    }
    sanitized = sanitized
        .replaceAll('₫', '')
        .replaceAll('VND', '')
        .replaceAll('vnd', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '');
    final int? rawInt = int.tryParse(sanitized);
    if (rawInt != null && (rawInt > VndMoney.maxSafeVnd || -rawInt < VndMoney.minSafeVnd)) {
      throw VndOverflowException(
        'VND amount exceeds max safe limit (±${VndMoney.maxSafeVnd} ₫)',
      );
    }
    throw FormatException('Cannot parse VND amount from: "$input"');
  }
  ```

---

## 4. Stress Test Results Matrix

| Scenario / Test Case | Input / Operation | Expected Behavior | Actual Behavior | Result |
|---|---|---|---|---|
| **Boundary Max** | `VndMoney(9_000_000_000_000_000)` | Allowed, `amount == 9e15` | `amount == 9e15` | **PASS** |
| **Boundary Min** | `VndMoney(-9_000_000_000_000_000)` | Allowed, `amount == -9e15` | `amount == -9e15` | **PASS** |
| **Overflow Max + 1** | `VndMoney(9_000_000_000_000_001)` | Throws `VndOverflowException` | Throws `VndOverflowException` | **PASS** |
| **Underflow Min - 1** | `VndMoney(-9_000_000_000_000_001)` | Throws `VndOverflowException` | Throws `VndOverflowException` | **PASS** |
| **Int64 Max Overflow** | `VndMoney(9223372036854775807)` | Throws `VndOverflowException` | Throws `VndOverflowException` | **PASS** |
| **Int64 Min Overflow** | `VndMoney(-9223372036854775808)` | Throws `VndOverflowException` | Throws `VndOverflowException` | **PASS** |
| **Restricted Positive 0** | `VndMoney.positive(0)` | Throws `ArgumentError` | Throws `ArgumentError` | **PASS** |
| **Restricted Positive Negative** | `VndMoney.positive(-1)` | Throws `ArgumentError` | Throws `ArgumentError` | **PASS** |
| **Restricted NonNegative -1** | `VndMoney.nonNegative(-1)` | Throws `ArgumentError` | Throws `ArgumentError` | **PASS** |
| **Restricted NonNegative 0** | `VndMoney.nonNegative(0)` | Allowed, `amount == 0` | `amount == 0` | **PASS** |
| **Addition Overflow** | `maxSafeVnd + VndMoney(1)` | Throws `VndOverflowException` | Throws `VndOverflowException` | **PASS** |
| **Addition Cancel** | `maxSafeVnd + minSafeVnd` | `VndMoney.zero` | `VndMoney.zero` | **PASS** |
| **Subtraction Underflow** | `minSafeVnd - VndMoney(1)` | Throws `VndOverflowException` | Throws `VndOverflowException` | **PASS** |
| **Multiplication Overflow** | `VndMoney(4.5e15 + 1) * 2` | Throws `VndOverflowException` | Throws `VndOverflowException` | **PASS** |
| **Multiplication by 0** | `maxSafeVnd * 0` | `VndMoney.zero` | `VndMoney.zero` | **PASS** |
| **Multiplication Int64 Scalar** | `VndMoney(1) * -0x8000000000000000` | Throws `VndOverflowException` | Throws `VndOverflowException` | **PASS** |
| **Division by Zero** | `VndMoney(100) ~/ 0` | Throws `ArgumentError` | Throws `ArgumentError` | **PASS** |
| **Truncating Division** | `VndMoney(10) ~/ 3` | `VndMoney(3)` | `VndMoney(3)` | **PASS** |
| **Truncating Division Negative** | `VndMoney(-10) ~/ 3` | `VndMoney(-3)` | `VndMoney(-3)` | **PASS** |
| **Ceiling Division Math** | `((10.000.000 - 0) + 3 - 1) ~/ 3` | `3.333.334 ₫` | `3.333.334 ₫` | **PASS** |
| **Format Zero** | `VndFormatter.format(0)` | `'0 ₫'` | `'0 ₫'` | **PASS** |
| **Format Positive with Sign** | `VndFormatter.format(1250000, showSign: true)` | `'+1.250.000 ₫'` | `'+1.250.000 ₫'` | **PASS** |
| **Format Negative with Sign** | `VndFormatter.format(-1250000, showSign: true)` | `'-1.250.000 ₫'` | `'-1.250.000 ₫'` | **PASS** |
| **Format Multi-Trillion** | `VndFormatter.format(9e15)` | `'9.000.000.000.000.000 ₫'` | `'9.000.000.000.000.000 ₫'` | **PASS** |
| **Tabular Figures Feature** | `VndFormatter.withTabularFigures(style)` | Contains `FontFeature.tabularFigures()` | Contains `FontFeature.tabularFigures()` | **PASS** |
| **Parse Various Separators** | `'1.250.000'`, `'1,250,000'`, `'1 250 000'` | `1250000` | `1250000` | **PASS** |
| **Parse Consecutive Signs** | `VndFormatter.tryParse('--1000')` | `null` (reject) | `<1000>` (accepted as +1000) | **FAIL (BUG)** |
| **Parse Overflow Exception Type** | `VndFormatter.parse('9.000.000.000.000.001 ₫')` | Throws `VndOverflowException` | Throws `FormatException` | **FAIL (BUG)** |

---

## 5. Caveats

- Testing was performed purely on the Dart VM (`flutter test`) in desktop simulation mode.
- Does not test SQLite/Drift column serialisation (this is handled by `auditor_m1_1` / `worker_m1_1`).

---

## 6. Conclusion & Recommendation

1. **Monetary Value Object (`VndMoney`)**: **APPROVED**  
   The arithmetic engine, integer overflow guarding at `9_000_000_000_000_000`, division by zero checks, negation, comparison, and formatting delegations are robust, mathematically sound, and compliant with all project non-negotiables.

2. **Monetary Formatter & Parser (`VndFormatter`)**: **REQUEST_CHANGES**  
   Must resolve:
   - Reject multiple consecutive/embedded signs (`--1000`, `++1000`, `+-1000`, `- - 1000`) in `VndFormatter.tryParse`.
   - Align `VndFormatter.parse` with its public docstring contract by throwing `VndOverflowException` on overflow amounts.

Once `worker_m1_1` applies the 10-line fix described in Section 3, running `test/unit/vnd_money_adversarial_test.dart` will pass 100%, and Milestone M1 can be unconditionally approved.

---

## 7. Verification Method

To independently reproduce the findings and verify the subsequent fix:

1. Run baseline unit tests:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_test.dart
   ```
2. Run the adversarial stress test suite:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_adversarial_test.dart
   ```
   - Before fix: Fails with 2 failures (`--1000` evaluates to `<1000>`, and `parse()` throws `FormatException` instead of `VndOverflowException`).
   - After fix: Passes 28 of 28 tests with exit code 0.
