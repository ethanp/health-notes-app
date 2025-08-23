import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/drug_dose.dart';

part 'health_notes_provider.g.dart';

@riverpod
class HealthNotesNotifier extends _$HealthNotesNotifier {
  @override
  Future<List<HealthNote>> build() async {
    return _loadNotes();
  }

  Future<List<HealthNote>> _loadNotes() async {
    try {
      final response = await Supabase.instance.client
          .from('health_notes')
          .select()
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
      await Supabase.instance.client.from('health_notes').insert({
        'date_time': dateTime.toIso8601String(),
        'symptoms': symptoms.trim(),
        'drug_doses': drugDoses.map((dose) => dose.toJson()).toList(),
        'notes': notes.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Refresh the notes list
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await Supabase.instance.client.from('health_notes').delete().eq('id', id);

      // Refresh the notes list
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  Future<void> refreshNotes() async {
    ref.invalidateSelf();
  }
}
