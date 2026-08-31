// ignore_for_file: deprecated_member_use

import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/utils/rating_color.dart';

void main() {
  group('RatingColor', () {
    test('redToGreen returns red for rating 1', () {
      final color = RatingColor.redToGreen(1);
      expect(color.red, greaterThan(200));
      expect(color.green, lessThan(80));
      expect(color.blue, lessThan(80));
    });

    test('redToGreen returns green for rating 10', () {
      final color = RatingColor.redToGreen(10);
      expect(color.green, greaterThan(180));
      expect(color.red, lessThan(80));
      expect(color.blue, lessThan(100));
    });

    test('redToGreen interpolates correctly for middle values', () {
      final color = RatingColor.redToGreen(5);
      expect(color.red, greaterThan(100));
      expect(color.green, greaterThan(100));
      expect(color.blue, lessThan(100));
    });

    test('lowerIsBetter uses inverted mapping', () {
      final lowColor = RatingColor.lowerIsBetter(1);
      final highColor = RatingColor.lowerIsBetter(10);
      expect(lowColor.green, greaterThan(180));
      expect(highColor.red, greaterThan(200));
    });

    test('higherIsBetter uses direct mapping', () {
      final lowColor = RatingColor.higherIsBetter(1);
      final highColor = RatingColor.higherIsBetter(10);
      expect(lowColor.red, greaterThan(200));
      expect(highColor.green, greaterThan(180));
    });

    test('middleIsBest peaks at middle values', () {
      final middleColor = RatingColor.middleIsBest(5);
      final lowColor = RatingColor.middleIsBest(1);
      final highColor = RatingColor.middleIsBest(10);

      expect(middleColor.green, greaterThan(lowColor.green));
      expect(middleColor.green, greaterThan(highColor.green));
      expect(lowColor.red, greaterThan(middleColor.red));
      expect(highColor.red, greaterThan(middleColor.red));
    });

    test('semanticBandsThroughPlotAndLabels returns correct colors for each type', () {
      final lowerGradient = RatingColor.semanticBandsThroughPlotAndLabels(
        MetricType.lowerIsBetter,
      );
      final higherGradient = RatingColor.semanticBandsThroughPlotAndLabels(
        MetricType.higherIsBetter,
      );
      final middleGradient = RatingColor.semanticBandsThroughPlotAndLabels(
        MetricType.middleIsBest,
      );

      expect(lowerGradient.length, equals(4));
      expect(higherGradient.length, equals(4));
      expect(middleGradient.length, equals(6));
    });
  });
}
