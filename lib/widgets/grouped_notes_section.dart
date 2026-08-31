import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/utils/health_date_format.dart';
import 'package:health_notes/theme/spacing.dart';

class const GroupedNotesSection({
  required final List<HealthNote> notes,
  required final List<Widget> Function(List<HealthNote> notes) cardBuilder,
  final Widget? header,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const _EmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health Notes (${notes.length})', style: EText.headline.small),
        VSpace.sm,
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

  Widget _dateHeader(DateTime date, int count) => ESectionHeader(
    title: date.monthDayYear,
    subtitle: '$count note${count == 1 ? '' : 's'}',
  );
}

class const _EmptyState() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EEmptyState(
    title: 'No matching notes',
    message: 'Try adjusting your search terms',
    icon: CupertinoIcons.search,
  );
}
