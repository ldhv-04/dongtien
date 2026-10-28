import 'package:dongtien/core/money/vnd_money.dart';
import 'envelope_exceptions.dart';

/// Pure Dart calculator and validator for Available-to-Allocate funds.
///
/// Implements Section 5.1 of `ARCHITECTURE_AND_RULES.md`:
/// `available_to_allocate = total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd`
class AvailableToAllocateCalculator {
  const AvailableToAllocateCalculator._();

  /// Computes the exact Available-to-Allocate amount in integer VND.
  ///
  /// Note: The result can be negative if reserves + buffer exceed liquid assets.
  static int calculate({
    required int totalLiquidAssetsVnd,
    required int totalEnvelopeReservesVnd,
    required int minimumCashBufferVnd,
  }) {
    if (minimumCashBufferVnd < 0) {
      throw ArgumentError.value(
        minimumCashBufferVnd,
        'minimumCashBufferVnd',
        'Minimum cash buffer must be non-negative',
      );
    }
    return totalLiquidAssetsVnd -
        totalEnvelopeReservesVnd -
        minimumCashBufferVnd;
  }

  /// Validates an ALLOCATE command.
  ///
  /// Invariant: `amount_vnd <= max(0, available_to_allocate)`.
  /// Throws [OverAllocationException] if requested allocation exceeds available funds.
  static void validateAllocation({
    required int allocateAmountVnd,
    required int availableToAllocateVnd,
  }) {
    if (allocateAmountVnd <= 0) {
      throw ArgumentError.value(
        allocateAmountVnd,
        'allocateAmountVnd',
        'Allocation amount must be strictly positive (> 0 ₫)',
      );
    }
    if (allocateAmountVnd > VndMoney.maxSafeVnd) {
      throw ArgumentError.value(
        allocateAmountVnd,
        'allocateAmountVnd',
        'Allocation amount exceeds max safe VND limit',
      );
    }

    final int maxAllowed =
        availableToAllocateVnd > 0 ? availableToAllocateVnd : 0;
    if (allocateAmountVnd > maxAllowed) {
      throw OverAllocationException(
        requestedVnd: allocateAmountVnd,
        availableToAllocateVnd: availableToAllocateVnd,
      );
    }
  }

  /// Validates spending from an envelope.
  ///
  /// Throws [SpendingDeficitException] if `spendAmountVnd > reservedBalanceVnd`
  /// and `allowNegativeException` is false.
  static void validateSpending({
    required int spendAmountVnd,
    required int reservedBalanceVnd,
    required bool allowNegativeException,
    required int envelopeId,
  }) {
    if (spendAmountVnd <= 0) {
      throw ArgumentError.value(
        spendAmountVnd,
        'spendAmountVnd',
        'Spend amount must be strictly positive (> 0 ₫)',
      );
    }
    if (spendAmountVnd > VndMoney.maxSafeVnd) {
      throw ArgumentError.value(
        spendAmountVnd,
        'spendAmountVnd',
        'Spend amount exceeds max safe VND limit',
      );
    }

    if (spendAmountVnd > reservedBalanceVnd && !allowNegativeException) {
      throw SpendingDeficitException(
        requestedVnd: spendAmountVnd,
        currentReservedVnd: reservedBalanceVnd,
        envelopeId: envelopeId,
      );
    }
  }

  /// Validates transferring funds between envelopes.
  static void validateTransfer({
    required int fromEnvelopeId,
    required int toEnvelopeId,
    required int amountVnd,
    required int sourceReservedVnd,
    required bool allowNegativeException,
  }) {
    if (fromEnvelopeId == toEnvelopeId) {
      throw const InvalidEnvelopeOperationException(
        'Source and destination envelopes must be distinct',
      );
    }
    if (amountVnd <= 0) {
      throw ArgumentError.value(
        amountVnd,
        'amountVnd',
        'Transfer amount must be strictly positive (> 0 ₫)',
      );
    }
    if (amountVnd > VndMoney.maxSafeVnd) {
      throw ArgumentError.value(
        amountVnd,
        'amountVnd',
        'Transfer amount exceeds max safe VND limit',
      );
    }

    if (amountVnd > sourceReservedVnd && !allowNegativeException) {
      throw SpendingDeficitException(
        requestedVnd: amountVnd,
        currentReservedVnd: sourceReservedVnd,
        envelopeId: fromEnvelopeId,
        message:
            'Transfer amount exceeds source reserved balance and negative exceptions are disabled',
      );
    }
  }
}
