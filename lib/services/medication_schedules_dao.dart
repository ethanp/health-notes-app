import 'dart:convert';

import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/services/local_database.dart';
import 'package:sqflite/sqflite.dart';

class MedicationSchedulesDao() {
  static const String _tableName = 'medication_schedules';

  static Future<List<MedicationSchedule>> getAllSchedules(String userId) async {
    final sqlite = await LocalDatabase.database;
    final scheduleRows = await sqlite.query(
      _tableName,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'start_date DESC',
    );
    return scheduleRows.map(_mapToSchedule).toList();
  }

  static Future<MedicationSchedule?> getScheduleById(String id) async {
    final sqlite = await LocalDatabase.database;
    final scheduleRows = await sqlite.query(
      _tableName,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (scheduleRows.isEmpty) return null;
    return _mapToSchedule(scheduleRows.first);
  }

  static Future<void> insertSchedule(
    MedicationSchedule schedule,
    String userId,
  ) async {
    final sqlite = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();
    await sqlite.insert(_tableName, {
      ..._rowFromSchedule(schedule, userId: userId),
      'created_at': schedule.createdAt.toIso8601String(),
      'updated_at': now,
      'sync_status': SyncStatus.pending.value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateSchedule(MedicationSchedule schedule) async {
    final sqlite = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();
    await sqlite.update(
      _tableName,
      {
        ..._rowFromSchedule(schedule, userId: schedule.userId),
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  static Future<void> stopSchedule(String id, DateTime endDate) async {
    final sqlite = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();
    await sqlite.update(
      _tableName,
      {
        'end_date': endDate.toIso8601String(),
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteSchedule(String id) async {
    final sqlite = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();
    await sqlite.update(
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

  static Future<List<Map<String, dynamic>>> getPendingSyncSchedules() async {
    final sqlite = await LocalDatabase.database;
    return sqlite.query(
      _tableName,
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
    );
  }

  static Future<void> markAsSynced(String id) async {
    final sqlite = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();
    await sqlite.update(
      _tableName,
      {'sync_status': SyncStatus.synced.value, 'synced_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> upsertFromServer(
    Map<String, dynamic> serverData,
    String userId,
  ) async {
    final sqlite = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();
    final existing = await getScheduleById(serverData['id']);
    final row = {
      'id': serverData['id'],
      'user_id': userId,
      'medication_name': serverData['medication_name'],
      'unit': serverData['unit'] ?? 'mg',
      'start_date': serverData['start_date'],
      'end_date': serverData['end_date'],
      'steps': jsonEncode(serverData['steps'] ?? []),
      'notes': serverData['notes'] ?? '',
      'created_at': serverData['created_at'] ?? now,
      'updated_at': serverData['updated_at'] ?? now,
      'sync_status': SyncStatus.synced.value,
      'synced_at': now,
    };

    if (existing != null) {
      final serverUpdated = DateTime.parse(
        serverData['updated_at'] ?? serverData['created_at'] ?? now,
      );
      if (!serverUpdated.isAfter(existing.updatedAt)) return;
      await sqlite.update(
        _tableName,
        row,
        where: 'id = ?',
        whereArgs: [serverData['id']],
      );
      return;
    }

    await sqlite.insert(
      _tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Map<String, dynamic> _rowFromSchedule(
    MedicationSchedule schedule, {
    required String userId,
  }) {
    return {
      'id': schedule.id,
      'user_id': userId,
      'medication_name': schedule.medicationName.display,
      'unit': schedule.unit,
      'start_date': schedule.startDate.toIso8601String(),
      'end_date': schedule.endDate?.toIso8601String(),
      'steps': jsonEncode(schedule.steps.map((step) => step.toJson()).toList()),
      'notes': schedule.notes,
    };
  }

  static MedicationSchedule _mapToSchedule(Map<String, dynamic> row) {
    final decodedSteps = jsonDecode(row['steps'] as String? ?? '[]') as List;
    return MedicationSchedule(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      medicationName: DrugName(row['medication_name'] as String),
      unit: row['unit'] as String? ?? 'mg',
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: row['end_date'] != null
          ? DateTime.parse(row['end_date'] as String)
          : null,
      steps: decodedSteps
          .map(
            (stepJson) =>
                ScheduleStep.fromJson(stepJson as Map<String, dynamic>),
          )
          .toList(),
      notes: row['notes'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
