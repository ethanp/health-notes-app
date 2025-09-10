import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_notes/models/user_profile.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/services/user_profile_dao.dart';
import 'package:health_notes/utils/data_utils.dart';

part 'user_profile_provider.g.dart';

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) return null;

    return await UserProfileDao.getProfileById(user.id);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await UserProfileDao.upsertProfile(profile);
    DataUtils.syncService.queueForSync(
      'user_profiles',
      profile.id,
      'upsert',
      UserProfileDao.toSyncMap(profile),
    );
    ref.invalidateSelf();
  }
}
