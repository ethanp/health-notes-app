import 'dart:io';

import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/app_identity.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

const _logger = ELogger('LegacySqliteImport');
const _importedPrefKey = 'legacy_health_notes_sqlite_imported';
const _legacyFileName = 'health_notes.db';

const _productTables = <String>[
  'health_notes',
  'check_ins',
  'user_profiles',
  'check_in_metrics',
  'conditions',
  'condition_entries',
  'medication_schedules',
];

Future<void> importLegacySqliteIfNeeded(PowerSyncDatabase database) async {
  final preferences = await SharedPreferences.getInstance();
  if (preferences.getBool(_importedPrefKey) == true) return;

  if (await _powerSyncHasAnyRows(database)) {
    await preferences.setBool(_importedPrefKey, true);
    return;
  }

  final legacyFile = await _legacySqliteFile();
  if (legacyFile == null) {
    await preferences.setBool(_importedPrefKey, true);
    return;
  }

  _logger.log('Importing from ${legacyFile.path}');
  final sqlite = sqlite3.open(legacyFile.path, mode: OpenMode.readOnly);
  try {
    await _copyTable(
      sqlite,
      database,
      table: 'user_profiles',
      columns: ['id', 'email', 'full_name', 'avatar_url', 'updated_at'],
      remapUserIdColumn: 'id',
    );
    await _copyTable(
      sqlite,
      database,
      table: 'health_notes',
      columns: [
        'id',
        'user_id',
        'date_time',
        'symptoms_list',
        'drug_doses',
        'notes',
        'applied_tools',
        'created_at',
        'updated_at',
        'is_deleted',
      ],
    );
    await _copyTable(
      sqlite,
      database,
      table: 'check_ins',
      columns: [
        'id',
        'user_id',
        'metric_name',
        'rating',
        'date_time',
        'created_at',
        'updated_at',
        'is_deleted',
      ],
    );
    await _copyTable(
      sqlite,
      database,
      table: 'check_in_metrics',
      columns: [
        'id',
        'user_id',
        'name',
        'type',
        'color_value',
        'icon_code_point',
        'sort_order',
        'created_at',
        'updated_at',
        'is_deleted',
      ],
    );
    await _copyTable(
      sqlite,
      database,
      table: 'conditions',
      columns: [
        'id',
        'user_id',
        'name',
        'start_date',
        'end_date',
        'condition_status',
        'color_value',
        'icon_code_point',
        'notes',
        'created_at',
        'updated_at',
        'is_deleted',
      ],
    );
    await _copyTable(
      sqlite,
      database,
      table: 'condition_entries',
      columns: [
        'id',
        'condition_id',
        'entry_date',
        'severity',
        'phase',
        'notes',
        'linked_check_in_id',
        'created_at',
        'updated_at',
        'is_deleted',
      ],
    );
    await _copyTable(
      sqlite,
      database,
      table: 'medication_schedules',
      columns: [
        'id',
        'user_id',
        'medication_name',
        'unit',
        'start_date',
        'end_date',
        'steps',
        'notes',
        'created_at',
        'updated_at',
        'is_deleted',
      ],
    );
  } finally {
    sqlite.dispose();
  }

  await preferences.setBool(_importedPrefKey, true);
}

Future<bool> _powerSyncHasAnyRows(PowerSyncDatabase database) async {
  for (final table in _productTables) {
    final existing = await database.getOptional('SELECT id FROM $table LIMIT 1');
    if (existing != null) return true;
  }
  return false;
}

Future<File?> _legacySqliteFile() async {
  final documents = await getApplicationDocumentsDirectory();
  final candidates = [
    File(p.join(documents.path, _legacyFileName)),
    File(p.join(documents.path, 'databases', _legacyFileName)),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) return candidate;
  }
  return null;
}

Future<void> _copyTable(
  Database sqlite,
  PowerSyncDatabase powerSync, {
  required String table,
  required List<String> columns,
  String? remapUserIdColumn,
}) async {
  if (!_legacyHasTable(sqlite, table)) return;
  final presentColumns = _legacyColumns(sqlite, table);
  final selected = [
    for (final column in columns)
      if (presentColumns.contains(column)) column,
  ];
  if (selected.isEmpty) return;

  final rows = sqlite.select('SELECT ${selected.join(', ')} FROM $table');
  _logger.log('Importing ${rows.length} $table rows');
  for (final row in rows) {
    final values = <String, Object?>{
      for (final column in selected) column: row[column],
    };
    if (values.containsKey('user_id')) {
      values['user_id'] = AppIdentity.localUserId;
    }
    if (remapUserIdColumn != null) {
      values[remapUserIdColumn] = AppIdentity.localUserId;
    }
    if (columns.contains('is_deleted') && !values.containsKey('is_deleted')) {
      values['is_deleted'] = 0;
    }
    if (columns.contains('applied_tools') &&
        !values.containsKey('applied_tools')) {
      values['applied_tools'] = '[]';
    }
    await powerSync.upsert(table, values);
  }
}

bool _legacyHasTable(Database sqlite, String table) {
  final tables = sqlite.select(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    [table],
  );
  return tables.isNotEmpty;
}

Set<String> _legacyColumns(Database sqlite, String table) {
  return {
    for (final column in sqlite.select('PRAGMA table_info($table)'))
      column['name'] as String,
  };
}
