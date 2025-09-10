import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:health_notes/services/offline_repository.dart';
import 'package:health_notes/services/connectivity_service.dart';
import 'package:health_notes/providers/auth_provider.dart';

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
    } finally {
      state = false;
    }
  }
}

@riverpod
bool connectivityStatus(Ref ref) {
  final connectivityService = ConnectivityService();
  return connectivityService.isConnected;
}

@riverpod
Stream<bool> connectivityStream(Ref ref) {
  final connectivityService = ConnectivityService();
  return connectivityService.connectivityStream;
}

@riverpod
Stream<bool> syncStatusStream(Ref ref) {
  return OfflineRepository.syncStatusStream;
}

@riverpod
Stream<String?> syncErrorStream(Ref ref) {
  return OfflineRepository.syncErrorStream;
}
