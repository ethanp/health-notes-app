import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/services/offline_repository.dart';
import 'package:health_notes/theme/app_theme.dart';

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

enum SyncStatusType { loading, syncing, section, error }

/// Unified sync status widget for consistent loading and sync states across the app
class SyncStatusWidget extends ConsumerWidget {
  final SyncStatusType type;
  final String? message;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? child;

  const SyncStatusWidget.loading({super.key, this.message, this.child})
    : type = SyncStatusType.loading,
      errorMessage = null,
      onRetry = null;

  const SyncStatusWidget.syncing({super.key, this.message, this.child})
    : type = SyncStatusType.syncing,
      errorMessage = null,
      onRetry = null;

  const SyncStatusWidget.section({super.key, this.message, this.child})
    : type = SyncStatusType.section,
      errorMessage = null,
      onRetry = null;

  const SyncStatusWidget.error({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.child,
  }) : type = SyncStatusType.error,
       message = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (type) {
      case SyncStatusType.loading:
        return _buildLoadingState();
      case SyncStatusType.syncing:
        return _buildSyncingState(ref);
      case SyncStatusType.section:
        return _buildSectionLoadingState();
      case SyncStatusType.error:
        return _buildErrorState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusExtraLarge),
            ),
            child: const CupertinoActivityIndicator(
              radius: 20,
              color: AppTheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            Text(
              message!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncingState(WidgetRef ref) {
    final isConnected = ref.watch(connectivityStatusProvider);
    final isSyncing = ref.watch(syncNotifierProvider);

    return StreamBuilder<String?>(
      stream: OfflineRepository.syncErrorStream,
      builder: (context, errorSnapshot) {
        final syncError = errorSnapshot.data;

        return Center(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            margin: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isConnected) ...[
                  const Icon(
                    CupertinoIcons.wifi_slash,
                    size: 48,
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No internet connection',
                    style: AppTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Data will sync when connection is restored',
                    style: AppTheme.bodyMedium.copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (syncError != null && syncError.isNotEmpty) ...[
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    size: 48,
                    color: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Sync Error',
                    style: AppTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    syncError,
                    style: AppTheme.bodyMedium.copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    CupertinoButton.filled(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ] else if (isSyncing) ...[
                  const CupertinoActivityIndicator(
                    radius: 24,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Syncing data...',
                    style: AppTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      message!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: CupertinoColors.systemGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ] else ...[
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 48,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Data in sync',
                    style: AppTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (child != null) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  child!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          const CupertinoActivityIndicator(radius: 10),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              message ?? 'Loading...',
              style: AppTheme.bodyMedium.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        margin: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CupertinoColors.systemRed.withValues(alpha: 0.1),
              CupertinoColors.systemRed.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: CupertinoColors.systemRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Error',
              style: AppTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppTheme.spacingS),
              Text(
                errorMessage!,
                style: AppTheme.bodyMedium.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
