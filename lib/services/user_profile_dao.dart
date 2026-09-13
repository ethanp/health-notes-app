import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/models/user_profile.dart';
import 'package:powersync/powersync.dart';

class UserProfileDao(final PowerSyncDatabase _powerSync) {
  static const _tableName = 'user_profiles';

  Future<UserProfile?> getProfileById(String id) async {
    final profileRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE id = ?',
      [id],
    );
    if (profileRow == null) return null;
    return _mapToUserProfile(profileRow);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await _powerSync.upsert(_tableName, {
      'id': profile.id,
      'email': profile.email,
      'full_name': profile.fullName,
      'avatar_url': profile.avatarUrl,
      'updated_at': profile.updatedAt.toIso8601String(),
    });
  }

  Future<void> updateProfile(UserProfile profile) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET email = ?, full_name = ?, avatar_url = ?, '
      'updated_at = ? WHERE id = ?',
      [profile.email, profile.fullName, profile.avatarUrl, now, profile.id],
    );
  }

  static UserProfile _mapToUserProfile(Map<String, dynamic> profileRow) {
    return UserProfile(
      id: profileRow['id'] as String,
      email: profileRow['email'] as String,
      fullName: profileRow['full_name'] as String,
      avatarUrl: profileRow['avatar_url'] as String?,
      updatedAt: DateTime.parse(profileRow['updated_at'] as String),
    );
  }
}
