# Empirical Challenge & Verification Handoff Report: Milestone M1 Bugfix Review (Round 2)

**Agent**: `challenger_m1_1_r2`  
**Role**: Empirical Challenger (critic, specialist)  
**Date**: 2026-10-27T18:50:00Z  
**Verdict**: **APPROVE**  
**Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_1_r2`  
**Target Handoff Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_1_r2\handoff.md`  

---

## 1. Observation

### 1.1 Direct Source Code Inspection
In `c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart`:
- **Lines 120–160 (`tryParse`)**:
  ```dart
  static int? tryParse(String input) {
    String sanitized = input.trim();
    if (sanitized.isEmpty) return null;

    // Check for negative sign
    bool isNegative = false;
    if (sanitized.startsWith('-')) {
      isNegative = true;
      sanitized = sanitized.substring(1).trim();
    } else if (sanitized.startsWith('+')) {
      sanitized = sanitized.substring(1).trim();
    }

    if (sanitized.contains('-') || sanitized.contains('+')) {
      return null;
    }
    // ...
  ```
  Lines 133–135 strictly reject any string containing `-` or `+` anywhere within the remainder of the input after extracting at most one leading sign.

- **Lines 76–115 (`parse`)**:
  ```dart
  static int parse(String input) {
    final int? result = tryParse(input);
    if (result != null) return result;

    // Check if the parse failure was specifically due to overflow
    String sanitized = input.trim();
    if (sanitized.startsWith('-') || sanitized.startsWith('+')) {
      sanitized = sanitized.substring(1).trim();
    }
    if (sanitized.contains('-') || sanitized.contains('+')) {
      throw FormatException('Cannot parse VND amount from: "$input"');
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

    throw FormatException('Cannot parse VND amount from: "$input"');
  }
  ```
  Lines 85–87 guarantee that malformed strings with multiple or embedded signs throw `FormatException`. Lines 97–112 handle numerical overflow exceeding `±9_000_000_000_000_000` via both `int.tryParse` (covering 64-bit int boundaries up to `9223372036854775807`) and `BigInt.tryParse` (covering arbitrary-precision magnitudes exceeding 64-bit integers), throwing `const VndOverflowException(...)`.

### 1.2 Execution of Existing Test Suites
- **Adversarial Test Suite (`test/unit/vnd_money_adversarial_test.dart`)**:
  - Command: `& "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_adversarial_test.dart`
  - Verbatim Output:
    ```text
    00:00 +28: All tests passed!
    ```
- **Unit Test Suite (`test/unit/vnd_money_test.dart`)**:
  - Command: `& "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_test.dart`
  - Verbatim Output:
    ```text
    00:00 +33: All tests passed!
    ```

### 1.3 Extended Adversarial Stress Suite Execution
We augmented `test/unit/vnd_money_adversarial_test.dart` with 4 comprehensive stress-test groups targeting edge cases designed to break the parser:
1. **Embedded, trailing, and multi-sign permutations (42 adversarial inputs)**:
   - Inputs: `---1000`, `+++1000`, `+-+1000`, `-+-1000`, `+ + 1000`, `- + 1000`, `+ - 1000`, `- - - 1000`, `-    +    1000`, ` - - 1000 ₫ `, ` + - 1000 ₫ `, `1000-`, `1000+`, `1000- ₫`, `1000+ ₫`, `1.000 ₫ -`, `1.000 ₫ +`, `12-34`, `12+34`, `1.250-000`, `1.250+000`, `-1.000-000`, `+1.000+000`, `-1.000+000`, `+1.000-000`, `+1000-`, `-1000+`, `+1000+`, `-1000-`, `-₫`, `+₫`, `₫-`, `₫+`, `-VND`, `+VND`, `VND-`, `VND+`, `-1000-₫`, `+1000+₫`, `++0`, `--0`, `+-0`, `-+0`.
   - Result: All return `null` in `tryParse` and throw `FormatException` in `parse()`.
2. **Comprehensive overflow spectra across 64-bit and BigInt domains (19 boundary inputs)**:
   - Inputs: `9.000.000.000.000.001 ₫`, `+9.000.000.000.000.001 ₫`, `-9.000.000.000.000.001 ₫`, `9000000000000001`, `+9000000000000001`, `-9000000000000001`, `9223372036854775807 ₫` (int64 max), `+9223372036854775807 ₫`, `-9223372036854775808 ₫` (int64 min), `-9223372036854775808`, `9223372036854775808` (2^63), `+9223372036854775808`, `-9223372036854775809`, `100000000000000000000` (10^20), `-100000000000000000000`, `+999999999999999999999999999999 ₫`, `-999999999999999999999999999999 ₫`, `0009000000000000001 ₫`, `-0009000000000000001 ₫`.
   - Result: All return `null` in `tryParse` and throw `VndOverflowException` in `parse()`.
3. **Strict syntax vs overflow discrimination (7 malformed large inputs)**:
   - Inputs: `--9000000000000001`, `++9000000000000001`, `+-9000000000000001`, `9000000000000001-₫`, `9000000000000001-2`, `abc9000000000000001`, `9000000000000001xyz`.
   - Result: All return `null` in `tryParse` and throw `FormatException` in `parse()`, verifying that syntax errors take precedence over overflow detection.
4. **Boundary and zero variations (16 valid inputs)**:
   - Inputs: `9.000.000.000.000.000 ₫`, `+9.000.000.000.000.000 ₫`, `-9.000.000.000.000.000 ₫`, `9000000000000000`, `-9000000000000000`, `0 ₫`, `+0 ₫`, `-0 ₫`, `+0`, `-0`, `00000 ₫`, `+00000 ₫`, `-00000 ₫`, `00001000 ₫`, `+00001000 ₫`, `-00001000 ₫`.
   - Result: All parse accurately to their exact integer values without throwing.

Execution of the expanded adversarial suite:
- Command: `& "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_adversarial_test.dart`
- Verbatim Output:
  ```text
  00:00 +33: All tests passed!
  ```

### 1.4 Quality Gate Verification Results
- **Full Project Test Suite**:
  - Command: `& "C:\Users\coihu12\flutter\bin\flutter.bat" test`
  - Output: `00:00 +124: All tests passed!` (100% pass across all unit, database, and schema tests).
- **Format Compliance Check**:
  - Command: `& "C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe" format --output=none --set-exit-if-changed .`
  - Output: `Formatted 8 files (0 changed) in 0.81 seconds.` (Exit code 0).
- **Static Analysis Gate**:
  - Command: `& "C:\Users\coihu12\flutter\bin\flutter.bat" analyze`
  - Output: `No issues found! (ran in 9.9s)` (Exit code 0).

---

## 2. Logic Chain

1. **Resolution of BUG-M1-01 (Multiple/Embedded Signs Parsing)**:
   - *Observation*: Input strings with multiple or embedded signs (e.g., `'--1000'`, `'+-1000'`, `'12-34'`, `'1000-'`) previously had the first sign stripped and remainder parsed by `int.tryParse`, inadvertently converting `--1000` to positive `1000`.
   - *Logic*: In `vnd_formatter.dart`, immediately after extracting at most one leading sign character (`-` or `+`), `sanitized.contains('-') || sanitized.contains('+')` evaluates whether any subsequent sign exists anywhere in the string. If true, `tryParse` returns `null` and `parse()` raises `FormatException`.
   - *Empirical Proof*: Tested across 42 distinct permutations of consecutive, embedded, trailing, spaced, and symbol-adjacent signs. 100% returned `null` and threw `FormatException`.

2. **Resolution of BUG-M1-02 (Overflow Exception Contract)**:
   - *Observation*: The docstring for `parse()` specifies `Throws [VndOverflowException] if the parsed amount exceeds [VndMoney.maxSafeVnd]`. Previously, `parse()` only threw `FormatException`.
   - *Logic*: In `parse()`, when `tryParse()` returns `null`, the input is validated for syntactic soundness (no invalid embedded signs). Then the magnitude is parsed via `int.tryParse` and `BigInt.tryParse`. Any magnitude exceeding `VndMoney.maxSafeVnd` (`9_000_000_000_000_000`) throws `const VndOverflowException(...)`.
   - *Empirical Proof*: Tested across 19 overflow scenarios covering 1-VND boundary overflows (`±9_000_000_000_000_001 ₫`), 64-bit int extremes (`9223372036854775807`, `-9223372036854775808`), and arbitrary-precision BigInt values (`10^20`, `10^30`). In every case, `VndOverflowException` was thrown.
   - *Contract Boundary*: Tested malformed strings containing large numbers (e.g., `'--9000000000000001'`, `'abc9000000000000001'`). Because syntactic validation precedes overflow checks, these correctly throw `FormatException` instead of `VndOverflowException`.

3. **Regression Invariance**:
   - Running the entire test suite (`flutter test`) verified all 124 tests pass without regression across database DAOs, schema constraints, VndMoney arithmetic, and formatting.

---

## 3. Caveats

- **No caveats.** The fix introduces zero external dependencies, relies purely on native Dart string manipulation, 64-bit integer arithmetic, and standard `BigInt`, adhering strictly to clean architecture and zero-network offline invariants.

---

## 4. Conclusion

**Verdict: APPROVE**

- **BUG-M1-01** (multiple/embedded signs parsing) is completely and robustly resolved.
- **BUG-M1-02** (overflow exception contract) is completely and accurately resolved across 64-bit and BigInt integer ranges.
- Zero regressions were introduced across the codebase.
- All code formatting and static analysis quality gates exit cleanly with code 0.

---

## 5. Verification Method

To independently verify this evaluation, run the following commands:

1. **Verify Adversarial Stress Suite**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_adversarial_test.dart
   ```
   *Expected output*: `00:00 +33: All tests passed!`

2. **Verify Baseline Unit Test Suite**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/unit/vnd_money_test.dart
   ```
   *Expected output*: `00:00 +33: All tests passed!`

3. **Verify Complete Project Test Suite**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test
   ```
   *Expected output*: `00:00 +124: All tests passed!`

4. **Verify Static Analysis**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" analyze
   ```
   *Expected output*: `No issues found!`

5. **Verify Formatting Compliance**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe" format --output=none --set-exit-if-changed .
   ```
   *Expected output*: `Formatted 8 files (0 changed)` with exit code 0.
