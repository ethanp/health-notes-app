import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/app_identity.dart';
import 'package:health_notes/sync/import_legacy_sqlite.dart';
import 'package:health_notes/sync/powersync_schema.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _log = ELogger('HealthNotesSync');

const _fkDependencies = <String, Set<String>>{
  'user_profiles': {},
  'health_notes': {},
  'check_ins': {},
  'check_in_metrics': {},
  'conditions': {},
  'condition_entries': {'conditions'},
  'medication_schedules': {},
  'health_tool_categories': {},
  'health_tools': {'health_tool_categories'},
};

SyncConfig buildHealthNotesSyncConfig(SharedPreferences preferences) {
  return DotEnvSyncBootstrap.build(
    preferences: preferences,
    appName: AppIdentity.syncAppName,
    powersyncPort: 8086,
    postgrestPort: 3009,
    schema: healthNotesSchema,
    upload: UploadSettings(
      strategy: TieredBatchUploadStrategy(dependencies: _fkDependencies),
    ),
    startupHooks: [importLegacySqliteIfNeeded],
    onSyncError: _log.warn,
  );
}
