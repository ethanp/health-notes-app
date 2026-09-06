import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/services/offline_repository.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

/// Compact sync status indicator for app bars
class const CompactSyncStatusWidget() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(connectivityStatusProvider)) {
      return const Icon(Icons.wifi_off, size: 16, color: EColors.danger);
    }
    if (ref.watch(syncProvider)) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
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
        child: const Icon(Icons.warning, size: 16, color: EColors.warning),
      );
    }
    return const Icon(Icons.check_circle, size: 16, color: EColors.success);
  }

  void _showSyncErrorDialog(BuildContext context, String errorMessage) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

enum SyncStatusType() {
  loading,
  syncing,
  section,
  error,
}

/// Unified sync status widget for consistent loading and sync states across the app
class SyncStatusWidget extends ConsumerWidget {
  final SyncStatusType type;
  final String? message;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? child;

  const new loading({this.message, this.child})
    : type = SyncStatusType.loading,
      errorMessage = null,
      onRetry = null;

  const new syncing({this.message, this.child})
    : type = SyncStatusType.syncing,
      errorMessage = null,
      onRetry = null;

  const new section({this.message, this.child})
    : type = SyncStatusType.section,
      errorMessage = null,
      onRetry = null;

  const new error({required this.errorMessage, this.onRetry, this.child})
    : type = SyncStatusType.error,
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
                  EColors.accent.withValues(alpha: 0.1),
                  EColors.accent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: EColors.accent),
            ),
          ),
          if (message != null) ...[
            VSpace.m,
            Text(
              message!,
              style: EText.body.medium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncingState(WidgetRef ref) {
    final isConnected = ref.watch(connectivityStatusProvider);
    final isSyncing = ref.watch(syncProvider);

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
                color: EColors.surfaceRaised.withValues(alpha: 0.3),
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
        const Icon(Icons.wifi_off, size: 48, color: EColors.danger),
        VSpace.m,
        Text(
          'No internet connection',
          style: EText.headline.small,
          textAlign: TextAlign.center,
        ),
        VSpace.s,
        Text(
          'Data will sync when connection is restored',
          style: EText.body.medium.muted,
          textAlign: TextAlign.center,
        ),
      ];
    }

    if (syncError != null && syncError.isNotEmpty) {
      return [
        const Icon(Icons.warning, size: 48, color: EColors.warning),
        VSpace.m,
        Text(
          'Sync Error',
          style: EText.headline.small,
          textAlign: TextAlign.center,
        ),
        VSpace.s,
        Text(
          syncError,
          style: EText.body.medium.muted,
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          VSpace.m,
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ];
    }

    if (isSyncing) {
      return [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(color: EColors.accent),
        ),
        VSpace.m,
        Text(
          'Syncing data...',
          style: EText.headline.small,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          VSpace.s,
          Text(
            message!,
            style: EText.body.medium.muted,
            textAlign: TextAlign.center,
          ),
        ],
      ];
    }

    return [
      const Icon(Icons.check_circle, size: 48, color: EColors.success),
      VSpace.m,
      Text(
        'Data in sync',
        style: EText.headline.small,
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
          color: EColors.surfaceRaised.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          HSpace.m,
          Expanded(
            child: Text(
              message ?? 'Loading...',
              style: EText.body.medium.muted,
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
              EColors.danger.withValues(alpha: 0.1),
              EColors.danger.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: EColors.danger.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, size: 48, color: EColors.danger),
            VSpace.m,
            Text(
              'Error',
              style: EText.headline.small,
              textAlign: TextAlign.center,
            ),
            if (errorMessage != null) ...[
              VSpace.s,
              Text(
                errorMessage!,
                style: EText.body.medium.muted,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              VSpace.m,
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
            if (child != null) ...[VSpace.m, child!],
          ],
        ),
      ),
    );
  }
}
