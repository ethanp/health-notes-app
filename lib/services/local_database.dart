import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database service for offline storage
class LocalDatabase {
  static const String _databaseName = 'health_notes.db';
  static const int _databaseVersion = 4;

  static Database? _database;

  /// Get the database instance
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_notes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date_time TEXT NOT NULL,
        symptoms_list TEXT NOT NULL,
        drug_doses TEXT NOT NULL,
        notes TEXT NOT NULL,
        applied_tools TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE check_ins (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        metric_name TEXT NOT NULL,
        rating INTEGER NOT NULL,
        date_time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        full_name TEXT NOT NULL,
        avatar_url TEXT,
        updated_at TEXT NOT NULL,
        synced_at TEXT,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE check_in_metrics (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_health_notes_user_id ON health_notes(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_health_notes_date_time ON health_notes(date_time)',
    );
    await db.execute(
      'CREATE INDEX idx_health_notes_sync_status ON health_notes(sync_status)',
    );

    await db.execute(
      'CREATE INDEX idx_check_ins_user_id ON check_ins(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_check_ins_date_time ON check_ins(date_time)',
    );
    await db.execute(
      'CREATE INDEX idx_check_ins_sync_status ON check_ins(sync_status)',
    );

    await db.execute(
      'CREATE INDEX idx_check_in_metrics_user_id ON check_in_metrics(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_check_in_metrics_sort_order ON check_in_metrics(sort_order)',
    );
    await db.execute(
      'CREATE INDEX idx_check_in_metrics_sync_status ON check_in_metrics(sync_status)',
    );

    await db.execute(
      'CREATE INDEX idx_sync_queue_table_name ON sync_queue(table_name)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_created_at ON sync_queue(created_at)',
    );
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE check_in_metrics (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          icon_code_point INTEGER NOT NULL,
          sort_order INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced_at TEXT,
          is_deleted INTEGER DEFAULT 0,
          sync_status TEXT DEFAULT 'pending'
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_check_in_metrics_user_id ON check_in_metrics(user_id)',
      );
      await db.execute(
        'CREATE INDEX idx_check_in_metrics_sort_order ON check_in_metrics(sort_order)',
      );
      await db.execute(
        'CREATE INDEX idx_check_in_metrics_sync_status ON check_in_metrics(sync_status)',
      );
    }

    if (oldVersion < 3) {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_metrics'",
      );

      if (result.isNotEmpty) {
        await db.execute('ALTER TABLE user_metrics RENAME TO check_in_metrics');

        await db.execute('DROP INDEX IF EXISTS idx_user_metrics_user_id');
        await db.execute('DROP INDEX IF EXISTS idx_user_metrics_sort_order');
        await db.execute('DROP INDEX IF EXISTS idx_user_metrics_sync_status');

        await db.execute(
          'CREATE INDEX idx_check_in_metrics_user_id ON check_in_metrics(user_id)',
        );
        await db.execute(
          'CREATE INDEX idx_check_in_metrics_sort_order ON check_in_metrics(sort_order)',
        );
        await db.execute(
          'CREATE INDEX idx_check_in_metrics_sync_status ON check_in_metrics(sync_status)',
        );
      }
    }

    if (oldVersion < 4) {
      final columns = await db.rawQuery("PRAGMA table_info('health_notes')");
      final hasAppliedTools = columns.any(
        (row) => (row['name'] as String?) == 'applied_tools',
      );
      if (!hasAppliedTools) {
        await db.execute(
          "ALTER TABLE health_notes ADD COLUMN applied_tools TEXT NOT NULL DEFAULT '[]'",
        );
      }
    }
  }

  /// Close the database
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Fix any existing data with null updated_at values
  static Future<void> fixNullUpdatedAtValues() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.rawUpdate(
      'UPDATE health_notes SET updated_at = ? WHERE updated_at IS NULL',
      [now],
    );

    await db.rawUpdate(
      'UPDATE check_ins SET updated_at = ? WHERE updated_at IS NULL',
      [now],
    );

    await db.rawUpdate(
      'UPDATE user_profiles SET updated_at = ? WHERE updated_at IS NULL',
      [now],
    );
  }
}

/// Sync status enum
enum SyncStatus { pending, syncing, synced, failed }

/// Extension to convert SyncStatus to/from string
extension SyncStatusExtension on SyncStatus {
  String get value {
    switch (this) {
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.syncing:
        return 'syncing';
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.failed:
        return 'failed';
    }
  }

  static SyncStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return SyncStatus.pending;
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      default:
        return SyncStatus.pending;
    }
  }
}
