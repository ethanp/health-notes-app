import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

enum SyncStatusType() {
  loading,
  syncing,
  section,
  error,
}

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
    return switch (type) {
      SyncStatusType.loading => _loadingState(),
      SyncStatusType.syncing => _syncingState(ref),
      SyncStatusType.section => _sectionLoadingState(),
      SyncStatusType.error => _errorState(),
    };
  }

  Widget _loadingState() {
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

  Widget _syncingState(WidgetRef ref) {
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
            const ESyncPhaseIcon(),
            VSpace.m,
            Text(
              ref.watch(syncStatusCaptionProvider),
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
            if (child != null) ...[VSpace.m, child!],
          ],
        ),
      ),
    );
  }

  Widget _sectionLoadingState() {
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

  Widget _errorState() {
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
