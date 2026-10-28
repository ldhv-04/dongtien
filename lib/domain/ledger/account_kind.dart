/// Classification of ledger accounts in DongTien double-entry general ledger.
///
/// Matches SQLite CHECK constraint on `ledger_accounts(kind)`:
/// `CHECK (kind IN ('ASSET_CASH', 'ASSET_BANK', 'LIABILITY_CREDIT_CARD', 'INCOME', 'EXPENSE', 'EQUITY_OPENING'))`
enum AccountKind {
  assetCash('ASSET_CASH'),
  assetBank('ASSET_BANK'),
  liabilityCreditCard('LIABILITY_CREDIT_CARD'),
  income('INCOME'),
  expense('EXPENSE'),
  equityOpening('EQUITY_OPENING');

  final String dbValue;
  const AccountKind(this.dbValue);

  /// Liquid assets comprise physical cash and bank/e-wallet accounts.
  /// Credit cards are liabilities and strictly NOT liquid.
  bool get isLiquid => this == assetCash || this == assetBank;

  /// Normal balance convention:
  /// - Asset and Expense accounts have a Debit normal balance (debit - credit).
  /// - Liability, Income, and Equity accounts have a Credit normal balance (credit - debit).
  bool get isDebitNormal =>
      this == assetCash || this == assetBank || this == expense;

  /// Whether this account type is credit-normal.
  bool get isCreditNormal =>
      this == liabilityCreditCard || this == income || this == equityOpening;

  /// Parses an [AccountKind] from its database string representation.
  static AccountKind fromDbValue(String value) {
    return AccountKind.values.firstWhere(
      (k) => k.dbValue == value,
      orElse: () => throw ArgumentError('Unknown AccountKind: "$value"'),
    );
  }
}
