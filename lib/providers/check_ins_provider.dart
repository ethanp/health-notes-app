import 'package:health_notes/app_identity.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/providers/dao_providers.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_ins_provider.g.dart';

@riverpod
class CheckInsNotifier() extends _$CheckInsNotifier {
  @override
  Future<List<CheckIn>> build() async {
    final checkInsDao = await ref.watch(checkInsDaoProvider.future);
    return checkInsDao.getAllCheckIns(AppIdentity.localUserId);
  }

  Future<void> addCheckIn(CheckIn checkIn) async {
    final checkInsDao = await ref.read(checkInsDaoProvider.future);
    final newCheckIn = CheckIn(
      id: DataUtils.uuid.v4(),
      metricName: checkIn.metricName,
      rating: checkIn.rating,
      dateTime: checkIn.dateTime,
      createdAt: DateTime.now(),
    );
    await checkInsDao.insertCheckIn(newCheckIn, AppIdentity.localUserId);
    ref.invalidateSelf();
  }

  Future<void> updateCheckIn(CheckIn checkIn) async {
    final checkInsDao = await ref.read(checkInsDaoProvider.future);
    await checkInsDao.updateCheckIn(checkIn);
    ref.invalidateSelf();
  }

  Future<void> deleteCheckIn(String id) async {
    final entriesDao = await ref.read(conditionEntriesDaoProvider.future);
    final checkInsDao = await ref.read(checkInsDaoProvider.future);
    final linkedEntries = await entriesDao.getEntriesForCheckIn(id);
    for (final entry in linkedEntries) {
      await entriesDao.deleteEntry(entry.id);
    }
    await checkInsDao.deleteCheckIn(id);
    ref.invalidateSelf();
  }

  Future<void> deleteCheckInGroup(List<String> checkInIds) async {
    final entriesDao = await ref.read(conditionEntriesDaoProvider.future);
    final checkInsDao = await ref.read(checkInsDaoProvider.future);
    for (final checkInId in checkInIds) {
      final linkedEntries = await entriesDao.getEntriesForCheckIn(checkInId);
      for (final entry in linkedEntries) {
        await entriesDao.deleteEntry(entry.id);
      }
    }
    await checkInsDao.deleteCheckInGroup(checkInIds);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<CheckIn?> getCheckInById(String id) async {
    final checkInsDao = await ref.read(checkInsDaoProvider.future);
    return checkInsDao.getCheckInById(id);
  }
}
