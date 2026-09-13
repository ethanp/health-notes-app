import 'package:health_notes/app_identity.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/providers/dao_providers.dart';
import 'package:health_notes/services/canonical_drug_names.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medication_schedules_provider.g.dart';

@riverpod
class MedicationSchedulesNotifier() extends _$MedicationSchedulesNotifier {
  @override
  Future<List<MedicationSchedule>> build() async {
    final notesDao = await ref.watch(healthNotesDaoProvider.future);
    final schedulesDao = await ref.watch(medicationSchedulesDaoProvider.future);
    await CanonicalDrugNames.rewriteStoredSpellings(
      userId: AppIdentity.localUserId,
      notesDao: notesDao,
      schedulesDao: schedulesDao,
    );
    return schedulesDao.getAllSchedules(AppIdentity.localUserId);
  }

  Future<MedicationSchedule> addSchedule(MedicationSchedule schedule) async {
    final schedulesDao = await ref.read(medicationSchedulesDaoProvider.future);
    await schedulesDao.insertSchedule(schedule, AppIdentity.localUserId);
    ref.invalidateSelf();
    return schedule;
  }

  Future<void> updateSchedule(MedicationSchedule schedule) async {
    final schedulesDao = await ref.read(medicationSchedulesDaoProvider.future);
    await schedulesDao.updateSchedule(schedule);
    ref.invalidateSelf();
  }

  Future<void> stopSchedule(String id, {DateTime? endDate}) async {
    final schedulesDao = await ref.read(medicationSchedulesDaoProvider.future);
    await schedulesDao.stopSchedule(id, endDate ?? DateTime.now());
    ref.invalidateSelf();
  }

  Future<void> deleteSchedule(String id) async {
    final schedulesDao = await ref.read(medicationSchedulesDaoProvider.future);
    await schedulesDao.deleteSchedule(id);
    ref.invalidateSelf();
  }
}
