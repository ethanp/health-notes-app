import 'package:health_notes/models/check_in.dart';

/// Groups check-ins that are within 10 minutes of each other
class CheckInGrouping {
  static const int _groupingThresholdMinutes = 10;

  /// Groups check-ins by time proximity
  /// Check-ins within 10 minutes of each other are grouped together
  static List<CheckInGroup> groupCheckIns(List<CheckIn> checkIns) {
    if (checkIns.isEmpty) return [];

    // Sort check-ins by date/time (newest first)
    final sortedCheckIns = List<CheckIn>.from(checkIns)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final groups = <CheckInGroup>[];
    CheckInGroup? currentGroup;

    for (final checkIn in sortedCheckIns) {
      if (currentGroup == null) {
        // Start a new group
        currentGroup = CheckInGroup(
          primaryCheckIn: checkIn,
          checkIns: [checkIn],
        );
      } else {
        // Check if this check-in should be added to the current group
        final timeDifference = currentGroup.primaryCheckIn.dateTime
            .difference(checkIn.dateTime)
            .inMinutes
            .abs();

        if (timeDifference <= _groupingThresholdMinutes) {
          // Add to current group
          currentGroup.checkIns.add(checkIn);
          // Update primary check-in if this one is newer
          if (checkIn.dateTime.isAfter(currentGroup.primaryCheckIn.dateTime)) {
            currentGroup = CheckInGroup(
              primaryCheckIn: checkIn,
              checkIns: currentGroup.checkIns,
            );
          }
        } else {
          // Start a new group
          groups.add(currentGroup);
          currentGroup = CheckInGroup(
            primaryCheckIn: checkIn,
            checkIns: [checkIn],
          );
        }
      }
    }

    // Add the last group
    if (currentGroup != null) {
      groups.add(currentGroup);
    }

    return groups;
  }
}

/// Represents a group of check-ins that occurred within the same time period
class CheckInGroup {
  final CheckIn primaryCheckIn;
  final List<CheckIn> checkIns;

  CheckInGroup({required this.primaryCheckIn, required this.checkIns});

  /// Returns true if this group contains multiple check-ins
  bool get isMultiMetric => checkIns.length > 1;

  /// Returns the number of unique metrics in this group
  int get uniqueMetricCount => checkIns.map((c) => c.metricName).toSet().length;

  /// Returns all unique metric names in this group
  Set<String> get uniqueMetrics => checkIns.map((c) => c.metricName).toSet();

  /// Returns the average rating across all check-ins in this group
  double get averageRating {
    if (checkIns.isEmpty) return 0;
    final total = checkIns.fold<int>(0, (sum, checkIn) => sum + checkIn.rating);
    return total / checkIns.length;
  }
}
