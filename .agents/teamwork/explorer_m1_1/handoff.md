# Handoff Report — Scaffolding & Core Money Architecture (Milestone M1)

**Agent**: `explorer_m1_1`  
**Role**: Scaffolding & Core Architecture Explorer  
**Milestone**: M1 (Scaffold & Drift Database Schema)  
**Target Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_1\handoff.md`  
**Authoritative References**:  
- `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (R1, R2, Acceptance Criteria)
- `c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md` (§1, §2, §3, §4.1, §8)
- `c:\Users\coihu12\Documents\App\AGENTS.md` (§1.1, §1.2, §3, §4, §5)
- `c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md` (§Architecture, §Features 5-8, §Interface Contracts)

---

## 1. Observation

### 1.1 Host Environment & Toolchain State
When executing toolchain commands from `c:\Users\coihu12\Documents\App`:
```powershell
flutter --version
dart --version
```
**Verbatim Output**:
```text
flutter : The term 'flutter' is not recognized as the name of a cmdlet, function, script file, or operable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
    + CategoryInfo          : ObjectNotFound: (flutter:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```
A recursive search across drive `C:\` up to depth 4 for `flutter.bat` returned no matches. This corroborates the toolchain audit from `explorer_survey_3/handoff.md` showing that Flutter and Dart are not currently present in the system `PATH` of this workstation.

### 1.2 Existing Workspace Inventory
The current workspace directory `c:\Users\coihu12\Documents\App` contains pre-existing critical files and directories that must not be deleted, overwritten, or clobbered:
- `.agents/` (agent metadata, plans, progress, and handoffs)
- `build_spec/dongtien_build_spec.md` (29,032 bytes authoritative build specification)
- `docs/` (`ARCHITECTURE_AND_RULES.md`, `DESIGN_AND_TEST_PLAN.md`, `design_refs/` containing 9 PNG reference assets)
- `AGENTS.md` (authoritative system invariants and locked dependency whitelist)
- `test_m0_financial_math.py`, `test_m0_security_crypto.py` (M0 invariant verification scripts)

### 1.3 Authoritative Project Identity & Package Names
From `AGENTS.md` (lines 4-5) and `build_spec/dongtien_build_spec.md` (§0, §1):
- Application name: **Đồng Tiền**
- Package name: `dongtien`
- Application ID / Namespace: `vn.dongtien`
- Target platform: `Android` (offline-first, single user, Material 3, `vi_VN` locale)

### 1.4 Authoritative Dependency & Architecture Mandates
From `AGENTS.md` §1.2, §4.1, §4.2:
- **Zero Floating-Point Currency**: Monetary amounts must NEVER be stored, calculated, or passed as `double` or `float`.
- **Underlying Representation**: 64-bit signed integers (`int` in Dart) representing whole Vietnamese Dong (`VND`) with 0 decimal places.
- **Overflow Guard**: `max_Safe_VND = 9_000_000_000_000_000` (9 quadrillion VND). Any amount exceeding this threshold throws `VndOverflowException`.
- **Formatting**: Thousands grouped by dot (`.`), followed by space and `₫` symbol (e.g. `1.250.000 ₫`, `0 ₫`, `-500.000 ₫`). Text widgets displaying currency must specify `fontFeatures: [FontFeature.tabularFigures()]`.
- **Locked Dependencies Whitelist**: `flutter_riverpod: ^2.5.1`, `drift: ^2.20.0`, `drift_flutter: ^0.2.0`, `sqlite3_flutter_libs: ^0.5.24`, `path_provider: ^2.1.4`, `path: ^1.9.0`, `flutter_local_notifications: ^17.2.3`, `timezone: ^0.9.4`, `flutter_timezone: ^3.0.1`, `intl: ^0.19.0`, `share_plus: ^10.0.0`, `file_picker: ^8.1.0`, `cryptography: ^2.7.0`. Dev: `flutter_test`, `integration_test`, `flutter_lints: ^4.0.0`, `build_runner: ^2.4.12`, `drift_dev: ^2.20.0`.
- **Forbidden Packages**: `uuid`, `fl_chart`, `go_router`, `freezed`, `dio`/`http`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`.

---

## 2. Logic Chain

### 2.1 Project Scaffolding & Non-Clobbering Strategy
1. **Observation 1.2 & 1.3**: The working directory is `c:\Users\coihu12\Documents\App`. If standard `flutter create .` were executed without flags, Flutter would default the package name to `app` rather than `dongtien`, which violates the `package:dongtien/...` import structure.
2. **Observation 1.2**: Directories `build_spec/`, `docs/`, and `.agents/` exist in `c:\Users\coihu12\Documents\App`. Flutter's `create` tool in an existing directory does not delete existing subdirectories, but will generate template `pubspec.yaml`, `analysis_options.yaml`, `README.md`, and `lib/main.dart`.
3. **Deduction**: The exact CLI command to scaffold the project must be:
   ```bash
   flutter create --project-name dongtien --org vn.dongtien --platforms android .
   ```
4. **Fallback / Offline Scaffold Strategy**: If the CLI tool is not available in the active terminal environment, all files can be created directly in their canonical directory layout. Specifically:
   - `pubspec.yaml` with the locked dependencies.
   - `analysis_options.yaml` with strict linter rules.
   - `lib/core/money/vnd_money.dart` and `lib/core/money/vnd_formatter.dart`.
   - `test/unit/vnd_money_test.dart`.
   - `android/` configuration (with `allowBackup="false"`, `data_extraction_rules.xml`, and no exact alarm permissions).

### 2.2 Pubspec Lockdown & Forbidden Dependency Elimination
1. **Observation 1.4**: All 8 forbidden packages (`uuid`, `fl_chart`, `go_router`, `freezed`, `dio`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`) are strictly prohibited to prevent build failures, breaking changes, and privacy leaks.
2. **Deduction**: The `pubspec.yaml` must include exclusively the 13 approved runtime packages and 5 approved dev packages from `AGENTS.md` §4.1.

### 2.3 Analysis Options & Tabular Numerals Enforcement
1. **Observation 1.4**: `AGENTS.md` §1.2 & §5.3 mandates `fontFeatures: [FontFeature.tabularFigures()]` on all widgets displaying money, dates, or percentages.
2. **Deduction**: `analysis_options.yaml` should enable strict type checks (`strict-casts`, `strict-inference`, `strict-raw-types`), exclude generated Drift files (`**/*.g.dart`), and enforce clean code practices. A reusable helper `VndFormatter.withTabularFigures()` must be provided in `lib/core/money/vnd_formatter.dart` to make adherence trivial for feature engineers.

### 2.4 VndMoney Value Object & Arithmetic Safety
1. **Observation 1.4**: Monetary values represent whole Vietnamese Dong as 64-bit integers (`int`).
2. **Observation 1.4 & Scenario 12**: Safe-to-Spend can be negative (e.g. `-1.500.000 ₫`), and net expenses can be negative ("Thu hồi chi phí ròng"). Thus, `VndMoney` must support both positive and negative values.
3. **Observation 1.4 & Acceptance Criteria**: Transaction creation commands require strictly positive amounts (`amount > 0`). Thus, `VndMoney.positive(amount)` must be provided. Account balances require non-negative values, supported by `VndMoney.nonNegative(amount)`.
4. **Observation 1.4**: Overflow guard `max_Safe_VND = 9_000_000_000_000_000` must be enforced across all constructors, additions, subtractions, and multiplications. A dedicated `VndOverflowException` must be thrown upon boundary violation.

### 2.5 VndFormatter Specification
1. **Observation 1.4**: Vietnamese currency uses dot (`.`) grouping and ` ₫` suffix.
2. **Deduction**: Formatting can be implemented deterministically using regular expressions on integer strings without floating-point conversion, guaranteeing zero rounding errors or locale bundle initialization delays.

---

## 3. Caveats

1. **Host CLI Availability**: As observed in §1.1, the `flutter` and `dart` commands are not currently reachable in PATH in the active terminal session. If Flutter is installed in a non-standard location or needs to be provisioned via `winget`, the full path or environment variable update will be needed. However, all source files, configurations, and test files can be authored and verified immediately.
2. **Web / Desktop Platforms**: Per build specification §2, only the `android` platform is targeted. Scaffolding with `--platforms android` ensures desktop and web boilerplate are omitted.
3. **Drift Generated Code**: Drift table classes will require `app_database.g.dart` generated by `build_runner`. `analysis_options.yaml` is configured with `analyzer.exclude: ["**/*.g.dart"]` so that static analysis remains clean before and during code generation.

---

## 4. Conclusion & Implementation Artifacts

The core architecture, scaffolding strategy, locked dependencies, static analysis rules, monetary value object, currency formatter, and unit test specifications are finalized and ready for immediate implementation by `worker_m1_1`.

### 4.1 Scaffolding Execution Plan
When executing Flutter scaffolding:
```powershell
flutter create --project-name dongtien --org vn.dongtien --platforms android .
```
Ensure that existing files in `docs/`, `build_spec/`, and `.agents/` remain intact.

---

### 4.2 Exact Content: `pubspec.yaml`
Target file: `c:\Users\coihu12\Documents\App\pubspec.yaml`

```yaml
name: dongtien
description: "DongTien - Production-ready, offline-first personal finance application for Android."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management (Standard Notifier / AsyncNotifier)
  flutter_riverpod: ^2.5.1

  # Persistence & Type-safe SQLite
  drift: ^2.20.0
  drift_flutter: ^0.2.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

  # Scheduled Local Reminders & Timezone
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
  flutter_timezone: ^3.0.1

  # Localization & Formatting
  intl: ^0.19.0

  # Export & Import File Bridge
  share_plus: ^10.0.0
  file_picker: ^8.1.0

  # Authenticated Cryptography (PBKDF2-HMAC-SHA256, AES-256-GCM)
  cryptography: ^2.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.12
  drift_dev: ^2.20.0

flutter:
  uses-material-design: true
  assets:
    - docs/design_refs/
```

---

### 4.3 Exact Content: `analysis_options.yaml`
Target file: `c:\Users\coihu12\Documents\App\analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    avoid_empty_else: true
    avoid_relative_lib_imports: true
    avoid_shadowing_type_parameters: true
    avoid_types_as_parameter_names: true
    await_only_futures: true
    curly_braces_in_flow_control_structures: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_final_fields: true
    prefer_final_locals: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    prefer_iterable_whereType: true
    prefer_single_quotes: true
    unawaited_futures: true
    unnecessary_const: true
    unnecessary_new: true
    unnecessary_null_aware_assignments: true
    unnecessary_nullable_for_final_variable_declarations: true
    unnecessary_string_interpolations: true
    use_build_context_synchronously: true
    use_key_in_widget_constructors: true
    valid_regexps: true
```

---

### 4.4 Concrete Implementation: `lib/core/money/vnd_money.dart`
Target file: `c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart`

```dart
import 'package:flutter/foundation.dart' show immutable;
import 'vnd_formatter.dart';

/// Exception thrown when a monetary operation or value exceeds the
/// 64-bit safety threshold of 9 quadrillion VND (±9.000.000.000.000.000 ₫).
class VndOverflowException implements Exception {
  final String message;
  const VndOverflowException(this.message);

  @override
  String toString() => 'VndOverflowException: $message';
}

/// Immutable value object representing an amount of Vietnamese Dong (VND).
///
/// In Vietnam, currency is exclusively integer VND with zero decimal fractions
/// (hào/xu are obsolete).
///
/// Under the hood, amounts are stored as 64-bit signed integers ([int] in Dart).
/// To guard against arithmetic overflow and ensure safe JSON serialization
/// within IEEE 754 precision limits, values are constrained to:
/// `maxSafeVnd = 9_000_000_000_000_000` (9 quadrillion VND).
@immutable
class VndMoney implements Comparable<VndMoney> {
  /// Maximum safe VND amount: 9.000.000.000.000.000 ₫ (9 quadrillion VND).
  static const int maxSafeVnd = 9000000000000000;

  /// Minimum safe VND amount: -9.000.000.000.000.000 ₫ (-9 quadrillion VND).
  static const int minSafeVnd = -9000000000000000;

  /// Canonical zero instance.
  static const VndMoney zero = VndMoney._(0);

  /// The raw monetary amount in whole VND.
  final int amount;

  /// Internal constructor with assert check for const contexts.
  const VndMoney._(this.amount)
      : assert(
          amount >= minSafeVnd && amount <= maxSafeVnd,
          'Amount $amount exceeds safe VND range [-$maxSafeVnd, $maxSafeVnd]',
        );

  /// Creates a [VndMoney] instance with overflow boundary validation.
  ///
  /// Throws [VndOverflowException] if `amount.abs() > maxSafeVnd`.
  factory VndMoney(int amount) {
    if (amount > maxSafeVnd || amount < minSafeVnd) {
      throw VndOverflowException(
        'VND amount $amount exceeds max safe limit (±$maxSafeVnd ₫)',
      );
    }
    return VndMoney._(amount);
  }

  /// Creates a strictly positive [VndMoney] instance (> 0 ₫).
  ///
  /// Used for transaction entry commands, category budgets, and scheduled bills.
  /// Throws [ArgumentError] if `amount <= 0`.
  /// Throws [VndOverflowException] if `amount > maxSafeVnd`.
  factory VndMoney.positive(int amount) {
    if (amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Amount must be strictly positive (> 0 ₫)',
      );
    }
    if (amount > maxSafeVnd) {
      throw VndOverflowException(
        'VND amount $amount exceeds max safe limit ($maxSafeVnd ₫)',
      );
    }
    return VndMoney._(amount);
  }

  /// Creates a non-negative [VndMoney] instance (>= 0 ₫).
  ///
  /// Used for account balances, envelope targets, and buffer settings.
  /// Throws [ArgumentError] if `amount < 0`.
  /// Throws [VndOverflowException] if `amount > maxSafeVnd`.
  factory VndMoney.nonNegative(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Amount must be non-negative (>= 0 ₫)',
      );
    }
    if (amount > maxSafeVnd) {
      throw VndOverflowException(
        'VND amount $amount exceeds max safe limit ($maxSafeVnd ₫)',
      );
    }
    return VndMoney._(amount);
  }

  /// Whether the amount is exactly zero.
  bool get isZero => amount == 0;

  /// Whether the amount is strictly positive (> 0).
  bool get isPositive => amount > 0;

  /// Whether the amount is strictly negative (< 0).
  bool get isNegative => amount < 0;

  /// Returns the absolute value as a [VndMoney].
  VndMoney abs() => VndMoney._(amount.abs());

  // ---------------------------------------------------------------------------
  // Arithmetic Operators
  // ---------------------------------------------------------------------------

  /// Adds [other] to this amount.
  ///
  /// Throws [VndOverflowException] if the result exceeds [maxSafeVnd] or drops below [minSafeVnd].
  VndMoney operator +(VndMoney other) {
    final int result = amount + other.amount;
    if (result > maxSafeVnd || result < minSafeVnd) {
      throw VndOverflowException(
        'Addition overflow: $amount + ${other.amount} = $result exceeds safe limit',
      );
    }
    return VndMoney._(result);
  }

  /// Subtracts [other] from this amount.
  ///
  /// Throws [VndOverflowException] if the result exceeds [maxSafeVnd] or drops below [minSafeVnd].
  VndMoney operator -(VndMoney other) {
    final int result = amount - other.amount;
    if (result > maxSafeVnd || result < minSafeVnd) {
      throw VndOverflowException(
        'Subtraction overflow: $amount - ${other.amount} = $result exceeds safe limit',
      );
    }
    return VndMoney._(result);
  }

  /// Negates this monetary amount.
  VndMoney operator -() {
    return VndMoney._(-amount);
  }

  /// Multiplies this amount by an integer [factor].
  ///
  /// Throws [VndOverflowException] on multiplication overflow.
  VndMoney operator *(int factor) {
    if (factor == 0 || amount == 0) {
      return VndMoney.zero;
    }
    if (factor.abs() > maxSafeVnd || (amount.abs() > maxSafeVnd ~/ factor.abs())) {
      throw VndOverflowException(
        'Multiplication overflow: $amount * $factor exceeds safe limit',
      );
    }
    final int result = amount * factor;
    if (result > maxSafeVnd || result < minSafeVnd) {
      throw VndOverflowException(
        'Multiplication overflow: $amount * $factor = $result exceeds safe limit',
      );
    }
    return VndMoney._(result);
  }

  /// Performs integer division (truncating) by [divisor].
  ///
  /// Throws [ArgumentError] if [divisor] is zero.
  VndMoney operator ~/(int divisor) {
    if (divisor == 0) {
      throw ArgumentError.value(divisor, 'divisor', 'Divisor cannot be zero');
    }
    return VndMoney._(amount ~/ divisor);
  }

  // ---------------------------------------------------------------------------
  // Comparison Operators & Comparable
  // ---------------------------------------------------------------------------

  bool operator <(VndMoney other) => amount < other.amount;
  bool operator <=(VndMoney other) => amount <= other.amount;
  bool operator >(VndMoney other) => amount > other.amount;
  bool operator >=(VndMoney other) => amount >= other.amount;

  @override
  int compareTo(VndMoney other) => amount.compareTo(other.amount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VndMoney && other.amount == amount);

  @override
  int get hashCode => amount.hashCode;

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  /// Formats this amount into a Vietnamese currency string (`1.250.000 ₫`).
  ///
  /// If [showSign] is true, prefixes positive amounts with `+`.
  String formatVnd({bool showSign = false}) {
    return VndFormatter.format(amount, showSign: showSign);
  }

  @override
  String toString() => formatVnd();
}
```

---

### 4.5 Concrete Implementation: `lib/core/money/vnd_formatter.dart`
Target file: `c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart`

```dart
import 'dart:ui' show FontFeature;
import 'package:flutter/painting.dart' show TextStyle;
import 'vnd_money.dart';

/// Formatting and parsing utilities for Vietnamese Dong (VND).
///
/// In Vietnam (`vi_VN` locale), currency formatting follows these strict rules:
/// - Whole VND amounts only (zero decimal subdivisions).
/// - Thousands grouped by dot (`.`).
/// - Suffix: Space followed by `₫` symbol (` ₫`).
/// - Examples: `1.250.000 ₫`, `0 ₫`, `-500.000 ₫`, `+20.000.000 ₫`.
/// - UI Typography requirement: Always use [FontFeature.tabularFigures()] on
///   text widgets displaying monetary amounts to prevent layout jitter.
class VndFormatter {
  VndFormatter._();

  /// Canonical font feature list for tabular figures.
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// Helper to attach [FontFeature.tabularFigures()] to any [TextStyle].
  static TextStyle withTabularFigures(TextStyle style) {
    return style.copyWith(
      fontFeatures: [
        ...?style.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
  }

  /// Formats an integer VND [amount] to a standard Vietnamese currency string.
  ///
  /// Example:
  /// - `format(1250000)` -> `"1.250.000 ₫"`
  /// - `format(0)` -> `"0 ₫"`
  /// - `format(-500000)` -> `"-500.000 ₫"`
  /// - `format(1250000, showSign: true)` -> `"+1.250.000 ₫"`
  /// - `format(0, showSign: true)` -> `"0 ₫"`
  static String format(int amount, {bool showSign = false}) {
    if (amount == 0) {
      return '0 ₫';
    }

    final bool isNegative = amount < 0;
    final int absAmount = amount.abs();

    // Group thousands with dots using regex
    final String digits = absAmount.toString();
    final String grouped = digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    if (isNegative) {
      return '-$grouped ₫';
    } else if (showSign) {
      return '+$grouped ₫';
    } else {
      return '$grouped ₫';
    }
  }

  /// Formats a [VndMoney] instance.
  static String formatMoney(VndMoney money, {bool showSign = false}) {
    return format(money.amount, showSign: showSign);
  }

  /// Parses a formatted Vietnamese currency string into an integer whole VND.
  ///
  /// Handles strings such as `"1.250.000 ₫"`, `"1.250.000"`, `"-500.000 ₫"`,
  /// `"+20.000.000 ₫"`, `"1250000"`.
  ///
  /// Throws [FormatException] if the input cannot be parsed.
  /// Throws [VndOverflowException] if the parsed amount exceeds [VndMoney.maxSafeVnd].
  static int parse(String input) {
    final int? result = tryParse(input);
    if (result == null) {
      throw FormatException('Cannot parse VND amount from: "$input"');
    }
    return result;
  }

  /// Attempts to parse a formatted VND string into an integer.
  ///
  /// Returns `null` if the input is invalid or exceeds [VndMoney.maxSafeVnd].
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

    // Remove currency symbol, spaces, non-breaking spaces, and dots
    sanitized = sanitized
        .replaceAll('₫', '')
        .replaceAll('VND', '')
        .replaceAll('vnd', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '');

    if (sanitized.isEmpty) return null;

    final int? parsed = int.tryParse(sanitized);
    if (parsed == null) return null;

    final int finalAmount = isNegative ? -parsed : parsed;

    if (finalAmount > VndMoney.maxSafeVnd || finalAmount < VndMoney.minSafeVnd) {
      return null;
    }

    return finalAmount;
  }

  /// Attempts to parse a formatted VND string directly into a [VndMoney] instance.
  static VndMoney? tryParseMoney(String input) {
    final int? amount = tryParse(input);
    if (amount == null) return null;
    return VndMoney(amount);
  }
}
```

---

### 4.6 Concrete Implementation: `test/unit/vnd_money_test.dart`
Target file: `c:\Users\coihu12\Documents\App\test\unit\vnd_money_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/core/money/vnd_formatter.dart';

void main() {
  group('VndMoney Value Object', () {
    test('Constructs valid VND amounts within safe bounds', () {
      final zero = VndMoney(0);
      expect(zero.amount, 0);
      expect(zero.isZero, isTrue);
      expect(zero.isPositive, isFalse);
      expect(zero.isNegative, isFalse);

      final tenMillion = VndMoney(10000000);
      expect(tenMillion.amount, 10000000);
      expect(tenMillion.isPositive, isTrue);

      final deficit = VndMoney(-500000);
      expect(deficit.amount, -500000);
      expect(deficit.isNegative, isTrue);
    });

    test('Canonical zero constant is identical and equals VndMoney(0)', () {
      expect(VndMoney.zero.amount, 0);
      expect(VndMoney(0), equals(VndMoney.zero));
    });

    test('positive factory enforces amount > 0', () {
      expect(VndMoney.positive(1).amount, 1);
      expect(() => VndMoney.positive(0), throwsArgumentError);
      expect(() => VndMoney.positive(-100), throwsArgumentError);
    });

    test('nonNegative factory enforces amount >= 0', () {
      expect(VndMoney.nonNegative(0).amount, 0);
      expect(VndMoney.nonNegative(50000).amount, 50000);
      expect(() => VndMoney.nonNegative(-1), throwsArgumentError);
    });

    group('64-Bit Overflow Guard (maxSafeVnd = 9_000_000_000_000_000)', () {
      test('Allows boundary values ±9 quadrillion VND', () {
        final maxVnd = VndMoney(VndMoney.maxSafeVnd);
        expect(maxVnd.amount, 9000000000000000);

        final minVnd = VndMoney(VndMoney.minSafeVnd);
        expect(minVnd.amount, -9000000000000000);
      });

      test('Rejects values exceeding maxSafeVnd', () {
        expect(
          () => VndMoney(VndMoney.maxSafeVnd + 1),
          throwsA(isA<VndOverflowException>()),
        );
        expect(
          () => VndMoney(VndMoney.minSafeVnd - 1),
          throwsA(isA<VndOverflowException>()),
        );
        expect(
          () => VndMoney.positive(VndMoney.maxSafeVnd + 1),
          throwsA(isA<VndOverflowException>()),
        );
        expect(
          () => VndMoney.nonNegative(VndMoney.maxSafeVnd + 1),
          throwsA(isA<VndOverflowException>()),
        );
      });
    });

    group('Arithmetic Operations', () {
      test('Addition (+) adds amounts correctly', () {
        final a = VndMoney(10000000);
        final b = VndMoney(20000000);
        final result = a + b;
        expect(result.amount, 30000000);
      });

      test('Addition with negative amount (net deficit)', () {
        final a = VndMoney(10000000);
        final b = VndMoney(-3000000);
        expect((a + b).amount, 7000000);
      });

      test('Addition throws VndOverflowException on boundary overflow', () {
        final max = VndMoney(VndMoney.maxSafeVnd);
        expect(() => max + VndMoney(1), throwsA(isA<VndOverflowException>()));

        final min = VndMoney(VndMoney.minSafeVnd);
        expect(() => min + VndMoney(-1), throwsA(isA<VndOverflowException>()));
      });

      test('Subtraction (-) subtracts amounts correctly', () {
        final a = VndMoney(29900000);
        final b = VndMoney(100000);
        expect((a - b).amount, 29800000);
      });

      test('Subtraction yielding negative shortfall', () {
        final a = VndMoney(500000);
        final b = VndMoney(1500000);
        final result = a - b;
        expect(result.amount, -1000000);
        expect(result.isNegative, isTrue);
      });

      test('Subtraction throws VndOverflowException on underflow', () {
        final min = VndMoney(VndMoney.minSafeVnd);
        expect(() => min - VndMoney(1), throwsA(isA<VndOverflowException>()));
      });

      test('Unary negation (-)', () {
        expect((-VndMoney(500000)).amount, -500000);
        expect((-VndMoney(-500000)).amount, 500000);
        expect((-VndMoney(0)).amount, 0);
      });

      test('Multiplication (*) scales amounts correctly', () {
        final a = VndMoney(2500000);
        expect((a * 3).amount, 7500000);
        expect((a * 0).amount, 0);
        expect((a * -1).amount, -2500000);
      });

      test('Multiplication throws VndOverflowException when exceeding safe threshold', () {
        final huge = VndMoney(5000000000000000);
        expect(() => huge * 2, throwsA(isA<VndOverflowException>()));
      });

      test('Integer division (~/) truncates division correctly', () {
        final total = VndMoney(10000000);
        expect((total ~/ 3).amount, 3333333);
      });

      test('Integer division by zero throws ArgumentError', () {
        expect(() => VndMoney(10000000) ~/ 0, throwsArgumentError);
      });

      test('abs() returns absolute magnitude', () {
        expect(VndMoney(-500000).abs().amount, 500000);
        expect(VndMoney(500000).abs().amount, 500000);
        expect(VndMoney(0).abs().amount, 0);
      });
    });

    group('Comparison, Equality & Set Hashing', () {
      test('Relational operators (<, <=, >, >=)', () {
        final a = VndMoney(100000);
        final b = VndMoney(200000);
        final c = VndMoney(100000);

        expect(a < b, isTrue);
        expect(a <= b, isTrue);
        expect(a <= c, isTrue);
        expect(b > a, isTrue);
        expect(b >= a, isTrue);
        expect(a >= c, isTrue);
      });

      test('Equality and hashCode consistency', () {
        final m1 = VndMoney(500000);
        final m2 = VndMoney(500000);
        final m3 = VndMoney(600000);

        expect(m1, equals(m2));
        expect(m1.hashCode, equals(m2.hashCode));
        expect(m1, isNot(equals(m3)));

        final set = {m1, m2, m3};
        expect(set.length, 2);
      });

      test('Comparable interface sorts ascending', () {
        final list = [VndMoney(300), VndMoney(100), VndMoney(-50), VndMoney(200)];
        list.sort();
        expect(list.map((m) => m.amount).toList(), [-50, 100, 200, 300]);
      });
    });
  });

  group('VndFormatter (vi_VN Locale Specification)', () {
    test('Formats zero as 0 ₫', () {
      expect(VndFormatter.format(0), '0 ₫');
      expect(VndFormatter.format(0, showSign: true), '0 ₫');
    });

    test('Formats positive amounts with dot grouping and ₫ suffix', () {
      expect(VndFormatter.format(100), '100 ₫');
      expect(VndFormatter.format(1000), '1.000 ₫');
      expect(VndFormatter.format(1250000), '1.250.000 ₫');
      expect(VndFormatter.format(10000000), '10.000.000 ₫');
      expect(VndFormatter.format(29900000), '29.900.000 ₫');
      expect(VndFormatter.format(9000000000000000), '9.000.000.000.000.000 ₫');
    });

    test('Formats negative amounts with minus sign', () {
      expect(VndFormatter.format(-500000), '-500.000 ₫');
      expect(VndFormatter.format(-1250000), '-1.250.000 ₫');
      expect(VndFormatter.format(-9000000000000000), '-9.000.000.000.000.000 ₫');
    });

    test('Formats with showSign: true displays explicit plus sign on positive numbers', () {
      expect(VndFormatter.format(1250000, showSign: true), '+1.250.000 ₫');
      expect(VndFormatter.format(-500000, showSign: true), '-500.000 ₫');
      expect(VndFormatter.format(0, showSign: true), '0 ₫');
    });

    test('VndMoney.formatVnd() delegates to VndFormatter', () {
      final money = VndMoney(1250000);
      expect(money.formatVnd(), '1.250.000 ₫');
      expect(money.formatVnd(showSign: true), '+1.250.000 ₫');
      expect(money.toString(), '1.250.000 ₫');
    });

    group('Parsing Currency Strings', () {
      test('Parses formatted strings with dots, spaces, and currency symbols', () {
        expect(VndFormatter.parse('1.250.000 ₫'), 1250000);
        expect(VndFormatter.parse('1.250.000'), 1250000);
        expect(VndFormatter.parse('1250000'), 1250000);
        expect(VndFormatter.parse('0 ₫'), 0);
        expect(VndFormatter.parse('-500.000 ₫'), -500000);
        expect(VndFormatter.parse('+20.000.000 ₫'), 20000000);
      });

      test('tryParse returns null on invalid strings or overflow', () {
        expect(VndFormatter.tryParse(''), isNull);
        expect(VndFormatter.tryParse('invalid'), isNull);
        expect(VndFormatter.tryParse('9000000000000001'), isNull);
      });

      test('tryParseMoney returns VndMoney instance', () {
        final parsed = VndFormatter.tryParseMoney('1.250.000 ₫');
        expect(parsed, isNotNull);
        expect(parsed!.amount, 1250000);
      });
    });
  });
}
```

---

## 5. Verification Method

To independently verify this implementation plan and handoff:

1. **Verify `pubspec.yaml` Integrity**:
   Inspect `pubspec.yaml` to ensure all 13 runtime dependencies and 5 dev dependencies are present, with zero forbidden packages.
   ```bash
   grep -E "(uuid|fl_chart|go_router|freezed|dio|firebase|flutter_secure_storage|sqlcipher)" pubspec.yaml
   ```
   *Expected Result*: Exits with code 1 (no matches).

2. **Verify Static Analysis**:
   ```bash
   flutter analyze
   ```
   *Expected Result*: Exits with code 0 (zero errors, zero warnings, zero lints).

3. **Verify VndMoney Unit Tests**:
   ```bash
   flutter test test/unit/vnd_money_test.dart
   ```
   *Expected Result*: 100% of tests pass, verifying:
   - Valid VND bounds and constructors (`positive`, `nonNegative`).
   - Boundary overflow detection at $\pm 9\text{ quadrillion VND}$ throwing `VndOverflowException`.
   - Arithmetic operations ($+$, $-$, $*$, $\sim/$) and negative shortfall handling.
   - Format representation matching `vi_VN` specification (`1.250.000 ₫`, `0 ₫`, `-500.000 ₫`).
   - Two-way parsing of currency strings.

4. **Verify Formatting Compliance**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
   *Expected Result*: Exits with code 0.
