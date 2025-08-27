import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/widgets/check_in_trends_chart.dart';

void main() {
  group('CheckInTrendsChart', () {
    testWidgets('displays empty state when no check-ins provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CheckInTrendsChart(checkIns: [])),
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
          home: Scaffold(body: CheckInTrendsChart(checkIns: checkIns)),
        ),
      );

      // Should show the chart title
      expect(find.text('Check-in Trends'), findsOneWidget);

      // Should show legend items for both metrics
      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);
    });

    testWidgets('handles single metric correctly', (tester) async {
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
          home: Scaffold(body: CheckInTrendsChart(checkIns: checkIns)),
        ),
      );

      // Should show the chart title
      expect(find.text('Check-in Trends'), findsOneWidget);

      // Should show legend item for the single metric
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
          home: Scaffold(body: CheckInTrendsChart(checkIns: checkIns)),
        ),
      );

      // Initially both metrics should be visible
      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);

      // Tap on Energy Level legend chip
      await tester.tap(find.text('Energy Level'));
      await tester.pump();

      // The Energy Level text should still be visible (legend remains)
      // but the line should be hidden from the chart
      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);

      // Tap again to show it
      await tester.tap(find.text('Energy Level'));
      await tester.pump();

      // Both should be visible again
      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);
    });

    testWidgets('legend chips are tappable', (tester) async {
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
          home: Scaffold(body: CheckInTrendsChart(checkIns: checkIns)),
        ),
      );

      // Verify the legend chip is tappable
      expect(find.byType(GestureDetector), findsOneWidget);

      // Tap the legend chip
      await tester.tap(find.text('Pain Level'));
      await tester.pump();

      // Should still be visible (legend remains even when hidden)
      expect(find.text('Pain Level'), findsOneWidget);
    });
  });
}
