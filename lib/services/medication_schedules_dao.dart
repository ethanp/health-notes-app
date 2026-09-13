import 'dart:convert';

import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:powersync/powersync.dart';

class MedicationSchedulesDao(final PowerSyncDatabase _powerSync) {
  static const _tableName = 'medication_schedules';

  Future<List<MedicationSchedule>> getAllSchedules(String userId) async {
    final scheduleRows = await _powerSync.getAll(
      'SELECT * FROM $_tableName WHERE user_id = ? AND is_deleted = 0 '
      'ORDER BY start_date DESC',
      [userId],
    );
    return [for (final scheduleRow in scheduleRows) _mapToSchedule(scheduleRow)];
  }

  Future<MedicationSchedule?> getScheduleById(String id) async {
    final scheduleRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE id = ? AND is_deleted = 0',
      [id],
    );
    if (scheduleRow == null) return null;
    return _mapToSchedule(scheduleRow);
  }

  Future<void> insertSchedule(
    MedicationSchedule schedule,
    String userId,
  ) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.upsert(_tableName, {
      ..._rowFromSchedule(schedule, userId: userId),
      'created_at': schedule.createdAt.toIso8601String(),
      'updated_at': now,
      'is_deleted': 0,
    });
  }

  Future<void> updateSchedule(MedicationSchedule schedule) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET medication_name = ?, unit = ?, start_date = ?, '
      'end_date = ?, steps = ?, notes = ?, updated_at = ? WHERE id = ?',
      [
        schedule.medicationName.display,
        schedule.unit,
        schedule.startDate.toIso8601String(),
        schedule.endDate?.toIso8601String(),
        jsonEncode(schedule.steps.map((step) => step.toJson()).toList()),
        schedule.notes,
        now,
        schedule.id,
      ],
    );
  }

  Future<void> stopSchedule(String id, DateTime endDate) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET end_date = ?, updated_at = ? WHERE id = ?',
      [endDate.toIso8601String(), now, id],
    );
  }

  Future<void> deleteSchedule(String id) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? WHERE id = ?',
      [now, id],
    );
  }

  static Map<String, Object?> _rowFromSchedule(
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

  static MedicationSchedule _mapToSchedule(Map<String, dynamic> scheduleRow) {
    final decodedSteps =
        jsonDecode(scheduleRow['steps'] as String? ?? '[]') as List;
    return MedicationSchedule(
      id: scheduleRow['id'] as String,
      userId: scheduleRow['user_id'] as String,
      medicationName: DrugName(scheduleRow['medication_name'] as String),
      unit: scheduleRow['unit'] as String? ?? 'mg',
      startDate: DateTime.parse(scheduleRow['start_date'] as String),
      endDate: scheduleRow['end_date'] != null
          ? DateTime.parse(scheduleRow['end_date'] as String)
          : null,
      steps: [
        for (final stepJson in decodedSteps)
          ScheduleStep.fromJson(stepJson as Map<String, dynamic>),
      ],
      notes: scheduleRow['notes'] as String? ?? '',
      createdAt: DateTime.parse(scheduleRow['created_at'] as String),
      updatedAt: DateTime.parse(scheduleRow['updated_at'] as String),
    );
  }
}
