import 'dart:convert';

import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:powersync/powersync.dart';

class HealthNotesDao(final PowerSyncDatabase _powerSync) {
  static const _tableName = 'health_notes';

  Future<List<HealthNote>> getAllNotes(String userId) async {
    final noteRows = await _powerSync.getAll(
      'SELECT * FROM $_tableName WHERE user_id = ? AND is_deleted = 0 '
      'ORDER BY created_at DESC',
      [userId],
    );
    return [for (final noteRow in noteRows) _mapToHealthNote(noteRow)];
  }

  Future<HealthNote?> getNoteById(String id) async {
    final noteRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE id = ? AND is_deleted = 0',
      [id],
    );
    if (noteRow == null) return null;
    return _mapToHealthNote(noteRow);
  }

  Future<void> insertNote(HealthNote note, String userId) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.upsert(_tableName, {
      'id': note.id,
      'user_id': userId,
      ..._noteColumns(note),
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': now,
      'is_deleted': 0,
    });
  }

  Future<void> updateNote(HealthNote note) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET date_time = ?, symptoms_list = ?, drug_doses = ?, '
      'applied_tools = ?, notes = ?, updated_at = ? WHERE id = ?',
      [
        note.dateTime.toIso8601String(),
        jsonEncode(note.symptomsList.map((symptom) => symptom.toJson()).toList()),
        jsonEncode(note.drugDoses.map((dose) => dose.toJson()).toList()),
        jsonEncode(note.appliedTools.map((tool) => tool.toJson()).toList()),
        note.notes,
        now,
        note.id,
      ],
    );
  }

  Future<void> deleteNote(String id) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? WHERE id = ?',
      [now, id],
    );
  }

  Map<String, Object?> _noteColumns(HealthNote note) {
    return {
      'date_time': note.dateTime.toIso8601String(),
      'symptoms_list': jsonEncode(
        note.symptomsList.map((symptom) => symptom.toJson()).toList(),
      ),
      'drug_doses': jsonEncode(
        note.drugDoses.map((dose) => dose.toJson()).toList(),
      ),
      'applied_tools': jsonEncode(
        note.appliedTools.map((tool) => tool.toJson()).toList(),
      ),
      'notes': note.notes,
    };
  }

  static HealthNote _mapToHealthNote(Map<String, dynamic> noteRow) {
    return HealthNote(
      id: noteRow['id'] as String,
      dateTime: DateTime.parse(noteRow['date_time'] as String),
      symptomsList: (jsonDecode(noteRow['symptoms_list'] as String) as List)
          .map((json) => Symptom.fromJson(json as Map<String, dynamic>))
          .toList(),
      drugDoses: (jsonDecode(noteRow['drug_doses'] as String) as List)
          .map((json) => DrugDose.fromJson(json as Map<String, dynamic>))
          .toList(),
      appliedTools: _parseAppliedTools(noteRow['applied_tools']),
      notes: noteRow['notes'] as String,
      createdAt: DateTime.parse(noteRow['created_at'] as String),
    );
  }

  static List<AppliedTool> _parseAppliedTools(dynamic raw) {
    try {
      if (raw == null) return const [];
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is List) {
        return [
          for (final toolJson in decoded)
            AppliedTool.fromJson(toolJson as Map<String, dynamic>),
        ];
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
