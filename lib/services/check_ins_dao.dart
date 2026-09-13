import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:powersync/powersync.dart';

class CheckInsDao(final PowerSyncDatabase _powerSync) {
  static const _tableName = 'check_ins';

  Future<List<CheckIn>> getAllCheckIns(String userId) async {
    final checkInRows = await _powerSync.getAll(
      'SELECT * FROM $_tableName WHERE user_id = ? AND is_deleted = 0 '
      'ORDER BY date_time DESC',
      [userId],
    );
    return [for (final checkInRow in checkInRows) _mapToCheckIn(checkInRow)];
  }

  Future<CheckIn?> getCheckInById(String id) async {
    final checkInRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE id = ? AND is_deleted = 0',
      [id],
    );
    if (checkInRow == null) return null;
    return _mapToCheckIn(checkInRow);
  }

  Future<void> insertCheckIn(CheckIn checkIn, String userId) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.upsert(_tableName, {
      'id': checkIn.id,
      'user_id': userId,
      'metric_name': checkIn.metricName,
      'rating': checkIn.rating,
      'date_time': checkIn.dateTime.toIso8601String(),
      'created_at': checkIn.createdAt.toIso8601String(),
      'updated_at': now,
      'is_deleted': 0,
    });
  }

  Future<void> updateCheckIn(CheckIn checkIn) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET metric_name = ?, rating = ?, date_time = ?, '
      'updated_at = ? WHERE id = ?',
      [
        checkIn.metricName,
        checkIn.rating,
        checkIn.dateTime.toIso8601String(),
        now,
        checkIn.id,
      ],
    );
  }

  Future<void> deleteCheckIn(String id) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? WHERE id = ?',
      [now, id],
    );
  }

  Future<void> deleteCheckInGroup(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final placeholders = List.filled(ids.length, '?').join(',');
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? '
      'WHERE id IN ($placeholders)',
      [now, ...ids],
    );
  }

  static CheckIn _mapToCheckIn(Map<String, dynamic> checkInRow) {
    return CheckIn(
      id: checkInRow['id'] as String,
      metricName: checkInRow['metric_name'] as String,
      rating: checkInRow['rating'] as int,
      dateTime: DateTime.parse(checkInRow['date_time'] as String),
      createdAt: DateTime.parse(checkInRow['created_at'] as String),
    );
  }
}
