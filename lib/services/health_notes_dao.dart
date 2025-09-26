import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/services/local_database.dart';

/// Data Access Object for Health Notes
class HealthNotesDao {
  static const String _tableName = 'health_notes';

  /// Get all health notes for a user
  static Future<List<HealthNote>> getAllNotes(String userId) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToHealthNote(map)).toList();
  }

  /// Get a specific health note by ID
  static Future<HealthNote?> getNoteById(String id) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToHealthNote(maps.first);
  }

  /// Insert a new health note
  static Future<void> insertNote(HealthNote note, String userId) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(_tableName, {
      'id': note.id,
      'user_id': userId,
      'date_time': note.dateTime.toIso8601String(),
      'symptoms_list': jsonEncode(
        note.symptomsList.map((s) => s.toJson()).toList(),
      ),
      'drug_doses': jsonEncode(note.drugDoses.map((d) => d.toJson()).toList()),
      'notes': note.notes,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': now,
      'sync_status': SyncStatus.pending.value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update an existing health note
  static Future<void> updateNote(HealthNote note) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'date_time': note.dateTime.toIso8601String(),
        'symptoms_list': jsonEncode(
          note.symptomsList.map((s) => s.toJson()).toList(),
        ),
        'drug_doses': jsonEncode(
          note.drugDoses.map((d) => d.toJson()).toList(),
        ),
        'notes': note.notes,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Delete a health note (soft delete)
  static Future<void> deleteNote(String id) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'is_deleted': 1,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get notes that need to be synced
  static Future<List<Map<String, dynamic>>> getPendingSyncNotes() async {
    final db = await LocalDatabase.database;
    return await db.query(
      _tableName,
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
    );
  }

  /// Mark a note as synced
  static Future<void> markAsSynced(String id) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {'sync_status': SyncStatus.synced.value, 'synced_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Upsert a note from server (for sync)
  static Future<void> upsertFromServer(
    Map<String, dynamic> serverData,
    String userId,
  ) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    final existing = await getNoteById(serverData['id']);

    if (existing != null) {
      final serverUpdatedStr =
          serverData['updated_at'] ?? serverData['created_at'] ?? now;
      final serverUpdated = DateTime.parse(serverUpdatedStr);
      final localUpdated = DateTime.parse(existing.createdAt.toIso8601String());

      if (serverUpdated.isAfter(localUpdated)) {
        await db.update(
          _tableName,
          {
            'date_time': serverData['date_time'],
            'symptoms_list': jsonEncode(serverData['symptoms_list']),
            'drug_doses': jsonEncode(serverData['drug_doses']),
            'notes': serverData['notes'],
            'updated_at':
                serverData['updated_at'] ?? serverData['created_at'] ?? now,
            'sync_status': SyncStatus.synced.value,
            'synced_at': now,
          },
          where: 'id = ?',
          whereArgs: [serverData['id']],
        );
      }
    } else {
      await db.insert(_tableName, {
        'id': serverData['id'],
        'user_id': userId,
        'date_time': serverData['date_time'],
        'symptoms_list': jsonEncode(serverData['symptoms_list']),
        'drug_doses': jsonEncode(serverData['drug_doses']),
        'notes': serverData['notes'],
        'created_at': serverData['created_at'],
        'updated_at':
            serverData['updated_at'] ?? serverData['created_at'] ?? now,
        'sync_status': SyncStatus.synced.value,
        'synced_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Convert database map to HealthNote object
  static HealthNote _mapToHealthNote(Map<String, dynamic> map) {
    return HealthNote(
      id: map['id'],
      dateTime: DateTime.parse(map['date_time']),
      symptomsList: (jsonDecode(map['symptoms_list']) as List)
          .map((json) => Symptom.fromJson(json))
          .toList(),
      drugDoses: (jsonDecode(map['drug_doses']) as List)
          .map((json) => DrugDose.fromJson(json))
          .toList(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
