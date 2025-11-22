import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/spacing.dart';

/// Reusable notes section header with count
class NotesSection extends StatelessWidget {
  final int noteCount;
  final List<Widget> noteCards;

  const NotesSection({
    super.key,
    required this.noteCount,
    required this.noteCards,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health Notes ($noteCount)', style: AppTypography.headlineSmall),
        VSpace.of(12),
        ...noteCards,
      ],
    );
  }
}

/// Empty state for no matching notes
class NoMatchingNotesState extends StatelessWidget {
  const NoMatchingNotesState({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedUIComponents.emptyState(
      title: 'No matching notes',
      message: 'Try adjusting your search terms',
      icon: CupertinoIcons.search,
    );
  }
}

/// Activity data generator for trends
class TrendsActivityDataGenerator {
  /// Generate activity data map from notes with a value extractor
  static Map<DateTime, T> generate<T>({
    required List<HealthNote> notes,
    required T Function(HealthNote note) valueExtractor,
    required T Function(T existing, T newValue) aggregator,
  }) {
    final activityData = <DateTime, T>{};

    for (final note in notes) {
      final dateKey = DateTime(
        note.dateTime.year,
        note.dateTime.month,
        note.dateTime.day,
      );

      final value = valueExtractor(note);

      if (activityData.containsKey(dateKey)) {
        activityData[dateKey] = aggregator(activityData[dateKey]! as T, value);
      } else {
        activityData[dateKey] = value;
      }
    }

    return activityData;
  }

  /// Generate severity activity data (takes max severity per day)
  static Map<DateTime, int> generateSeverityData({
    required List<HealthNote> notes,
    required String symptomName,
  }) {
    return generate<int>(
      notes: notes,
      valueExtractor: (note) {
        final symptom = note.symptomsList.firstWhere(
          (s) => s.majorComponent == symptomName,
        );
        return symptom.severityLevel;
      },
      aggregator: (existing, newValue) =>
          existing > newValue ? existing : newValue,
    );
  }
}
