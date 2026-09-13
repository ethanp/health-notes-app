import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:powersync/powersync.dart';

class CheckInMetricsDao(final PowerSyncDatabase _powerSync) {
  static const _tableName = 'check_in_metrics';

  Future<List<CheckInMetric>> getCheckInMetrics(String userId) async {
    final metricRows = await _powerSync.getAll(
      'SELECT * FROM $_tableName WHERE user_id = ? AND is_deleted = 0 '
      'ORDER BY sort_order ASC, created_at ASC',
      [userId],
    );
    return [for (final metricRow in metricRows) _mapToCheckInMetric(metricRow)];
  }

  Future<CheckInMetric?> getCheckInMetricById(String id) async {
    final metricRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE id = ? AND is_deleted = 0',
      [id],
    );
    if (metricRow == null) return null;
    return _mapToCheckInMetric(metricRow);
  }

  Future<void> insertCheckInMetric(CheckInMetric metric) async {
    await _powerSync.upsert(_tableName, {
      'id': metric.id,
      'user_id': metric.userId,
      'name': metric.name,
      'type': metric.type.name,
      'color_value': metric.colorValue,
      'icon_code_point': metric.iconCodePoint,
      'sort_order': metric.sortOrder,
      'created_at': metric.createdAt.toIso8601String(),
      'updated_at': metric.updatedAt.toIso8601String(),
      'is_deleted': 0,
    });
  }

  Future<void> updateCheckInMetric(CheckInMetric metric) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET name = ?, type = ?, color_value = ?, '
      'icon_code_point = ?, sort_order = ?, updated_at = ? WHERE id = ?',
      [
        metric.name,
        metric.type.name,
        metric.colorValue,
        metric.iconCodePoint,
        metric.sortOrder,
        now,
        metric.id,
      ],
    );
  }

  /// Soft-delete so existing check-ins can still show the metric name.
  Future<void> deleteCheckInMetric(String id) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? WHERE id = ?',
      [now, id],
    );
  }

  Future<void> updateSortOrder(List<CheckInMetric> metrics) async {
    final now = DateTime.now().toIso8601String();
    for (final metric in metrics) {
      await _powerSync.execute(
        'UPDATE $_tableName SET sort_order = ?, updated_at = ? WHERE id = ?',
        [metric.sortOrder, now, metric.id],
      );
    }
  }

  Future<int> getNextSortOrder(String userId) async {
    final maxRow = await _powerSync.getOptional(
      'SELECT MAX(sort_order) AS max_order FROM $_tableName '
      'WHERE user_id = ? AND is_deleted = 0',
      [userId],
    );
    final maxOrder = maxRow?['max_order'] as int?;
    return (maxOrder ?? -1) + 1;
  }

  Future<void> clearCheckInMetrics(String userId) async {
    await _powerSync.execute('DELETE FROM $_tableName WHERE user_id = ?', [
      userId,
    ]);
  }

  Future<bool> metricNameExists(
    String userId,
    String name, {
    String? excludeId,
  }) async {
    final normalizedName = MetricNameNormalizer.normalize(name);
    final existing = excludeId != null
        ? await _powerSync.getOptional(
            'SELECT id FROM $_tableName WHERE user_id = ? AND LOWER(TRIM(name)) = ? '
            'AND id != ? AND is_deleted = 0 LIMIT 1',
            [userId, normalizedName, excludeId],
          )
        : await _powerSync.getOptional(
            'SELECT id FROM $_tableName WHERE user_id = ? AND LOWER(TRIM(name)) = ? '
            'AND is_deleted = 0 LIMIT 1',
            [userId, normalizedName],
          );
    return existing != null;
  }

  static CheckInMetric _mapToCheckInMetric(Map<String, dynamic> metricRow) {
    return CheckInMetric(
      id: metricRow['id'] as String,
      userId: metricRow['user_id'] as String,
      name: metricRow['name'] as String,
      type: MetricType.values.firstWhere(
        (type) => type.name == metricRow['type'],
        orElse: () => MetricType.higherIsBetter,
      ),
      colorValue: metricRow['color_value'] as int,
      iconCodePoint: metricRow['icon_code_point'] as int,
      sortOrder: metricRow['sort_order'] as int,
      createdAt: DateTime.parse(metricRow['created_at'] as String),
      updatedAt: DateTime.parse(metricRow['updated_at'] as String),
    );
  }
}
