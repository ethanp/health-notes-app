import 'package:flutter/material.dart';
import 'package:health_notes/app_identity.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/providers/dao_providers.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_in_metrics_provider.g.dart';

@riverpod
class CheckInMetricsNotifier() extends _$CheckInMetricsNotifier {
  @override
  Future<List<CheckInMetric>> build() async {
    final metricsDao = await ref.watch(checkInMetricsDaoProvider.future);
    return metricsDao.getCheckInMetrics(AppIdentity.localUserId);
  }

  Future<void> addCheckInMetric({
    required String name,
    required MetricType type,
    required Color color,
    required IconData icon,
  }) async {
    final metricsDao = await ref.read(checkInMetricsDaoProvider.future);
    final nameExists = await metricsDao.metricNameExists(
      AppIdentity.localUserId,
      name.trim(),
    );
    if (nameExists) {
      throw Exception('A metric with this name already exists');
    }

    final sortOrder = await metricsDao.getNextSortOrder(
      AppIdentity.localUserId,
    );
    final metric = CheckInMetric.create(
      userId: AppIdentity.localUserId,
      name: name,
      type: type,
      colorValue: color.toARGB32(),
      iconCodePoint: icon.codePoint,
      sortOrder: sortOrder,
    ).copyWith(id: DataUtils.uuid.v4());
    await metricsDao.insertCheckInMetric(metric);
    ref.invalidateSelf();
  }

  Future<void> updateCheckInMetric(CheckInMetric metric) async {
    final metricsDao = await ref.read(checkInMetricsDaoProvider.future);
    final nameExists = await metricsDao.metricNameExists(
      AppIdentity.localUserId,
      metric.name.trim(),
      excludeId: metric.id,
    );
    if (nameExists) {
      throw Exception('A metric with this name already exists');
    }

    await metricsDao.updateCheckInMetric(metric.withUpdatedTimestamp());
    ref.invalidateSelf();
  }

  Future<void> deleteCheckInMetric(String id) async {
    final metricsDao = await ref.read(checkInMetricsDaoProvider.future);
    await metricsDao.deleteCheckInMetric(id);
    ref.invalidateSelf();
  }

  Future<void> reorderMetrics(List<CheckInMetric> metrics) async {
    final metricsDao = await ref.read(checkInMetricsDaoProvider.future);
    final updatedMetrics = <CheckInMetric>[
      for (var index = 0; index < metrics.length; index++)
        metrics[index].copyWith(sortOrder: index),
    ];
    await metricsDao.updateSortOrder(updatedMetrics);
    ref.invalidateSelf();
  }

  Future<bool> metricNameExists(String name, {String? excludeId}) async {
    final metricsDao = await ref.read(checkInMetricsDaoProvider.future);
    return metricsDao.metricNameExists(
      AppIdentity.localUserId,
      name,
      excludeId: excludeId,
    );
  }
}

@riverpod
Future<CheckInMetric?> checkInMetric(Ref ref, String id) async {
  final metricsDao = await ref.watch(checkInMetricsDaoProvider.future);
  return metricsDao.getCheckInMetricById(id);
}

@riverpod
Future<bool> hasCheckInMetrics(Ref ref) async {
  final metrics = await ref.watch(checkInMetricsProvider.future);
  return metrics.isNotEmpty;
}
