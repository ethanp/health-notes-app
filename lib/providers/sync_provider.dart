import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/providers/user_profile_provider.dart';
import 'package:health_notes/services/connectivity_service.dart';
import 'package:health_notes/services/offline_repository.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_provider.g.dart';

@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  bool build() {
    return false; // Initial sync status
  }

  /// Trigger manual sync
  Future<void> syncAllData() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    state = true;
    try {
      await OfflineRepository.syncAllData(user.id);
      // Invalidate all data providers to refresh with synced data
      _invalidateAllProviders();
    } finally {
      state = false;
    }
  }

  /// Force sync (ignores connectivity)
  Future<void> forceSyncAllData() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    state = true;
    try {
      await OfflineRepository.forceSyncAllData(user.id);
      // Invalidate all data providers to refresh with synced data
      _invalidateAllProviders();
    } finally {
      state = false;
    }
  }

  /// Invalidate all data providers to refresh cached data after sync
  void _invalidateAllProviders() {
    ref.invalidate(healthNotesNotifierProvider);
    ref.invalidate(checkInsNotifierProvider);
    ref.invalidate(checkInMetricsNotifierProvider);
    ref.invalidate(healthToolCategoriesNotifierProvider);
    ref.invalidate(userProfileNotifierProvider);
    ref.invalidate(groupedHealthNotesProvider);
    ref.invalidate(hasCheckInMetricsProvider);
  }
}

@riverpod
bool connectivityStatus(Ref ref) {
  final connectivityService = ConnectivityService();

  // Listen to connectivity changes to make this reactive
  return ref
      .watch(
        StreamProvider<bool>((ref) => connectivityService.connectivityStream),
      )
      .when(
        data: (isConnected) => isConnected,
        loading: () =>
            connectivityService.isConnected, // Fallback to current state
        error: (_, stackTrace) => false,
      );
}
