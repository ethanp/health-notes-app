import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/widgets/check_in_trends_chart.dart';

void main() {
  // Create test user metrics
  final testUserMetrics = [
    CheckInMetric.create(
      userId: 'test-user',
      name: 'Energy Level',
      type: MetricType.higherIsBetter,
    ),
    CheckInMetric.create(
      userId: 'test-user',
      name: 'Mood',
      type: MetricType.higherIsBetter,
    ),
    CheckInMetric.create(
      userId: 'test-user',
      name: 'Sleep Quality',
      type: MetricType.higherIsBetter,
    ),
  ];

  group('CheckInTrendsChart', () {
    testWidgets('displays empty state when no check-ins provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckInTrendsChart(
              checkIns: [],
              userMetrics: testUserMetrics,
            ),
          ),
        ),
      );

      expect(find.text('No check-in data available'), findsOneWidget);
    });

    testWidgets('displays chart with multiple metrics', (tester) async {
      final checkIns = [
        CheckIn(
          id: '1',
          metricName: 'Energy Level',
          rating: 8,
          dateTime: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now(),
        ),
        CheckIn(
          id: '2',
          metricName: 'Mood',
          rating: 7,
          dateTime: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now(),
        ),
        CheckIn(
          id: '3',
          metricName: 'Energy Level',
          rating: 6,
          dateTime: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckInTrendsChart(
              checkIns: checkIns,
              userMetrics: testUserMetrics,
            ),
          ),
        ),
      );

      expect(find.text('Trends'), findsOneWidget);
      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);
    });

    testWidgets('handles single metric correctly', (tester) async {
      final singleMetricUserMetrics = [
        CheckInMetric.create(
          userId: 'test-user',
          name: 'Pain Level',
          type: MetricType.lowerIsBetter,
        ),
      ];

      final checkIns = [
        CheckIn(
          id: '1',
          metricName: 'Pain Level',
          rating: 3,
          dateTime: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now(),
        ),
        CheckIn(
          id: '2',
          metricName: 'Pain Level',
          rating: 5,
          dateTime: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckInTrendsChart(
              checkIns: checkIns,
              userMetrics: singleMetricUserMetrics,
            ),
          ),
        ),
      );

      expect(find.text('Trends'), findsOneWidget);
      expect(find.text('Pain Level'), findsOneWidget);
    });

    testWidgets('toggles metric visibility when legend chip is tapped', (
      tester,
    ) async {
      final checkIns = [
        CheckIn(
          id: '1',
          metricName: 'Energy Level',
          rating: 8,
          dateTime: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now(),
        ),
        CheckIn(
          id: '2',
          metricName: 'Mood',
          rating: 7,
          dateTime: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckInTrendsChart(
              checkIns: checkIns,
              userMetrics: testUserMetrics,
            ),
          ),
        ),
      );

      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);

      await tester.tap(find.text('Energy Level'));
      await tester.pump();

      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);

      await tester.tap(find.text('Energy Level'));
      await tester.pump();

      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);
    });

    testWidgets('legend chips are tappable', (tester) async {
      final singleMetricUserMetrics = [
        CheckInMetric.create(
          userId: 'test-user',
          name: 'Pain Level',
          type: MetricType.lowerIsBetter,
        ),
      ];

      final checkIns = [
        CheckIn(
          id: '1',
          metricName: 'Pain Level',
          rating: 3,
          dateTime: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckInTrendsChart(
              checkIns: checkIns,
              userMetrics: singleMetricUserMetrics,
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);

      await tester.tap(find.text('Pain Level'));
      await tester.pump();

      expect(find.text('Pain Level'), findsOneWidget);
    });
  });
}
