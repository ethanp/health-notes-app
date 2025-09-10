import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/services/check_in_metrics_dao.dart';
import 'package:health_notes/utils/data_utils.dart';

part 'check_in_metrics_provider.g.dart';

@riverpod
class CheckInMetricsNotifier extends _$CheckInMetricsNotifier {
  @override
  Future<List<CheckInMetric>> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await CheckInMetricsDao.getCheckInMetrics(user.id);
  }

  Future<void> addCheckInMetric({
    required String name,
    required MetricType type,
    required Color color,
    required IconData icon,
  }) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final nameExists = await CheckInMetricsDao.metricNameExists(
      user.id,
      name.trim(),
    );
    if (nameExists) {
      throw Exception('A metric with this name already exists');
    }

    final sortOrder = await CheckInMetricsDao.getNextSortOrder(user.id);

    final metric = CheckInMetric.create(
      userId: user.id,
      name: name,
      type: type,
      color: color,
      icon: icon,
      sortOrder: sortOrder,
    ).copyWith(id: DataUtils.uuid.v4());

    await CheckInMetricsDao.insertCheckInMetric(metric);
    DataUtils.syncService.queueForSync(
      'check_in_metrics',
      metric.id,
      'insert',
      CheckInMetricsDao.toSyncMap(metric),
    );

    ref.invalidateSelf();
  }

  Future<void> updateCheckInMetric(CheckInMetric metric) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final nameExists = await CheckInMetricsDao.metricNameExists(
      user.id,
      metric.name.trim(),
      excludeId: metric.id,
    );
    if (nameExists) {
      throw Exception('A metric with this name already exists');
    }

    final updatedMetric = metric.withUpdatedTimestamp();
    await CheckInMetricsDao.updateCheckInMetric(updatedMetric);
    DataUtils.syncService.queueForSync(
      'check_in_metrics',
      metric.id,
      'update',
      CheckInMetricsDao.toSyncMap(updatedMetric),
    );
    ref.invalidateSelf();
  }

  Future<void> deleteCheckInMetric(String id) async {
    await CheckInMetricsDao.deleteCheckInMetric(id);
    DataUtils.syncService.queueForSync('check_in_metrics', id, 'delete', {});
    ref.invalidateSelf();
  }

  Future<void> reorderMetrics(List<CheckInMetric> metrics) async {
    final updatedMetrics = <CheckInMetric>[];
    for (int i = 0; i < metrics.length; i++) {
      updatedMetrics.add(metrics[i].copyWith(sortOrder: i));
    }

    await CheckInMetricsDao.updateSortOrder(updatedMetrics);
    for (final metric in updatedMetrics) {
      DataUtils.syncService.queueForSync(
        'check_in_metrics',
        metric.id,
        'update',
        CheckInMetricsDao.toSyncMap(metric),
      );
    }
    ref.invalidateSelf();
  }

  Future<bool> metricNameExists(String name, {String? excludeId}) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return false;

    return await CheckInMetricsDao.metricNameExists(
      user.id,
      name,
      excludeId: excludeId,
    );
  }
}

/// Provider for getting a specific check-in metric by ID
@riverpod
Future<CheckInMetric?> checkInMetric(Ref ref, String id) async {
  return await CheckInMetricsDao.getCheckInMetricById(id);
}

/// Provider for checking if user has any check-in metrics
@riverpod
Future<bool> hasCheckInMetrics(Ref ref) async {
  final metrics = await ref.watch(checkInMetricsNotifierProvider.future);
  return metrics.isNotEmpty;
}
