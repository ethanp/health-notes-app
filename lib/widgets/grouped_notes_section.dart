import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/theme/spacing.dart';

class GroupedNotesSection extends StatelessWidget {
  final List<HealthNote> notes;
  final List<Widget> Function(List<HealthNote> notes) cardBuilder;
  final Widget? header;

  const GroupedNotesSection({
    super.key,
    required this.notes,
    required this.cardBuilder,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const _EmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health Notes (${notes.length})',
            style: AppText.headline.small),
        VSpace.of(12),
        if (header != null) header!,
        ..._dateGroupedCards(),
      ],
    );
  }

  List<Widget> _dateGroupedCards() {
    final grouped = _groupByDate();
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      widgets.add(_dateHeader(entry.key, entry.value.length));
      widgets.addAll(cardBuilder(entry.value));
    }

    return widgets;
  }

  Map<DateTime, List<HealthNote>> _groupByDate() {
    final grouped = <DateTime, List<HealthNote>>{};
    for (final note in notes) {
      grouped.putIfAbsent(note.dateTime.startOfDay, () => []).add(note);
    }
    return grouped;
  }

  Widget _dateHeader(DateTime date, int count) =>
      EnhancedUIComponents.sectionHeader(
        title: AppDateUtils.formatShortDate(date),
        subtitle: '$count note${count == 1 ? '' : 's'}',
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => EnhancedUIComponents.emptyState(
        title: 'No matching notes',
        message: 'Try adjusting your search terms',
        icon: CupertinoIcons.search,
      );
}
