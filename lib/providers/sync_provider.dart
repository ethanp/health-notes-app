import 'package:ethan_sync/ethan_sync.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/providers/medication_schedules_provider.dart';
import 'package:health_notes/providers/user_profile_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_provider.g.dart';

@riverpod
class SyncNotifier() extends _$SyncNotifier {
  @override
  bool build() => false;

  Future<void> syncAllData() async {
    state = true;
    try {
      await ref.read(syncEnsureProvider).ensureConnected();
      _invalidateAllProviders();
    } finally {
      state = false;
    }
  }

  Future<void> forceSyncAllData() async {
    await syncAllData();
  }

  void _invalidateAllProviders() {
    ref.invalidate(healthNotesProvider);
    ref.invalidate(checkInsProvider);
    ref.invalidate(checkInMetricsProvider);
    ref.invalidate(healthToolCategoriesProvider);
    ref.invalidate(healthToolsProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(groupedHealthNotesProvider);
    ref.invalidate(hasCheckInMetricsProvider);
    ref.invalidate(medicationSchedulesProvider);
  }
}

@riverpod
bool connectivityStatus(Ref ref) => !ref.watch(isOfflineProvider);
