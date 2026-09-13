import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/models/condition.dart';
import 'package:powersync/powersync.dart';

class ConditionsDao(final PowerSyncDatabase _powerSync) {
  static const _tableName = 'conditions';

  Future<List<Condition>> getAllConditions(String userId) async {
    final conditionRows = await _powerSync.getAll(
      'SELECT * FROM $_tableName WHERE user_id = ? AND is_deleted = 0 '
      'ORDER BY start_date DESC',
      [userId],
    );
    return [
      for (final conditionRow in conditionRows) _mapToCondition(conditionRow),
    ];
  }

  Future<List<Condition>> getActiveConditions(String userId) async {
    final conditionRows = await _powerSync.getAll(
      'SELECT * FROM $_tableName WHERE user_id = ? AND condition_status = ? '
      'AND is_deleted = 0 ORDER BY start_date DESC',
      [userId, 'active'],
    );
    return [
      for (final conditionRow in conditionRows) _mapToCondition(conditionRow),
    ];
  }

  Future<Condition?> getConditionById(String id) async {
    final conditionRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE id = ? AND is_deleted = 0',
      [id],
    );
    if (conditionRow == null) return null;
    return _mapToCondition(conditionRow);
  }

  Future<Condition?> getActiveConditionByName(
    String userId,
    String name,
  ) async {
    final conditionRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE user_id = ? AND name = ? '
      'AND condition_status = ? AND is_deleted = 0 LIMIT 1',
      [userId, name, 'active'],
    );
    if (conditionRow == null) return null;
    return _mapToCondition(conditionRow);
  }

  Future<void> insertCondition(Condition condition, String userId) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.upsert(_tableName, {
      'id': condition.id,
      'user_id': userId,
      'name': condition.name,
      'start_date': condition.startDate.toIso8601String(),
      'end_date': condition.endDate?.toIso8601String(),
      'condition_status': condition.status.name,
      'color_value': condition.colorValue,
      'icon_code_point': condition.iconCodePoint,
      'notes': condition.notes,
      'created_at': condition.createdAt.toIso8601String(),
      'updated_at': now,
      'is_deleted': 0,
    });
  }

  Future<void> updateCondition(Condition condition) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET name = ?, start_date = ?, end_date = ?, '
      'condition_status = ?, color_value = ?, icon_code_point = ?, notes = ?, '
      'updated_at = ? WHERE id = ?',
      [
        condition.name,
        condition.startDate.toIso8601String(),
        condition.endDate?.toIso8601String(),
        condition.status.name,
        condition.colorValue,
        condition.iconCodePoint,
        condition.notes,
        now,
        condition.id,
      ],
    );
  }

  Future<void> resolveCondition(String id, DateTime endDate) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET condition_status = ?, end_date = ?, '
      'updated_at = ? WHERE id = ?',
      [ConditionStatus.resolved.name, endDate.toIso8601String(), now, id],
    );
  }

  Future<void> deleteCondition(String id) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? WHERE id = ?',
      [now, id],
    );
  }

  static Condition _mapToCondition(Map<String, dynamic> conditionRow) {
    return Condition(
      id: conditionRow['id'] as String,
      userId: conditionRow['user_id'] as String,
      name: conditionRow['name'] as String,
      startDate: DateTime.parse(conditionRow['start_date'] as String),
      endDate: conditionRow['end_date'] != null
          ? DateTime.parse(conditionRow['end_date'] as String)
          : null,
      status: ConditionStatus.values.firstWhere(
        (status) => status.name == conditionRow['condition_status'],
        orElse: () => ConditionStatus.active,
      ),
      colorValue: conditionRow['color_value'] as int,
      iconCodePoint: conditionRow['icon_code_point'] as int,
      notes: conditionRow['notes'] as String? ?? '',
      createdAt: DateTime.parse(conditionRow['created_at'] as String),
      updatedAt: DateTime.parse(conditionRow['updated_at'] as String),
    );
  }
}
