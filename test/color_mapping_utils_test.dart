// ignore_for_file: deprecated_member_use

import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/utils/color_mapping_utils.dart';

void main() {
  group('ColorMappingUtils', () {
    test('ratingToColor returns red for rating 1', () {
      final color = ColorMappingUtils.ratingToColor(1);
      // Red should have high red value and low green/blue values
      expect(color.red, greaterThan(200));
      expect(color.green, lessThan(80));
      expect(color.blue, lessThan(80));
    });

    test('ratingToColor returns green for rating 10', () {
      final color = ColorMappingUtils.ratingToColor(10);
      // Green should have high green value and low red/blue values
      expect(color.green, greaterThan(180));
      expect(color.red, lessThan(80));
      expect(color.blue, lessThan(100));
    });

    test('ratingToColor interpolates correctly for middle values', () {
      final color = ColorMappingUtils.ratingToColor(5);
      // Should be a yellow-ish color between red and green
      expect(color.red, greaterThan(100));
      expect(color.green, greaterThan(100));
      expect(color.blue, lessThan(100));
    });

    test('lowerIsBetterColor uses inverted mapping', () {
      final lowColor = ColorMappingUtils.lowerIsBetterColor(1);
      final highColor = ColorMappingUtils.lowerIsBetterColor(10);
      expect(lowColor.green, greaterThan(180)); // 1 = good = green
      expect(highColor.red, greaterThan(200)); // 10 = bad = red
    });

    test('higherIsBetterColor uses direct mapping', () {
      final lowColor = ColorMappingUtils.higherIsBetterColor(1);
      final highColor = ColorMappingUtils.higherIsBetterColor(10);
      expect(lowColor.red, greaterThan(200)); // 1 = bad = red
      expect(highColor.green, greaterThan(180)); // 10 = good = green
    });

    test('middleIsBestColor peaks at middle values', () {
      // Middle value (5) should be greener than extremes
      final middleColor = ColorMappingUtils.middleIsBestColor(5);
      final lowColor = ColorMappingUtils.middleIsBestColor(1);
      final highColor = ColorMappingUtils.middleIsBestColor(10);

      expect(middleColor.green, greaterThan(lowColor.green));
      expect(middleColor.green, greaterThan(highColor.green));
      expect(lowColor.red, greaterThan(middleColor.red));
      expect(highColor.red, greaterThan(middleColor.red));
    });

    test('getBackgroundGradient returns correct colors for each type', () {
      final lowerGradient = ColorMappingUtils.getBackgroundGradient(
        MetricType.lowerIsBetter,
      );
      final higherGradient = ColorMappingUtils.getBackgroundGradient(
        MetricType.higherIsBetter,
      );
      final middleGradient = ColorMappingUtils.getBackgroundGradient(
        MetricType.middleIsBest,
      );

      expect(lowerGradient.length, equals(3));
      expect(higherGradient.length, equals(3));
      expect(middleGradient.length, equals(5));
    });
  });
}
