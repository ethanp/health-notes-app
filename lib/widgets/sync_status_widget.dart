import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

/// Widget that shows sync status and connectivity
class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

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
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.wifi_slash,
                      size: 14,
                      color: CupertinoColors.systemRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Offline',
                      style: AppTheme.caption.copyWith(
                        color: CupertinoColors.systemRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (syncError != null && syncError.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemOrange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      size: 14,
                      color: CupertinoColors.systemOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sync Issue',
                      style: AppTheme.caption.copyWith(
                        color: CupertinoColors.systemOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (syncInProgress || isSyncing) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(radius: 6),
                    const SizedBox(width: 6),
                    Text(
                      'Syncing...',
                      style: AppTheme.caption.copyWith(
                        color: CupertinoColors.systemBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 14,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Synced',
                    style: AppTheme.caption.copyWith(
                      color: CupertinoColors.systemGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

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
