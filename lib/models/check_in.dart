import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/models/metric.dart';
import 'package:flutter/cupertino.dart';
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

  /// Create a CheckIn with a Metric object
  factory CheckIn.withMetric({
    required String id,
    required Metric metric,
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

  /// Get the Metric object for this check-in
  Metric? get metric => Metric.fromName(metricName);

  /// Get the color for this check-in's metric
  Color get metricColor => metric?.color ?? AppTheme.primary;

  /// Get the icon for this check-in's metric
  IconData get metricIcon => metric?.icon ?? CupertinoIcons.circle;

  /// Get the rating color based on the metric type
  Color get ratingColor =>
      metric?.getRatingColor(rating) ?? CupertinoColors.systemGrey;

  /// Check if the rating is in a good state for this metric
  bool get isRatingInGoodState => metric?.isRatingInGoodState(rating) ?? false;

  CheckIn copyWith({
    String? id,
    String? metricName,
    int? rating,
    DateTime? dateTime,
    DateTime? createdAt,
  }) {
    return CheckIn(
      id: id ?? this.id,
      metricName: metricName ?? this.metricName,
      rating: rating ?? this.rating,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create a copy with a Metric object
  CheckIn copyWithMetric({
    String? id,
    Metric? metric,
    int? rating,
    DateTime? dateTime,
    DateTime? createdAt,
  }) {
    return CheckIn(
      id: id ?? this.id,
      metricName: metric?.name ?? metricName,
      rating: rating ?? this.rating,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'metric_name': metricName,
      'rating': rating,
      'date_time': dateTime.toIso8601String(),
    };
  }
}
