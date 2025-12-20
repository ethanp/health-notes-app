import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:health_notes/services/check_in_metrics_dao.dart';
import 'package:health_notes/services/check_ins_dao.dart';
import 'package:health_notes/services/condition_entries_dao.dart';
import 'package:health_notes/services/conditions_dao.dart';
import 'package:health_notes/services/health_notes_dao.dart';
import 'package:health_notes/services/local_database.dart';
import 'package:health_notes/services/user_profile_dao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for syncing local data with Supabase
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _syncStatusController = StreamController<bool>.broadcast();
  final _syncErrorController = StreamController<String?>.broadcast();
  bool _isSyncing = false;

  /// Stream of sync status changes (true means it isSyncing)
  Stream<bool> get syncStatusStream => _syncStatusController.stream;

  /// Whether sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Stream of sync error messages (null means no error)
  Stream<String?> get syncErrorStream => _syncErrorController.stream;

  /// Check if device is connected to internet
  Future<bool> _isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isEmpty ||
          connectivityResult.first == ConnectivityResult.none) {
        return false;
      }

      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Queue an operation for sync
  Future<void> queueForSync(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    if (!await _isConnected()) {
      await _addToSyncQueue(tableName, recordId, operation, data);
      return;
    }
    try {
      await _syncOperation(tableName, recordId, operation, data);
    } catch (e) {
      await _addToSyncQueue(tableName, recordId, operation, data);
      _emitSyncError(
        'Failed to sync now ($tableName:$recordId): ${e.toString()}',
      );
    }
  }

  Future<void> _addToSyncQueue(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    final db = await LocalDatabase.database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  /// Sync a single operation
  Future<void> _syncOperation(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final supabase = Supabase.instance.client;

    switch (tableName) {
      case 'health_notes':
        await _syncHealthNoteOperation(
          supabase,
          user.id,
          recordId,
          operation,
          data,
        );
        break;
      case 'check_ins':
        await _syncCheckInOperation(
          supabase,
          user.id,
          recordId,
          operation,
          data,
        );
        break;
      case 'user_profiles':
        await _syncUserProfileOperation(supabase, recordId, operation, data);
        break;
      case 'check_in_metrics':
        await _syncCheckInMetricOperation(
          supabase,
          user.id,
          recordId,
          operation,
          data,
        );
        break;
      case 'user_metrics': // For backward compatibility
        await _syncCheckInMetricOperation(
          supabase,
          user.id,
          recordId,
          operation,
          data,
        );
        break;
      case 'conditions':
        await _syncConditionOperation(
          supabase,
          user.id,
          recordId,
          operation,
          data,
        );
        break;
      case 'condition_entries':
        await _syncConditionEntryOperation(
          supabase,
          recordId,
          operation,
          data,
        );
        break;
    }
  }

  void _emitSyncError(String message) {
    _syncErrorController.add(message);
  }

  /// Sync health note operation
  Future<void> _syncHealthNoteOperation(
    SupabaseClient supabase,
    String userId,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'insert':
        await supabase.from('health_notes').insert({
          'id': recordId,
          'user_id': userId,
          ...data,
        });
        await HealthNotesDao.markAsSynced(recordId);
        break;

      case 'update':
        await supabase
            .from('health_notes')
            .update(data)
            .eq('id', recordId)
            .eq('user_id', userId);
        await HealthNotesDao.markAsSynced(recordId);
        break;

      case 'delete':
        await supabase
            .from('health_notes')
            .delete()
            .eq('id', recordId)
            .eq('user_id', userId);
        await HealthNotesDao.markAsSynced(recordId);
        break;
    }
  }

  /// Sync check-in metric operation
  Future<void> _syncCheckInMetricOperation(
    SupabaseClient supabase,
    String userId,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'upsert':
        await supabase.from('check_in_metrics').upsert({
          'id': recordId,
          'user_id': userId,
          ...data,
        });
        await CheckInMetricsDao.markAsSynced(recordId);
        break;
      case 'insert':
        await supabase.from('check_in_metrics').insert({
          'id': recordId,
          'user_id': userId,
          ...data,
        });
        await CheckInMetricsDao.markAsSynced(recordId);
        break;

      case 'update':
        await supabase
            .from('check_in_metrics')
            .update(data)
            .eq('id', recordId)
            .eq('user_id', userId);
        await CheckInMetricsDao.markAsSynced(recordId);
        break;

      case 'delete':
        await supabase
            .from('check_in_metrics')
            .delete()
            .eq('id', recordId)
            .eq('user_id', userId);
        await CheckInMetricsDao.markAsSynced(recordId);
        break;
    }
  }

  /// Sync check in operation
  Future<void> _syncCheckInOperation(
    SupabaseClient supabase,
    String userId,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'insert':
        await supabase.from('check_ins').insert({
          'id': recordId,
          'user_id': userId,
          ...data,
        });
        await CheckInsDao.markAsSynced(recordId);
        break;

      case 'update':
        await supabase
            .from('check_ins')
            .update(data)
            .eq('id', recordId)
            .eq('user_id', userId);
        await CheckInsDao.markAsSynced(recordId);
        break;

      case 'delete':
        await supabase
            .from('check_ins')
            .delete()
            .eq('id', recordId)
            .eq('user_id', userId);
        await CheckInsDao.markAsSynced(recordId);
        break;
    }
  }

  /// Sync user profile operation
  Future<void> _syncUserProfileOperation(
    SupabaseClient supabase,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'upsert':
        await supabase.from('profiles').upsert({
          'id': recordId,
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        });
        await UserProfileDao.markAsSynced(recordId);
        break;
    }
  }

  /// Sync condition operation
  Future<void> _syncConditionOperation(
    SupabaseClient supabase,
    String userId,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'insert':
        await supabase.from('conditions').insert({
          'id': recordId,
          'user_id': userId,
          ...data,
        });
        await ConditionsDao.markAsSynced(recordId);
        break;

      case 'update':
        await supabase
            .from('conditions')
            .update(data)
            .eq('id', recordId)
            .eq('user_id', userId);
        await ConditionsDao.markAsSynced(recordId);
        break;

      case 'delete':
        await supabase
            .from('conditions')
            .delete()
            .eq('id', recordId)
            .eq('user_id', userId);
        await ConditionsDao.markAsSynced(recordId);
        break;
    }
  }

  /// Sync condition entry operation
  Future<void> _syncConditionEntryOperation(
    SupabaseClient supabase,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'insert':
        await supabase.from('condition_entries').insert({
          'id': recordId,
          ...data,
        });
        await ConditionEntriesDao.markAsSynced(recordId);
        break;

      case 'update':
        await supabase
            .from('condition_entries')
            .update(data)
            .eq('id', recordId);
        await ConditionEntriesDao.markAsSynced(recordId);
        break;

      case 'delete':
        await supabase
            .from('condition_entries')
            .delete()
            .eq('id', recordId);
        await ConditionEntriesDao.markAsSynced(recordId);
        break;
    }
  }

  /// Sync all pending operations
  Future<void> syncAllData(String userId) async {
    if (_isSyncing || !await _isConnected()) return;

    _isSyncing = true;
    _syncStatusController.add(true);

    try {
      try {
        await _pullLatestData(userId);
      } catch (e) {
        // Pull failed - continue with push
      }
      await _pushLocalChanges();
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
      _syncErrorController.add(null);
    }
  }

  /// Force sync all data (ignores connectivity check)
  Future<void> forceSyncAllData(String userId) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(true);

    try {
      try {
        await _pullLatestData(userId);
      } catch (e) {
        // Pull failed - continue with push
      }
      await _pushLocalChanges();
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
      _syncErrorController.add(null);
    }
  }

  /// Push local changes only (no pull). Useful after local cleanup to delete
  /// duplicates on server before pulling fresh data.
  Future<void> pushLocalOnly() async {
    if (_isSyncing || !await _isConnected()) return;

    _isSyncing = true;
    _syncStatusController.add(true);

    try {
      await _pushLocalChanges();
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
      _syncErrorController.add(null);
    }
  }

  /// Pull latest data from server
  Future<void> _pullLatestData(String userId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final supabase = Supabase.instance.client;

    try {
      final healthNotesResponse = await supabase
          .from('health_notes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      for (final noteData in healthNotesResponse) {
        await HealthNotesDao.upsertFromServer(noteData, userId);
      }

      final checkInsResponse = await supabase
          .from('check_ins')
          .select()
          .eq('user_id', userId)
          .order('date_time', ascending: false);

      for (final checkInData in checkInsResponse) {
        await CheckInsDao.upsertFromServer(checkInData, userId);
      }

      try {
        final profileResponse = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        await UserProfileDao.upsertFromServer(profileResponse);
      } catch (e) {
        // Profile sync failed - not critical
      }

      final metricsResponse = await supabase
          .from('check_in_metrics')
          .select()
          .eq('user_id', userId)
          .order('sort_order', ascending: true);

      for (final metricData in metricsResponse) {
        await CheckInMetricsDao.upsertFromServer(metricData);
      }

      final conditionsResponse = await supabase
          .from('conditions')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false);

      for (final conditionData in conditionsResponse) {
        await ConditionsDao.upsertFromServer(conditionData, userId);
      }

      final conditionEntriesResponse = await supabase
          .from('condition_entries')
          .select()
          .order('entry_date', ascending: false);

      for (final entryData in conditionEntriesResponse) {
        await ConditionEntriesDao.upsertFromServer(entryData);
      }
    } catch (e) {
      _emitSyncError('Error pulling latest data: ${e.toString()}');
      rethrow;
    }
  }

  /// Push local changes to server
  Future<void> _pushLocalChanges() async {
    final db = await LocalDatabase.database;

    final orphanMetrics = await CheckInMetricsDao.getPendingSyncMetrics();
    for (final m in orphanMetrics) {
      try {
        final data = <String, dynamic>{
          'user_id': m['user_id'],
          'name': m['name'],
          'type': m['type'],
          'color_value': m['color_value'],
          'icon_code_point': m['icon_code_point'],
          'sort_order': m['sort_order'],
        };
        await _syncOperation(
          'check_in_metrics',
          m['id'] as String,
          'upsert',
          data,
        );
      } catch (e) {
        _emitSyncError('Error syncing check_in_metrics:${m['id']}: $e');
      }
    }

    final pendingOps = await db.query('sync_queue', orderBy: 'created_at ASC');

    for (final op in pendingOps) {
      try {
        final data = jsonDecode(op['data'] as String) as Map<String, dynamic>;
        await _syncOperation(
          op['table_name'] as String,
          op['record_id'] as String,
          op['operation'] as String,
          data,
        );

        await db.delete('sync_queue', where: 'id = ?', whereArgs: [op['id']]);
      } catch (e) {
        final retryCount = (op['retry_count'] as int) + 1;
        await db.update(
          'sync_queue',
          {'retry_count': retryCount, 'last_error': e.toString()},
          where: 'id = ?',
          whereArgs: [op['id']],
        );

        if (retryCount >= 3) {
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [op['id']]);
        }

        _emitSyncError(
          'Error syncing ${op['table_name'] as String}:${op['record_id'] as String}: ${e.toString()}',
        );
      }
    }
  }

  /// Start automatic sync when connectivity is restored
  void startAutoSync(String userId) {
    Connectivity().onConnectivityChanged
        .cast<List<ConnectivityResult>>()
        .listen((List<ConnectivityResult> results) {
          if (results.isNotEmpty &&
              results.any((r) => r != ConnectivityResult.none)) {
            syncAllData(userId);
          }
        });
  }

  /// Stop auto sync
  void stopAutoSync() {}

  /// Dispose resources
  void dispose() {
    _syncStatusController.close();
    _syncErrorController.close();
  }
}
