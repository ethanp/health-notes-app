import 'package:health_notes/app_identity.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/grouped_health_notes.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/dao_providers.dart';
import 'package:health_notes/services/canonical_drug_names.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_notes_provider.g.dart';

@riverpod
class HealthNotesNotifier() extends _$HealthNotesNotifier {
  @override
  Future<List<HealthNote>> build() async {
    final notesDao = await ref.watch(healthNotesDaoProvider.future);
    final schedulesDao = await ref.watch(medicationSchedulesDaoProvider.future);
    await CanonicalDrugNames.rewriteStoredSpellings(
      userId: AppIdentity.localUserId,
      notesDao: notesDao,
      schedulesDao: schedulesDao,
    );
    return notesDao.getAllNotes(AppIdentity.localUserId);
  }

  Future<void> addNote({
    required DateTime dateTime,
    required List<Symptom> symptomsList,
    required List<DrugDose> drugDoses,
    List<AppliedTool> appliedTools = const [],
    required String notes,
  }) async {
    final notesDao = await ref.read(healthNotesDaoProvider.future);
    final note = HealthNote(
      id: DataUtils.uuid.v4(),
      dateTime: dateTime,
      symptomsList: symptomsList,
      drugDoses: drugDoses,
      appliedTools: appliedTools,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await notesDao.insertNote(note, AppIdentity.localUserId);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(String id) async {
    final notesDao = await ref.read(healthNotesDaoProvider.future);
    await notesDao.deleteNote(id);
    ref.invalidateSelf();
  }

  Future<void> updateNote({
    required String id,
    required DateTime dateTime,
    required List<Symptom> symptomsList,
    required List<DrugDose> drugDoses,
    List<AppliedTool> appliedTools = const [],
    required String notes,
  }) async {
    final notesDao = await ref.read(healthNotesDaoProvider.future);
    final existingNote = await notesDao.getNoteById(id);
    if (existingNote == null) return;

    final updatedNote = existingNote.copyWith(
      dateTime: dateTime,
      symptomsList: symptomsList,
      drugDoses: drugDoses,
      appliedTools: appliedTools.isEmpty
          ? existingNote.appliedTools
          : appliedTools,
      notes: notes,
    );
    await notesDao.updateNote(updatedNote);
    ref.invalidateSelf();
  }

  Future<void> refreshNotes() async {
    ref.invalidateSelf();
  }

  Future<HealthNote?> getHealthNoteById(String id) async {
    final notesDao = await ref.read(healthNotesDaoProvider.future);
    return notesDao.getNoteById(id);
  }

  List<GroupedHealthNotes> _groupNotesByDate(List<HealthNote> notes) {
    final groupedMap = notes.fold<Map<String, List<HealthNote>>>({}, (
      map,
      note,
    ) {
      final dateKey = DateFormat('yyyy-MM-dd').format(note.dateTime);
      map.putIfAbsent(dateKey, () => []).add(note);
      return map;
    });

    return groupedMap.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final sortedNotes = entry.value
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return GroupedHealthNotes(date: date, notes: sortedNotes);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}

@riverpod
Future<List<GroupedHealthNotes>> groupedHealthNotes(Ref ref) async {
  final notes = await ref.watch(healthNotesProvider.future);
  final notifier = ref.read(healthNotesProvider.notifier);
  return notifier._groupNotesByDate(notes);
}
