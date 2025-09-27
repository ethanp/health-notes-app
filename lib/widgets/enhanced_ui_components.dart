import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';

class EnhancedUIComponents {
  static Widget animatedGradientBackground({
    required Widget child,
    Duration duration = AppAnimation.slow,
  }) {
    return AnimatedContainer(
      duration: duration,
      decoration: const BoxDecoration(gradient: AppComponents.backgroundGradient),
      child: child,
    );
  }

  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    bool isElevated = false,
  }) {
    return AnimatedContainer(
      duration: AppAnimation.medium,
      curve: AppAnimation.curve,
      margin: margin ?? const EdgeInsets.all(AppSpacing.m),
      decoration: isElevated ? AppComponents.elevatedCard : AppComponents.primaryCard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.m),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget button({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return AnimatedContainer(
      duration: AppAnimation.fast,
      curve: AppAnimation.curve,
      width: width,
      height: 48,
      decoration: isPrimary ? AppComponents.primaryButton : AppComponents.secondaryButton,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Center(
            child: isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: isPrimary
                              ? CupertinoColors.white
                              : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.s),
                      ],
                      Text(
                        text,
                        style: isPrimary
                            ? AppTypography.buttonPrimary
                            : AppTypography.buttonSecondary,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  static Widget searchField({
    required TextEditingController controller,
    required String placeholder,
    required ValueChanged<String> onChanged,
    VoidCallback? onSuffixTap,
    bool showSuffix = false,
  }) {
    return AnimatedContainer(
      duration: AppAnimation.medium,
      curve: AppAnimation.curve,
      decoration: AppComponents.searchField,
      child: CupertinoSearchTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: AppTypography.inputPlaceholder,
        style: AppTypography.input,
        onChanged: onChanged,
        onSuffixTap: showSuffix ? onSuffixTap : null,
        decoration: const BoxDecoration(),
      ),
    );
  }

  static Widget filterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: AppAnimation.fast,
      curve: AppAnimation.curve,
      decoration: isActive ? AppComponents.activeFilterChip : AppComponents.filterChip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: Text(
              label,
              style: isActive
                  ? AppTypography.labelMedium.copyWith(color: CupertinoColors.white)
                  : AppTypography.labelMedium,
            ),
          ),
        ),
      ),
    );
  }

  static Widget statusIndicator({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpacing.s),
          ],
          Text(text, style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  static Widget sectionHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  static Widget emptyState({
    required String title,
    required String message,
    IconData? icon,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
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
                  borderRadius: BorderRadius.circular(
                    AppRadius.extraLarge,
                  ),
                ),
                child: Icon(icon, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.l),
              action,
            ],
          ],
        ),
      ),
    );
  }

  static Widget loadingIndicator({String? message}) {
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
            const SizedBox(height: AppSpacing.m),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static ObstructingPreferredSizeWidget navigationBar({
    required String title,
    Widget? leading,
    Widget? trailing,
    bool showGradient = true,
  }) {
    return CupertinoNavigationBar(
      middle: Text(title, style: AppTypography.headlineSmall),
      leading: leading,
      trailing: trailing,
      backgroundColor: showGradient
          ? Colors.transparent
          : AppColors.backgroundSecondary,
      border: showGradient
          ? null
          : Border(
              bottom: BorderSide(
                color: AppColors.backgroundQuaternary.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
    );
  }
}

class AppAlertDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? contentWidget;
  final List<AppAlertDialogAction> actions;
  final bool showCancelButton;
  final String? cancelText;

  const AppAlertDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    required this.actions,
    this.showCancelButton = false,
    this.cancelText,
  }) : assert(
         content != null || contentWidget != null,
         'Either content or contentWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final allActions = <CupertinoDialogAction>[];

    allActions.addAll(
      actions.map(
        (action) => CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          isDestructiveAction: action.isDestructive,
          child: Text(action.text),
        ),
      ),
    );

    if (showCancelButton) {
      allActions.add(
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? 'Cancel'),
        ),
      );
    }

    return CupertinoAlertDialog(
      title: Text(title),
      content: contentWidget ?? (content != null ? Text(content!) : null),
      actions: allActions,
    );
  }
}

class AppAlertDialogAction {
  final String text;
  final bool isDestructive;

  const AppAlertDialogAction({required this.text, this.isDestructive = false});
}

class AppAlertDialogs {
  static AppAlertDialog confirmDestructive({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = true,
  }) {
    return AppAlertDialog(
      title: title,
      content: content,
      showCancelButton: true,
      cancelText: cancelText,
      actions: [
        AppAlertDialogAction(text: confirmText, isDestructive: isDestructive),
      ],
    );
  }

  static AppAlertDialog error({
    required String title,
    required String content,
    String okText = 'OK',
  }) {
    return AppAlertDialog(
      title: title,
      content: content,
      actions: [AppAlertDialogAction(text: okText)],
    );
  }

  static AppAlertDialog success({
    required String title,
    required String content,
    String okText = 'OK',
  }) {
    return AppAlertDialog(
      title: title,
      content: content,
      actions: [AppAlertDialogAction(text: okText)],
    );
  }

  static AppAlertDialog custom({
    required String title,
    String? content,
    Widget? contentWidget,
    required List<AppAlertDialogAction> actions,
    bool showCancelButton = false,
    String? cancelText,
  }) {
    return AppAlertDialog(
      title: title,
      content: content,
      contentWidget: contentWidget,
      actions: actions,
      showCancelButton: showCancelButton,
      cancelText: cancelText,
    );
  }
}
