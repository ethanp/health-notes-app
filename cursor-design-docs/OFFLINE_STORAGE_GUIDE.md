# Offline-First Storage Implementation Guide

This guide explains the offline-first storage system implemented in the Health Notes app, which allows users to interact with their data without an internet connection and automatically syncs when connectivity is restored.

## Architecture Overview

The offline-first system consists of several key components:

### 1. Local Database (SQLite)
- **File**: `lib/services/local_database.dart`
- **Purpose**: Provides local SQLite storage for all app data
- **Features**:
  - Automatic schema creation and migration
  - Indexes for optimal query performance
  - Soft delete support for data integrity
  - Sync status tracking for each record

### 2. Data Access Objects (DAOs)
- **Files**: 
  - `lib/services/health_notes_dao.dart`
  - `lib/services/check_ins_dao.dart`
  - `lib/services/user_profile_dao.dart`
- **Purpose**: Handle all database operations for specific data types
- **Features**:
  - CRUD operations for local data
  - Sync status management
  - Conflict resolution support
  - Server data upserting

### 3. Offline Repository
- **File**: `lib/services/offline_repository.dart`
- **Purpose**: High-level interface for all data operations
- **Features**:
  - Offline-first approach (always saves locally first)
  - Automatic sync queueing
  - UUID generation for new records
  - Unified API for all data types

### 4. Sync Service
- **File**: `lib/services/sync_service.dart`
- **Purpose**: Handles synchronization between local and remote data
- **Features**:
  - Bidirectional sync (pull from server, push local changes)
  - Conflict resolution (server wins for updates)
  - Retry mechanism for failed operations
  - Automatic sync on connectivity restoration

### 5. Connectivity Service
- **File**: `lib/services/connectivity_service.dart`
- **Purpose**: Monitors network connectivity status
- **Features**:
  - Real-time connectivity monitoring
  - Internet reachability verification
  - Stream-based status updates

## How It Works

### Data Flow

1. **User Action**: User creates/updates/deletes data
2. **Local Save**: Data is immediately saved to local SQLite database
3. **Sync Queue**: Operation is queued for synchronization
4. **Background Sync**: When online, queued operations are synced to Supabase
5. **Conflict Resolution**: Server data takes precedence for conflicts

### Sync Strategy

#### Pull (Server → Local)
- Fetches latest data from Supabase
- Compares timestamps to resolve conflicts
- Updates local database with server data
- Marks records as synced

#### Push (Local → Server)
- Processes queued operations
- Sends local changes to Supabase
- Handles authentication and error cases
- Retries failed operations up to 3 times

### Conflict Resolution

The system uses a "server wins" strategy for conflicts:
- If a record exists both locally and on server
- Server version is considered authoritative
- Local changes are overwritten if server version is newer
- Local changes are preserved if they're newer than server version

## Database Schema

### Health Notes Table
```sql
CREATE TABLE health_notes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  date_time TEXT NOT NULL,
  symptoms_list TEXT NOT NULL,
  drug_doses TEXT NOT NULL,
  notes TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  synced_at TEXT,
  is_deleted INTEGER DEFAULT 0,
  sync_status TEXT DEFAULT 'pending'
)
```

### Check Ins Table
```sql
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
```

### User Profiles Table
```sql
CREATE TABLE user_profiles (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  updated_at TEXT NOT NULL,
  synced_at TEXT,
  sync_status TEXT DEFAULT 'pending'
)
```

### Sync Queue Table
```sql
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
```

## Usage Examples

### Adding a Health Note
```dart
await OfflineRepository.addHealthNote(
  userId: user.id,
  dateTime: DateTime.now(),
  symptomsList: [symptom1, symptom2],
  drugDoses: [dose1, dose2],
  notes: "Feeling better today",
);
```

### Manual Sync
```dart
// Sync all data
await OfflineRepository.syncAllData(userId);

// Force sync (ignores connectivity)
await OfflineRepository.forceSyncAllData(userId);
```

### Monitoring Sync Status
```dart
// Watch sync status
ref.watch(syncNotifierProvider);

// Listen to sync stream
OfflineRepository.syncStatusStream.listen((isSyncing) {
  // Handle sync status changes
});
```

## Provider Updates

All existing providers have been updated to use the offline-first approach:

### Health Notes Provider
- Loads data from local database
- Uses `OfflineRepository` for all operations
- Automatically triggers sync on refresh

### Check Ins Provider
- Same offline-first pattern as health notes
- Supports batch operations
- Maintains existing API compatibility

### User Profile Provider
- Loads profile from local storage
- Queues updates for sync
- Handles profile creation and updates

## UI Components

### Sync Status Widget
- Shows current connectivity status
- Displays sync progress
- Provides visual feedback to users

### Compact Sync Status
- Smaller version for app bars
- Icon-based status indication
- Minimal space usage

## Benefits

1. **Offline Functionality**: Users can use the app without internet
2. **Data Persistence**: All data is stored locally and survives app restarts
3. **Automatic Sync**: Changes sync automatically when online
4. **Conflict Resolution**: Handles data conflicts intelligently
5. **Performance**: Local operations are fast and responsive
6. **Reliability**: Retry mechanism ensures data consistency
7. **User Experience**: Seamless transition between online/offline modes

## Configuration

### Dependencies Added
```yaml
dependencies:
  sqflite: ^2.3.3+1          # SQLite database
  path: ^1.9.0               # File path utilities
  connectivity_plus: ^6.0.5  # Network connectivity
  uuid: ^4.5.1               # UUID generation
```

### Initialization
The system is automatically initialized in `main.dart`:
- Local database setup
- Connectivity monitoring
- Sync service initialization

## Troubleshooting

### Common Issues

1. **Sync Not Working**
   - Check internet connectivity
   - Verify Supabase credentials
   - Check sync queue for errors

2. **Data Not Appearing**
   - Ensure local database is initialized
   - Check if data is marked as deleted
   - Verify user authentication

3. **Performance Issues**
   - Monitor database size
   - Check for excessive sync operations
   - Review query performance

### Debugging

Enable debug logging to see sync operations:
```dart
// Add to sync service for debugging
print('Syncing operation: $operation for $tableName');
```

## Future Enhancements

1. **Incremental Sync**: Only sync changed data
2. **Compression**: Compress data for faster sync
3. **Encryption**: Encrypt sensitive local data
4. **Analytics**: Track sync performance and errors
5. **Background Sync**: Sync in background when app is closed

## Migration from Previous Version

The offline storage system is designed to be backward compatible:
- Existing Supabase data is automatically pulled on first sync
- No data loss during migration
- Gradual rollout possible with feature flags

This implementation provides a robust, production-ready offline-first storage solution that ensures users can always access and modify their health data, regardless of network conditions.
