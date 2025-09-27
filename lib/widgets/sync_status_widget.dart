import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/services/offline_repository.dart';

/// Compact sync status indicator for app bars
class CompactSyncStatusWidget extends ConsumerWidget {
  const CompactSyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(connectivityStatusProvider)) {
      return const Icon(
        CupertinoIcons.wifi_slash,
        size: 16,
        color: CupertinoColors.systemRed,
      );
    }
    if (ref.watch(syncNotifierProvider)) {
      return const CupertinoActivityIndicator(radius: 8);
    }

    return StreamBuilder<String?>(
      stream: OfflineRepository.syncErrorStream,
      builder: (context, errorSnapshot) {
        final String? syncError = errorSnapshot.data;
        if (syncError != null && syncError.isNotEmpty) {
          return GestureDetector(
            onTap: () => _showSyncErrorDialog(context, syncError),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 16,
              color: CupertinoColors.systemOrange,
            ),
          );
        }

        return const Icon(
          CupertinoIcons.checkmark_circle_fill,
          size: 16,
          color: CupertinoColors.systemGreen,
        );
      },
    );
  }

  void _showSyncErrorDialog(BuildContext context, String errorMessage) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sync Error'),
        content: Text(errorMessage),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
