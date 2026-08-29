import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/services/canonical_drug_names.dart';
import 'package:health_notes/services/medication_schedules_dao.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medication_schedules_provider.g.dart';

@riverpod
class MedicationSchedulesNotifier extends _$MedicationSchedulesNotifier {
  @override
  Future<List<MedicationSchedule>> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }
    await CanonicalDrugNames.rewriteStoredSpellings(user.id);
    return MedicationSchedulesDao.getAllSchedules(user.id);
  }

  Future<MedicationSchedule> addSchedule(MedicationSchedule schedule) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }
    await MedicationSchedulesDao.insertSchedule(schedule, user.id);
    DataUtils.syncService.queueForSync(
      'medication_schedules',
      schedule.id,
      'insert',
      schedule.toJsonForUpdate(),
    );
    ref.invalidateSelf();
    return schedule;
  }

  Future<void> updateSchedule(MedicationSchedule schedule) async {
    await MedicationSchedulesDao.updateSchedule(schedule);
    DataUtils.syncService.queueForSync(
      'medication_schedules',
      schedule.id,
      'update',
      schedule.toJsonForUpdate(),
    );
    ref.invalidateSelf();
  }

  Future<void> stopSchedule(String id, {DateTime? endDate}) async {
    final stopDate = endDate ?? DateTime.now();
    await MedicationSchedulesDao.stopSchedule(id, stopDate);
    DataUtils.syncService.queueForSync('medication_schedules', id, 'update', {
      'end_date': stopDate.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    ref.invalidateSelf();
  }

  Future<void> deleteSchedule(String id) async {
    await MedicationSchedulesDao.deleteSchedule(id);
    DataUtils.syncService.queueForSync(
      'medication_schedules',
      id,
      'delete',
      {},
    );
    ref.invalidateSelf();
  }
}
