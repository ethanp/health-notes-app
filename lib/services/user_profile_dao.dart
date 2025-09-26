import 'package:sqflite/sqflite.dart';
import 'package:health_notes/models/user_profile.dart';
import 'package:health_notes/services/local_database.dart';

/// Data Access Object for User Profile
class UserProfileDao {
  static const String _tableName = 'user_profiles';

  /// Get user profile by ID
  static Future<UserProfile?> getProfileById(String id) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToUserProfile(maps.first);
  }

  /// Insert or update user profile
  static Future<void> upsertProfile(UserProfile profile) async {
    final db = await LocalDatabase.database;

    await db.insert(_tableName, {
      'id': profile.id,
      'email': profile.email,
      'full_name': profile.fullName,
      'avatar_url': profile.avatarUrl,
      'updated_at': profile.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.pending.value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update user profile
  static Future<void> updateProfile(UserProfile profile) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'email': profile.email,
        'full_name': profile.fullName,
        'avatar_url': profile.avatarUrl,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Get profiles that need to be synced
  static Future<List<Map<String, dynamic>>> getPendingSyncProfiles() async {
    final db = await LocalDatabase.database;
    return await db.query(
      _tableName,
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
    );
  }

  /// Mark a profile as synced
  static Future<void> markAsSynced(String id) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {'sync_status': SyncStatus.synced.value, 'synced_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Upsert a profile from server (for sync)
  static Future<void> upsertFromServer(Map<String, dynamic> serverData) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(_tableName, {
      'id': serverData['id'],
      'email': serverData['email'],
      'full_name': serverData['full_name'],
      'avatar_url': serverData['avatar_url'],
      'updated_at': serverData['updated_at'] ?? now,
      'sync_status': SyncStatus.synced.value,
      'synced_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Convert UserProfile object to sync map (for queueForSync)
  static Map<String, dynamic> toSyncMap(UserProfile profile) {
    return {
      'email': profile.email,
      'full_name': profile.fullName,
      'avatar_url': profile.avatarUrl,
    };
  }

  /// Convert database map to UserProfile object
  static UserProfile _mapToUserProfile(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      email: map['email'],
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
