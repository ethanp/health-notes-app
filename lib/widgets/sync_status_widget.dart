import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/services/offline_repository.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/spacing.dart';

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
      builder: (context, errorSnapshot) =>
          _compactStatusIcon(context, errorSnapshot.data),
    );
  }

  Widget _compactStatusIcon(BuildContext context, String? syncError) {
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
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            ),
            child: const CupertinoActivityIndicator(
              radius: 20,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...[
            VSpace.m,
            Text(
              message!,
              style: AppTypography.bodyMedium,
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
            padding: const EdgeInsets.all(AppSpacing.l),
            margin: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              gradient: AppComponents.cardGradient,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._syncingStateContent(isConnected, isSyncing, syncError),
                if (child != null) ...[VSpace.m, child!],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _syncingStateContent(
    bool isConnected,
    bool isSyncing,
    String? syncError,
  ) {
    if (!isConnected) {
      return [
        const Icon(
          CupertinoIcons.wifi_slash,
          size: 48,
          color: CupertinoColors.systemRed,
        ),
        VSpace.m,
        Text(
          'No internet connection',
          style: AppTypography.headlineSmall,
          textAlign: TextAlign.center,
        ),
        VSpace.s,
        Text(
          'Data will sync when connection is restored',
          style: AppTypography.bodyMediumSystemGrey,
          textAlign: TextAlign.center,
        ),
      ];
    }

    if (syncError != null && syncError.isNotEmpty) {
      return [
        const Icon(
          CupertinoIcons.exclamationmark_triangle_fill,
          size: 48,
          color: CupertinoColors.systemOrange,
        ),
        VSpace.m,
        Text(
          'Sync Error',
          style: AppTypography.headlineSmall,
          textAlign: TextAlign.center,
        ),
        VSpace.s,
        Text(
          syncError,
          style: AppTypography.bodyMediumSystemGrey,
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          VSpace.m,
          CupertinoButton.filled(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ];
    }

    if (isSyncing) {
      return [
        const CupertinoActivityIndicator(radius: 24, color: AppColors.primary),
        VSpace.m,
        Text(
          'Syncing data...',
          style: AppTypography.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          VSpace.s,
          Text(
            message!,
            style: AppTypography.bodyMediumSystemGrey,
            textAlign: TextAlign.center,
          ),
        ],
      ];
    }

    return [
      const Icon(
        CupertinoIcons.checkmark_circle_fill,
        size: 48,
        color: CupertinoColors.systemGreen,
      ),
      VSpace.m,
      Text(
        'Data in sync',
        style: AppTypography.headlineSmall,
        textAlign: TextAlign.center,
      ),
    ];
  }

  Widget _buildSectionLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppComponents.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          const CupertinoActivityIndicator(radius: 10),
          HSpace.m,
          Expanded(
            child: Text(
              message ?? 'Loading...',
              style: AppTypography.bodyMediumSystemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        margin: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CupertinoColors.systemRed.withValues(alpha: 0.1),
              CupertinoColors.systemRed.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.medium),
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
            VSpace.m,
            Text(
              'Error',
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (errorMessage != null) ...[
              VSpace.s,
              Text(
                errorMessage!,
                style: AppTypography.bodyMediumSystemGrey,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              VSpace.m,
              CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
            if (child != null) ...[VSpace.m, child!],
          ],
        ),
      ),
    );
  }
}
