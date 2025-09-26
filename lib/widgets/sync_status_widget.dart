import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/services/offline_repository.dart';

/// Compact sync status indicator for app bars
class CompactSyncStatusWidget extends ConsumerWidget {
  const CompactSyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectivityStatusProvider);
    final isSyncing = ref.watch(syncNotifierProvider);

    return StreamBuilder<String?>(
      stream: OfflineRepository.syncErrorStream,
      builder: (context, errorSnapshot) {
        final String? syncError = errorSnapshot.data;

        return StreamBuilder<bool>(
          stream: OfflineRepository.syncStatusStream,
          builder: (context, syncSnapshot) {
            final bool syncInProgress = syncSnapshot.data ?? false;

            if (!isConnected) {
              return const Icon(
                CupertinoIcons.wifi_slash,
                size: 16,
                color: CupertinoColors.systemRed,
              );
            }

            if (syncError != null && syncError.isNotEmpty) {
              return const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 16,
                color: CupertinoColors.systemOrange,
              );
            }

            if (syncInProgress || isSyncing) {
              return const CupertinoActivityIndicator(radius: 8);
            }

            return const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 16,
              color: CupertinoColors.systemGreen,
            );
          },
        );
      },
    );
  }
}
