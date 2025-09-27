import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/theme/app_theme.dart';

part 'check_in.freezed.dart';
part 'check_in.g.dart';

@freezed
abstract class CheckIn with _$CheckIn {
  const factory CheckIn({
    required String id,
    @JsonKey(name: 'metric_name') required String metricName,
    @JsonKey(name: 'rating') required int rating,
    @JsonKey(name: 'date_time') required DateTime dateTime,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _CheckIn;

  factory CheckIn.fromJson(Map<String, dynamic> json) =>
      _$CheckInFromJson(json);

  /// Create a CheckIn with a CheckInMetric object
  factory CheckIn.withCheckInMetric({
    required String id,
    required CheckInMetric metric,
    required int rating,
    required DateTime dateTime,
    required DateTime createdAt,
  }) {
    return CheckIn(
      id: id,
      metricName: metric.name,
      rating: rating,
      dateTime: dateTime,
      createdAt: createdAt,
    );
  }
}

extension CheckInExtensions on CheckIn {
  bool get isValid => rating >= 1 && rating <= 10 && metricName.isNotEmpty;

  /// Get the color for this check-in's metric (requires CheckInMetric to be passed)
  Color getMetricColor(CheckInMetric? metric) =>
      metric?.color ?? AppColors.primary;

  /// Get the icon for this check-in's metric (requires CheckInMetric to be passed)
  IconData getMetricIcon(CheckInMetric? metric) =>
      metric?.icon ?? CupertinoIcons.circle;

  /// Get the rating color based on the metric type (requires CheckInMetric to be passed)
  Color getRatingColor(CheckInMetric? metric) =>
      metric?.getRatingColor(rating) ?? CupertinoColors.systemGrey;

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'metric_name': metricName,
      'rating': rating,
      'date_time': dateTime.toIso8601String(),
    };
  }
}
