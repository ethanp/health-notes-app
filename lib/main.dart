import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/app_identity.dart';
import 'package:health_notes/screens/health_notes_home.dart';
import 'package:health_notes/sync/sync_config.dart';

void main() {
  const SyncedAppLaunch(
    appName: AppIdentity.displayName,
    syncConfig: buildHealthNotesSyncConfig,
    home: HealthNotesHome(),
  ).launch();
}
