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

    if (sanitized.contains('-') || sanitized.contains('+')) {
      return null;
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

    if (finalAmount > VndMoney.maxSafeVnd ||
        finalAmount < VndMoney.minSafeVnd) {
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
