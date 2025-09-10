import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';

/// Groups check-ins that are within 10 minutes of each other
class CheckInGrouping {
  static const int _groupingThresholdMinutes = 10;

  /// Groups check-ins by time proximity
  /// Check-ins within 10 minutes of each other are grouped together
  static List<CheckInGroup> groupCheckIns(
    List<CheckIn> checkIns,
    int totalMetricsCount,
  ) {
    if (checkIns.isEmpty) return [];

    final sortedCheckIns = List<CheckIn>.from(checkIns)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final groups = <CheckInGroup>[];
    CheckInGroup? currentGroup;

    for (final checkIn in sortedCheckIns) {
      if (currentGroup == null) {
        currentGroup = CheckInGroup(
          checkIns: [checkIn],
          totalMetricsCount: totalMetricsCount,
        );
      } else {
        final timeDifference = currentGroup.representativeCheckIn.dateTime
            .difference(checkIn.dateTime)
            .inMinutes
            .abs();

        if (timeDifference <= _groupingThresholdMinutes) {
          currentGroup.checkIns.add(checkIn);
        } else {
          groups.add(currentGroup);
          currentGroup = CheckInGroup(
            checkIns: [checkIn],
            totalMetricsCount: totalMetricsCount,
          );
        }
      }
    }

    if (currentGroup != null) {
      groups.add(currentGroup);
    }

    return groups;
  }
}

/// Represents a group of check-ins that occurred within the same time period
class CheckInGroup {
  final List<CheckIn> checkIns;
  final int totalMetricsCount;

  CheckInGroup({required this.checkIns, required this.totalMetricsCount}) {
    checkIns.sort((a, b) => a.metricName.compareTo(b.metricName));
  }

  /// Returns the representative check-in for this group (newest one)
  CheckIn get representativeCheckIn => checkIns.first;

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

  /// Returns the proportion of available metrics that are included in this group
  double get metricProportion {
    final uniqueMetricsInGroup = uniqueMetrics.length;
    if (totalMetricsCount == 0) return 0.0;
    return uniqueMetricsInGroup / totalMetricsCount;
  }

  /// Returns a color based on the proportion of metrics in this group
  /// More metrics = greener, fewer metrics = redder
  Color get proportionColor {
    final proportion = metricProportion;

    if (proportion >= 0.8) {
      return CupertinoColors.systemGreen;
    } else if (proportion >= 0.6) {
      return CupertinoColors.systemYellow;
    } else if (proportion >= 0.4) {
      return CupertinoColors.systemOrange;
    } else {
      return CupertinoColors.systemRed;
    }
  }
}
