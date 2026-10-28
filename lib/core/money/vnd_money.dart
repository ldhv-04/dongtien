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
    if (factor.abs() > maxSafeVnd ||
        (amount.abs() > maxSafeVnd ~/ factor.abs())) {
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
