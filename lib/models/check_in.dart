import 'package:freezed_annotation/freezed_annotation.dart';

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
}

extension CheckInExtensions on CheckIn {
  bool get isValid => rating >= 1 && rating <= 10 && metricName.isNotEmpty;

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

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'metric_name': metricName,
      'rating': rating,
      'date_time': dateTime.toIso8601String(),
    };
  }
}
