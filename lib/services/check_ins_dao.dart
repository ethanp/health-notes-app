import 'package:sqflite/sqflite.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/services/local_database.dart';

/// Data Access Object for Check Ins
class CheckInsDao {
  static const String _tableName = 'check_ins';

  /// Get all check ins for a user
  static Future<List<CheckIn>> getAllCheckIns(String userId) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'date_time DESC',
    );

    return maps.map((map) => _mapToCheckIn(map)).toList();
  }

  /// Get a specific check in by ID
  static Future<CheckIn?> getCheckInById(String id) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToCheckIn(maps.first);
  }

  /// Insert a new check in
  static Future<void> insertCheckIn(CheckIn checkIn, String userId) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(_tableName, {
      'id': checkIn.id,
      'user_id': userId,
      'metric_name': checkIn.metricName,
      'rating': checkIn.rating,
      'date_time': checkIn.dateTime.toIso8601String(),
      'created_at': checkIn.createdAt.toIso8601String(),
      'updated_at': now,
      'sync_status': SyncStatus.pending.value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update an existing check in
  static Future<void> updateCheckIn(CheckIn checkIn) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'metric_name': checkIn.metricName,
        'rating': checkIn.rating,
        'date_time': checkIn.dateTime.toIso8601String(),
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [checkIn.id],
    );
  }

  /// Delete a check in (soft delete)
  static Future<void> deleteCheckIn(String id) async {
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

  /// Delete multiple check ins (soft delete)
  static Future<void> deleteCheckInGroup(List<String> ids) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'is_deleted': 1,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// Get check ins that need to be synced
  static Future<List<Map<String, dynamic>>> getPendingSyncCheckIns() async {
    final db = await LocalDatabase.database;
    return await db.query(
      _tableName,
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
    );
  }

  /// Mark a check in as synced
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

  /// Mark a check in sync as failed
  static Future<void> markSyncFailed(String id, String error) async {
    final db = await LocalDatabase.database;

    await db.update(
      _tableName,
      {'sync_status': SyncStatus.failed.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Upsert a check in from server (for sync)
  static Future<void> upsertFromServer(
    Map<String, dynamic> serverData,
    String userId,
  ) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    final existing = await getCheckInById(serverData['id']);

    if (existing != null) {
      final serverUpdatedStr =
          serverData['updated_at'] ?? serverData['created_at'] ?? now;
      final serverUpdated = DateTime.parse(serverUpdatedStr);
      final localUpdated = DateTime.parse(existing.createdAt.toIso8601String());

      if (serverUpdated.isAfter(localUpdated)) {
        await db.update(
          _tableName,
          {
            'metric_name': serverData['metric_name'],
            'rating': serverData['rating'],
            'date_time': serverData['date_time'],
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
        'metric_name': serverData['metric_name'],
        'rating': serverData['rating'],
        'date_time': serverData['date_time'],
        'created_at': serverData['created_at'],
        'updated_at':
            serverData['updated_at'] ?? serverData['created_at'] ?? now,
        'sync_status': SyncStatus.synced.value,
        'synced_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Convert database map to CheckIn object
  static CheckIn _mapToCheckIn(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'],
      metricName: map['metric_name'],
      rating: map['rating'],
      dateTime: DateTime.parse(map['date_time']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
