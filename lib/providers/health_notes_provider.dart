import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/grouped_health_notes.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:intl/intl.dart';

part 'health_notes_provider.g.dart';

@riverpod
class HealthNotesNotifier extends _$HealthNotesNotifier {
  @override
  Future<List<HealthNote>> build() async {
    return _loadNotes();
  }

  Future<List<HealthNote>> _loadNotes() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await Supabase.instance.client
          .from('health_notes')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response.map((json) => HealthNote.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load notes: $e');
    }
  }

  Future<void> addNote({
    required DateTime dateTime,
    required String symptoms,
    required List<DrugDose> drugDoses,
    required String notes,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client.from('health_notes').insert({
        'user_id': user.id,
        'date_time': dateTime.toIso8601String(),
        'symptoms': symptoms.trim(),
        'drug_doses': drugDoses.map((dose) => dose.toJson()).toList(),
        'notes': notes.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client
          .from('health_notes')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);

      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  Future<void> updateNote({
    required String id,
    required DateTime dateTime,
    required String symptoms,
    required List<DrugDose> drugDoses,
    required String notes,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client
          .from('health_notes')
          .update({
            'date_time': dateTime.toIso8601String(),
            'symptoms': symptoms.trim(),
            'drug_doses': drugDoses.map((dose) => dose.toJson()).toList(),
            'notes': notes.trim(),
          })
          .eq('id', id)
          .eq('user_id', user.id);

      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> refreshNotes() async {
    ref.invalidateSelf();
  }

  List<GroupedHealthNotes> _groupNotesByDate(List<HealthNote> notes) {
    final groupedMap = <String, List<HealthNote>>{};

    for (final note in notes) {
      final dateKey = DateFormat('yyyy-MM-dd').format(note.dateTime);
      groupedMap.putIfAbsent(dateKey, () => []).add(note);
    }

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
