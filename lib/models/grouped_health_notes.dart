import 'package:health_notes/models/health_note.dart';

class GroupedHealthNotes {
  final DateTime date;
  final List<HealthNote> notes;

  const GroupedHealthNotes({required this.date, required this.notes});
}
