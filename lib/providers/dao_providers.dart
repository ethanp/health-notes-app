import 'package:ethan_sync/ethan_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/services/check_in_metrics_dao.dart';
import 'package:health_notes/services/check_ins_dao.dart';
import 'package:health_notes/services/condition_entries_dao.dart';
import 'package:health_notes/services/conditions_dao.dart';
import 'package:health_notes/services/health_notes_dao.dart';
import 'package:health_notes/services/health_tools_dao.dart';
import 'package:health_notes/services/medication_schedules_dao.dart';
import 'package:health_notes/services/user_profile_dao.dart';

final healthNotesDaoProvider = FutureProvider<HealthNotesDao>((ref) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return HealthNotesDao(database);
});

final checkInsDaoProvider = FutureProvider<CheckInsDao>((ref) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return CheckInsDao(database);
});

final userProfileDaoProvider = FutureProvider<UserProfileDao>((ref) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return UserProfileDao(database);
});

final checkInMetricsDaoProvider = FutureProvider<CheckInMetricsDao>((
  ref,
) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return CheckInMetricsDao(database);
});

final conditionsDaoProvider = FutureProvider<ConditionsDao>((ref) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return ConditionsDao(database);
});

final conditionEntriesDaoProvider = FutureProvider<ConditionEntriesDao>((
  ref,
) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return ConditionEntriesDao(database);
});

final medicationSchedulesDaoProvider = FutureProvider<MedicationSchedulesDao>((
  ref,
) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return MedicationSchedulesDao(database);
});

final healthToolsDaoProvider = FutureProvider<HealthToolsDao>((ref) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return HealthToolsDao(database);
});
