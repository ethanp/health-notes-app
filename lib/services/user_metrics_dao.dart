import 'package:sqflite/sqflite.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/services/local_database.dart';

/// Data Access Object for Check-In Metrics
class CheckInMetricsDao {
  static const String _tableName = 'check_in_metrics';

  static Future<List<CheckInMetric>> getCheckInMetrics(String userId) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'sort_order ASC, created_at ASC',
    );

    return maps.map((map) => _mapToCheckInMetric(map)).toList();
  }

  static Future<CheckInMetric?> getCheckInMetricById(String id) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToCheckInMetric(maps.first);
  }

  /// Insert a new check-in metric
  static Future<void> insertCheckInMetric(CheckInMetric metric) async {
    final db = await LocalDatabase.database;

    await db.insert(_tableName, {
      'id': metric.id,
      'user_id': metric.userId,
      'name': metric.name,
      'type': metric.type.name,
      'color_value': metric.colorValue,
      'icon_code_point': metric.iconCodePoint,
      'sort_order': metric.sortOrder,
      'created_at': metric.createdAt.toIso8601String(),
      'updated_at': metric.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.pending.value,
    });
  }

  /// Update an existing check-in metric
  static Future<void> updateCheckInMetric(CheckInMetric metric) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'name': metric.name,
        'type': metric.type.name,
        'color_value': metric.colorValue,
        'icon_code_point': metric.iconCodePoint,
        'sort_order': metric.sortOrder,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [metric.id],
    );
  }

  /// Soft delete a check-in metric
  static Future<void> deleteCheckInMetric(String id) async {
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

  /// Update the sort order of multiple metrics
  static Future<void> updateSortOrder(List<CheckInMetric> metrics) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final metric in metrics) {
      batch.update(
        _tableName,
        {
          'sort_order': metric.sortOrder,
          'updated_at': now,
          'sync_status': SyncStatus.pending.value,
        },
        where: 'id = ?',
        whereArgs: [metric.id],
      );
    }
    await batch.commit();
  }

  /// Get the next available sort order for a user
  static Future<int> getNextSortOrder(String userId) async {
    final db = await LocalDatabase.database;
    final result = await db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM $_tableName WHERE user_id = ? AND is_deleted = 0',
      [userId],
    );

    final maxOrder = result.first['max_order'] as int?;
    return (maxOrder ?? -1) + 1;
  }

  /// Clear all check-in metrics for a specific user (for migration purposes)
  static Future<void> clearCheckInMetrics(String userId) async {
    final db = await LocalDatabase.database;
    await db.delete(_tableName, where: 'user_id = ?', whereArgs: [userId]);
  }

  static Future<bool> metricNameExists(
    String userId,
    String name, {
    String? excludeId,
  }) async {
    final db = await LocalDatabase.database;
    final normalizedName = name.trim().toLowerCase();
    final whereClause = excludeId != null
        ? 'user_id = ? AND LOWER(TRIM(name)) = ? AND id != ? AND is_deleted = 0'
        : 'user_id = ? AND LOWER(TRIM(name)) = ? AND is_deleted = 0';
    final whereArgs = excludeId != null
        ? [userId, normalizedName, excludeId]
        : [userId, normalizedName];

    final result = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get check-in metrics that need to be synced
  static Future<List<Map<String, dynamic>>> getPendingSyncMetrics() async {
    final db = await LocalDatabase.database;
    return await db.query(
      _tableName,
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
    );
  }

  /// Mark a check-in metric as synced
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

  /// Mark a check-in metric sync as failed
  static Future<void> markSyncFailed(String id, String error) async {
    final db = await LocalDatabase.database;

    await db.update(
      _tableName,
      {'sync_status': SyncStatus.failed.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Upsert check-in metric from server data
  static Future<void> upsertFromServer(Map<String, dynamic> data) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(_tableName, {
      'id': data['id'],
      'user_id': data['user_id'],
      'name': data['name'],
      'type': data['type'],
      'color_value': data['color_value'],
      'icon_code_point': data['icon_code_point'],
      'sort_order': data['sort_order'],
      'created_at': data['created_at'],
      'updated_at': data['updated_at'],
      'synced_at': now,
      'sync_status': SyncStatus.synced.value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> markAllAsPending(String userId) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {'sync_status': SyncStatus.pending.value, 'updated_at': now},
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
    );
  }

  /// Convert database map to CheckInMetric object
  static CheckInMetric _mapToCheckInMetric(Map<String, dynamic> map) {
    return CheckInMetric(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      type: MetricType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => MetricType.higherIsBetter,
      ),
      colorValue: map['color_value'],
      iconCodePoint: map['icon_code_point'],
      sortOrder: map['sort_order'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
