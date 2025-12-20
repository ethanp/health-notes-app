import 'dart:async';

import 'package:health_notes/services/check_in_metrics_dao.dart';
import 'package:health_notes/services/sync_service.dart';

class OfflineRepository {
  static final _syncService = SyncService();

  static Future<void> syncAllData(String userId) async {
    await _syncService.syncAllData(userId);
  }

  static Future<void> forceSyncAllData(String userId) async {
    await _syncService.forceSyncAllData(userId);
  }

  /// Stream of sync status changes (true means it isSyncing)
  static Stream<bool> get syncStatusStream => _syncService.syncStatusStream;

  static bool get isSyncing => _syncService.isSyncing;

  static Stream<String?> get syncErrorStream => _syncService.syncErrorStream;

  static Future<void> resyncAllCheckInMetrics(String userId) async {
    final metrics = await CheckInMetricsDao.getCheckInMetrics(userId);
    for (final metric in metrics) {
      await CheckInMetricsDao.updateCheckInMetric(
        metric.withUpdatedTimestamp(),
      );
      _syncService.queueForSync('check_in_metrics', metric.id, 'upsert', {
        'user_id': metric.userId,
        'name': metric.name,
        'type': metric.type.name,
        'color_value': metric.colorValue,
        'icon_code_point': metric.iconCodePoint,
        'sort_order': metric.sortOrder,
        'created_at': metric.createdAt.toIso8601String(),
        'updated_at': metric.updatedAt.toIso8601String(),
      });
    }
  }

  static Future<void> clearCheckInMetrics(String userId) async {
    await CheckInMetricsDao.clearCheckInMetrics(userId);
  }

  static Future<void> pushLocalOnly() async {
    await _syncService.pushLocalOnly();
  }
}
