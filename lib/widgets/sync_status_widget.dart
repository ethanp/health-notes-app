import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';

/// Compact sync status indicator for app bars
class CompactSyncStatusWidget extends ConsumerWidget {
  const CompactSyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectivityStatusProvider);
    final isSyncing = ref.watch(syncNotifierProvider);

    return StreamBuilder<String?>(
      stream: ref.watch(syncErrorStreamProvider.future).asStream(),
      builder: (context, errorSnapshot) {
        final syncError = errorSnapshot.data;
        return StreamBuilder<bool>(
          stream: ref.watch(syncStatusStreamProvider.future).asStream(),
          builder: (context, snapshot) {
            final syncInProgress = snapshot.data ?? false;

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
