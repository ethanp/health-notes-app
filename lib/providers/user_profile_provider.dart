import 'package:health_notes/app_identity.dart';
import 'package:health_notes/models/user_profile.dart';
import 'package:health_notes/providers/dao_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_provider.g.dart';

@riverpod
class UserProfileNotifier() extends _$UserProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    final profileDao = await ref.watch(userProfileDaoProvider.future);
    return profileDao.getProfileById(AppIdentity.localUserId);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final profileDao = await ref.read(userProfileDaoProvider.future);
    await profileDao.upsertProfile(profile);
    ref.invalidateSelf();
  }
}
