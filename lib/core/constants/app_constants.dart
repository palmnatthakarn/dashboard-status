/// App-wide business & API constants.
/// ⚠️  Adjust threshold values here — changes take effect across the entire app.
class AppConstants {
  AppConstants._();

  // ─────────────────────────────────────────────────────────────────────────
  // Dashboard status thresholds  (income / deposit amounts in THB)
  // ─────────────────────────────────────────────────────────────────────────

  /// Shops with income BELOW this value are classified as "safe".
  static const double safeIncomeMax = 1000000;

  /// Shops with income in [warningIncomeMin, warningIncomeMax] → "warning".
  static const double warningIncomeMin = 1000000;
  static const double warningIncomeMax = 1800000;

  /// Shops with income ABOVE this value are classified as "exceeded".
  static const double exceededIncomeMin = 1800000;

  /// Deposit threshold used for stats counters (success / warning / error).
  static const double successDepositThreshold = 1000000;
  static const double warningDepositMin = 500000;
  static const double warningDepositMax = 1000000;

  // ─────────────────────────────────────────────────────────────────────────
  // API / Pagination
  // ─────────────────────────────────────────────────────────────────────────

  /// Maximum journal records fetched per request.
  /// If total records might exceed this, implement cursor/offset pagination.
  static const int journalPageSize = 1000;
}
