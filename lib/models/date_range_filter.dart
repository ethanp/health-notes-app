import 'package:ethan_utils/ethan_utils.dart';

/// Date range filter options for trends data
enum DateRangeFilter({
  required final String label,

  /// Days before now for the filter window; null means no cutoff.
  required final int? lookbackDays,
}) {
  fourteenDays(label: '14 Days', lookbackDays: 14),
  sixtyDays(label: '60 Days', lookbackDays: 60),
  allTime(label: 'All Time', lookbackDays: null);

  /// Cutoff DateTime for filtering data. Null for [allTime].
  DateTime? getCutoffDate() {
    final days = lookbackDays;
    if (days == null) return null;
    return DateTime.now().shiftedByDays(-days);
  }

  /// Whether [date] is within this date range.
  bool includesDate(DateTime date) {
    final cutoff = getCutoffDate();
    return cutoff == null || date.isAfter(cutoff);
  }
}
