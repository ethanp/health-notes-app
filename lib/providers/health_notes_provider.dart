import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/grouped_health_notes.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/services/health_notes_dao.dart';
import 'package:health_notes/services/offline_repository.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:intl/intl.dart';

part 'health_notes_provider.g.dart';

@riverpod
class HealthNotesNotifier extends _$HealthNotesNotifier {
  @override
  Future<List<HealthNote>> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await HealthNotesDao.getAllNotes(user.id);
  }

  Future<void> addNote({
    required DateTime dateTime,
    required List<Symptom> symptomsList,
    required List<DrugDose> drugDoses,
    required String notes,
  }) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final note = HealthNote(
      id: DataUtils.uuid.v4(),
      dateTime: dateTime,
      symptomsList: symptomsList,
      drugDoses: drugDoses,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await HealthNotesDao.insertNote(note, user.id);
    DataUtils.syncService.queueForSync(
      'health_notes',
      note.id,
      'insert',
      note.toJsonForUpdate(),
    );

    ref.invalidateSelf();
  }

  Future<void> deleteNote(String id) async {
    await HealthNotesDao.deleteNote(id);
    DataUtils.syncService.queueForSync('health_notes', id, 'delete', {});
    ref.invalidateSelf();
  }

  Future<void> updateNote({
    required String id,
    required DateTime dateTime,
    required List<Symptom> symptomsList,
    required List<DrugDose> drugDoses,
    required String notes,
  }) async {
    final existingNote = await HealthNotesDao.getNoteById(id);
    if (existingNote == null) return;

    final updatedNote = existingNote.copyWith(
      dateTime: dateTime,
      symptomsList: symptomsList,
      drugDoses: drugDoses,
      notes: notes,
    );

    await HealthNotesDao.updateNote(updatedNote);
    DataUtils.syncService.queueForSync(
      'health_notes',
      id,
      'update',
      updatedNote.toJsonForUpdate(),
    );
    ref.invalidateSelf();
  }

  Future<void> refreshNotes() async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null) {
      await OfflineRepository.syncAllData(user.id);
    }
    ref.invalidateSelf();
  }

  Future<HealthNote?> getHealthNoteById(String id) async {
    return await HealthNotesDao.getNoteById(id);
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
  final notes = await ref.watch(healthNotesNotifierProvider.future);
  final notifier = ref.read(healthNotesNotifierProvider.notifier);
  return notifier._groupNotesByDate(notes);
}
