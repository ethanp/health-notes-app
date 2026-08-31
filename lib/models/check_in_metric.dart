import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/utils/rating_color.dart';

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

  /// Create a new CheckInMetric with default values
  factory CheckInMetric.create({
    required String userId,
    required String name,
    required MetricType type,
    Color? color,
    IconData? icon,
    int? sortOrder,
  }) {
    return CheckInMetric(
      id: '', // Will be set by the provider
      userId: userId,
      name: name,
      type: type,
      colorValue: (color ?? EColors.accent).toARGB32(),
      iconCodePoint: (icon ?? CupertinoIcons.circle).codePoint,
      sortOrder: sortOrder ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Returns the color for this metric
  Color get color => Color(colorValue);

  /// Returns the icon for this metric
  IconData get icon {
    try {
      return IconData(
        iconCodePoint, // ignore: non_const_argument_for_const_parameter
        fontFamily: 'CupertinoIcons',
        fontPackage: 'cupertino_icons',
      );
    } catch (_) {
      return CupertinoIcons.circle;
    }
  }

  bool get isValid => name.isNotEmpty && name.trim().isNotEmpty;

  /// Returns a copy with updated timestamp
  CheckInMetric withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }
}

enum MetricType({
  required final String description,
  required final String valuePreferenceTitle,
  required final Color Function(int) improvementColor,
}) {
  lowerIsBetter(
    description: 'Lower values are better',
    valuePreferenceTitle: 'Lower is Better',
    improvementColor: RatingColor.lowerIsBetter,
  ),
  middleIsBest(
    description: 'Middle values (4-7) are optimal',
    valuePreferenceTitle: 'Middle is Best',
    improvementColor: RatingColor.middleIsBest,
  ),
  higherIsBetter(
    description: 'Higher values are better',
    valuePreferenceTitle: 'Higher is Better',
    improvementColor: RatingColor.higherIsBetter,
  ),
}

/// Default color palette for new metrics
class MetricColorPalette {
  static const List<Color> colors = [
    EColors.accent,
    EColors.accentGlow,
    EColors.success,
    EColors.warning,
    EColors.success,
    EColors.warning,
    EColors.danger,
    CupertinoColors.systemPurple,
    CupertinoColors.systemTeal,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemPink,
    CupertinoColors.systemBrown,
    CupertinoColors.systemGrey,
  ];

  static Color getColorByIndex(int index) {
    return colors[index % colors.length];
  }
}

/// Default icon palette for new metrics
class MetricIconPalette {
  static const List<IconData> icons = [
    CupertinoIcons.heart,
    CupertinoIcons.drop,
    CupertinoIcons.circle_fill,
    CupertinoIcons.bolt_fill,
    CupertinoIcons.heart_fill,
    CupertinoIcons.bed_double_fill,
    CupertinoIcons.exclamationmark_octagon,
    CupertinoIcons.cart_fill,
    CupertinoIcons.eye_fill,
    CupertinoIcons.star_fill,
    CupertinoIcons.flame_fill,
    CupertinoIcons.cloud_fill,
    CupertinoIcons.sun_max_fill,
    CupertinoIcons.moon_fill,
    CupertinoIcons.wind,
    CupertinoIcons.thermometer,
  ];

  static IconData getIconByIndex(int index) {
    return icons[index % icons.length];
  }
}
