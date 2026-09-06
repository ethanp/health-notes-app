import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/utils/rating_color.dart';

void main() {
  group('RatingColor', () {
    test('redToGreen returns danger for rating 1', () {
      expect(RatingColor.redToGreen(1), EColors.danger);
    });

    test('redToGreen returns success for rating 10', () {
      expect(RatingColor.redToGreen(10), EColors.success);
    });

    test('redToGreen interpolates correctly for middle values', () {
      final color = RatingColor.redToGreen(5);
      expect(color.r, greaterThan(0.3));
      expect(color.g, greaterThan(0.3));
    });

    test('lowerIsBetter uses inverted mapping', () {
      expect(RatingColor.lowerIsBetter(1), EColors.success);
      expect(RatingColor.lowerIsBetter(10), EColors.danger);
    });

    test('higherIsBetter uses direct mapping', () {
      expect(RatingColor.higherIsBetter(1), EColors.danger);
      expect(RatingColor.higherIsBetter(10), EColors.success);
    });

    test('middleIsBest peaks at middle values', () {
      final middleColor = RatingColor.middleIsBest(5);
      final lowColor = RatingColor.middleIsBest(1);
      final highColor = RatingColor.middleIsBest(10);

      expect(middleColor.g, greaterThan(lowColor.g));
      expect(middleColor.g, greaterThan(highColor.g));
      expect(lowColor.r, greaterThan(middleColor.r));
      expect(highColor.r, greaterThan(middleColor.r));
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
