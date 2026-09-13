import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/utils/rating_color.dart';

extension CheckInMetricAppearance on CheckInMetric {
  Color get color => Color(colorValue);

  IconData get icon {
    try {
      return IconData(
        iconCodePoint, // ignore: non_const_argument_for_const_parameter
        fontFamily: 'MaterialIcons',
      );
    } catch (_) {
      return Icons.circle_outlined;
    }
  }
}

extension MetricTypeAppearance on MetricType {
  Color improvementColor(int rating) => switch (this) {
    MetricType.lowerIsBetter => RatingColor.lowerIsBetter(rating),
    MetricType.middleIsBest => RatingColor.middleIsBest(rating),
    MetricType.higherIsBetter => RatingColor.higherIsBetter(rating),
  };
}

abstract final class MetricColorPalette() {
  static const List<Color> colors = [
    EColors.accent,
    EColors.accentGlow,
    EColors.success,
    EColors.warning,
    EColors.success,
    EColors.warning,
    EColors.danger,
    Color(0xFFAF52DE),
    Color(0xFF5AC8FA),
    Color(0xFF5856D6),
    Color(0xFFFF2D55),
    Color(0xFFA2845E),
    EColors.textMuted,
  ];
}

abstract final class MetricIconPalette() {
  static const List<IconData> icons = [
    Icons.favorite_border,
    Icons.water_drop,
    Icons.circle,
    Icons.bolt,
    Icons.favorite,
    Icons.bed,
    Icons.report,
    Icons.shopping_cart,
    Icons.visibility,
    Icons.star,
    Icons.local_fire_department,
    Icons.cloud,
    Icons.wb_sunny,
    Icons.nightlight_round,
    Icons.air,
    Icons.thermostat,
  ];
}
