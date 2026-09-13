import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_in_metric.freezed.dart';
part 'check_in_metric.g.dart';

@freezed
abstract class CheckInMetric with _$CheckInMetric {
  const factory CheckInMetric({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    required MetricType type,
    @JsonKey(name: 'color_value') required int colorValue,
    @JsonKey(name: 'icon_code_point') required int iconCodePoint,
    @JsonKey(name: 'sort_order') required int sortOrder,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _CheckInMetric;

  const CheckInMetric._();

  factory CheckInMetric.fromJson(Map<String, dynamic> json) =>
      _$CheckInMetricFromJson(json);

  factory CheckInMetric.create({
    required String userId,
    required String name,
    required MetricType type,
    int colorValue = 0xFF6B73FF,
    int iconCodePoint = 0xef53,
    int? sortOrder,
  }) {
    return CheckInMetric(
      id: '',
      userId: userId,
      name: name,
      type: type,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      sortOrder: sortOrder ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isValid => name.isNotEmpty && name.trim().isNotEmpty;

  CheckInMetric withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }
}

enum MetricType({
  required final String description,
  required final String valuePreferenceTitle,
}) {
  lowerIsBetter(
    description: 'Lower values are better',
    valuePreferenceTitle: 'Lower is Better',
  ),
  middleIsBest(
    description: 'Middle values (4-7) are optimal',
    valuePreferenceTitle: 'Middle is Best',
  ),
  higherIsBetter(
    description: 'Higher values are better',
    valuePreferenceTitle: 'Higher is Better',
  ),
}
