import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/services/health_notes_dao.dart';
import 'package:health_notes/services/medication_schedules_dao.dart';

class const PreferredDrugNameRewrite({
  required final List<HealthNote> notes,
  required final List<MedicationSchedule> schedules,
}) {
  bool get isEmpty => notes.isEmpty && schedules.isEmpty;
}

class CanonicalDrugNames() {
  static PreferredDrugNameRewrite pendingRewrites({
    required List<HealthNote> notes,
    required List<MedicationSchedule> schedules,
  }) {
    final preferredByIdentity = DrugName.preferredByIdentity([
      ...notes.expand((note) => note.drugDoses).map((dose) => dose.name),
      ...schedules.map((schedule) => schedule.medicationName),
    ]);

    final rewrittenNotes = <HealthNote>[];
    for (final note in notes) {
      final rewritten = note.withPreferredDrugNames(preferredByIdentity);
      if (!identical(rewritten, note)) rewrittenNotes.add(rewritten);
    }

    final rewrittenSchedules = <MedicationSchedule>[];
    for (final schedule in schedules) {
      final preferred = preferredByIdentity[schedule.medicationName.identity];
      if (preferred == null) continue;
      final rewritten = schedule.withPreferredName(preferred);
      if (!identical(rewritten, schedule)) rewrittenSchedules.add(rewritten);
    }

    return PreferredDrugNameRewrite(
      notes: rewrittenNotes,
      schedules: rewrittenSchedules,
    );
  }

  static Future<void> rewriteStoredSpellings({
    required String userId,
    required HealthNotesDao notesDao,
    required MedicationSchedulesDao schedulesDao,
  }) async {
    final pending = pendingRewrites(
      notes: await notesDao.getAllNotes(userId),
      schedules: await schedulesDao.getAllSchedules(userId),
    );
    for (final note in pending.notes) {
      await notesDao.updateNote(note);
    }
    for (final schedule in pending.schedules) {
      await schedulesDao.updateSchedule(schedule);
    }
  }
}
