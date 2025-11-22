/// Date range filter options for trends data
enum DateRangeFilter {
  fourteenDays,
  sixtyDays,
  allTime,
}

extension DateRangeFilterExtension on DateRangeFilter {
  /// Display label for the date range
  String get label {
    switch (this) {
      case DateRangeFilter.fourteenDays:
        return '14 Days';
      case DateRangeFilter.sixtyDays:
        return '60 Days';
      case DateRangeFilter.allTime:
        return 'All Time';
    }
  }

  /// Get the cutoff DateTime for filtering data
  /// Returns null for allTime (no filtering)
  DateTime? getCutoffDate() {
    switch (this) {
      case DateRangeFilter.fourteenDays:
        return DateTime.now().subtract(const Duration(days: 14));
      case DateRangeFilter.sixtyDays:
        return DateTime.now().subtract(const Duration(days: 60));
      case DateRangeFilter.allTime:
        return null;
    }
  }

  /// Check if a DateTime is within this date range
  bool includesDate(DateTime date) {
    final cutoff = getCutoffDate();
    return cutoff == null || date.isAfter(cutoff);
  }
}
