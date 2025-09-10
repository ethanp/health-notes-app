import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/services/check_ins_dao.dart';
import 'package:health_notes/services/offline_repository.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/utils/data_utils.dart';

part 'check_ins_provider.g.dart';

@riverpod
class CheckInsNotifier extends _$CheckInsNotifier {
  @override
  Future<List<CheckIn>> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await CheckInsDao.getAllCheckIns(user.id);
  }

  Future<void> addCheckIn(CheckIn checkIn) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final newCheckIn = CheckIn(
      id: DataUtils.uuid.v4(),
      metricName: checkIn.metricName,
      rating: checkIn.rating,
      dateTime: checkIn.dateTime,
      createdAt: DateTime.now(),
    );

    await CheckInsDao.insertCheckIn(newCheckIn, user.id);
    DataUtils.syncService.queueForSync(
      'check_ins',
      newCheckIn.id,
      'insert',
      newCheckIn.toJsonForUpdate(),
    );

    ref.invalidateSelf();
  }

  Future<void> updateCheckIn(CheckIn checkIn) async {
    await CheckInsDao.updateCheckIn(checkIn);
    DataUtils.syncService.queueForSync(
      'check_ins',
      checkIn.id,
      'update',
      checkIn.toJsonForUpdate(),
    );
    ref.invalidateSelf();
  }

  Future<void> deleteCheckIn(String id) async {
    await CheckInsDao.deleteCheckIn(id);
    DataUtils.syncService.queueForSync('check_ins', id, 'delete', {});
    ref.invalidateSelf();
  }

  Future<void> deleteCheckInGroup(List<String> checkInIds) async {
    await CheckInsDao.deleteCheckInGroup(checkInIds);
    for (final id in checkInIds) {
      DataUtils.syncService.queueForSync('check_ins', id, 'delete', {});
    }
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null) {
      await OfflineRepository.syncAllData(user.id);
    }
    ref.invalidateSelf();
  }

  Future<CheckIn?> getCheckInById(String id) async {
    return await CheckInsDao.getCheckInById(id);
  }
}
