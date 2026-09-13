import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/utils/symptom_severity.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/health_notes_activity_calendar.dart';
import 'package:health_notes/widgets/health_notes_month_stack.dart';

void main() {
  final DateTime now = DateTime.now();

  testWidgets('shows the current month when older months have activity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ETheme.material3Dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HealthNotesActivityCalendar(
              notes: [
                HealthNote(
                  id: 'older',
                  dateTime: DateTime(now.year, now.month - 3, 8),
                  createdAt: DateTime(now.year, now.month - 3, 8),
                ),
              ],
              onDateTap: (_) {},
            ),
          ),
        ),
      ),
    );

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    expect(find.text('${monthNames[now.month - 1]} ${now.year}'), findsOneWidget);
  });

  testWidgets('Grid | Charts replaces the month stack with the calendar trio', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ETheme.material3Dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HealthNotesActivityCalendar(
              notes: [
                HealthNote(
                  id: 'today',
                  dateTime: DateTime(now.year, now.month, 8),
                  createdAt: DateTime(now.year, now.month, 8),
                ),
              ],
              onDateTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Grid'), findsOneWidget);
    expect(find.byType(EMonthStackCalendar<DateTime>), findsOneWidget);

    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();

    expect(find.byType(ECalendarCharts), findsOneWidget);
    expect(find.text('Active days per week'), findsOneWidget);
    expect(find.text('notes per week'), findsOneWidget);
    expect(find.text('Trailing 7-day notes'), findsOneWidget);
    expect(find.byType(EMonthStackCalendar<DateTime>), findsNothing);
  });

  test('dosage captions include the medication unit at each quartile', () {
    final scale = DosageActivityCalendar.scaleFor(
      observedDosages: const [10, 20, 30, 40, 50, 60, 70, 80],
      unit: 'mg',
    );
    expect(scale.captionFor(EHeatmapIntensity.none), '0mg');
    expect(scale.captionFor(EHeatmapIntensity.low), '20mg');
    expect(scale.captionFor(EHeatmapIntensity.mid), '40mg');
    expect(scale.captionFor(EHeatmapIntensity.high), '60mg');
    expect(scale.captionFor(EHeatmapIntensity.peak), '80mg');
    expect(scale.legendTitle, contains('period quartiles'));
  });

  test('severity days use the domain color, not heatmap intensity', () {
    const severity = 8;
    final background = SymptomSeverity.hslGreenToRed(severity);
    final presentation = HealthNotesMonthStack.severityDay(
      date: DateTime(2026, 9, 8),
      severity: severity,
      background: background,
      semanticsLabel: 'Severity level 8',
    );
    expect(presentation.visual, isA<ECalendarDaySeverity>());
    expect((presentation.visual as ECalendarDaySeverity).fill, background);
    expect(presentation.visual, isNot(isA<ECalendarDayMeasuredHeat>()));
  });

  test('zero severity is an empty day', () {
    final presentation = HealthNotesMonthStack.severityDay(
      date: DateTime(2026, 9, 8),
      severity: 0,
      background: SymptomSeverity.hslGreenToRed(0),
      semanticsLabel: 'No activity',
    );
    expect(presentation.visual, isA<ECalendarDayEmpty>());
  });
}
