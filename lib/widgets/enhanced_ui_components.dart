import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';

class EnhancedUIComponents {
  // Animated gradient background container
  static Widget animatedGradientBackground({
    required Widget child,
    Duration duration = AppTheme.animationSlow,
  }) {
    return AnimatedContainer(
      duration: duration,
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: child,
    );
  }

  // Enhanced card with hover effects and animations
  static Widget enhancedCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    bool isElevated = false,
  }) {
    return AnimatedContainer(
      duration: AppTheme.animationMedium,
      curve: AppTheme.animationCurve,
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingM),
      decoration: isElevated ? AppTheme.elevatedCard : AppTheme.primaryCard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
            child: child,
          ),
        ),
      ),
    );
  }

  // Enhanced button with gradient and animations
  static Widget enhancedButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return AnimatedContainer(
      duration: AppTheme.animationFast,
      curve: AppTheme.animationCurve,
      width: width,
      height: 48,
      decoration: isPrimary ? AppTheme.primaryButton : AppTheme.secondaryButton,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                              : AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                      ],
                      Text(
                        text,
                        style: isPrimary
                            ? AppTheme.buttonPrimary
                            : AppTheme.buttonSecondary,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Enhanced search field with animations
  static Widget enhancedSearchField({
    required TextEditingController controller,
    required String placeholder,
    required ValueChanged<String> onChanged,
    VoidCallback? onSuffixTap,
    bool showSuffix = false,
  }) {
    return AnimatedContainer(
      duration: AppTheme.animationMedium,
      curve: AppTheme.animationCurve,
      decoration: AppTheme.searchField,
      child: CupertinoSearchTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: AppTheme.inputPlaceholder,
        style: AppTheme.input,
        onChanged: onChanged,
        onSuffixTap: showSuffix ? onSuffixTap : null,
        decoration: const BoxDecoration(),
      ),
    );
  }

  // Enhanced filter chip with animations
  static Widget enhancedFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: AppTheme.animationFast,
      curve: AppTheme.animationCurve,
      decoration: isActive ? AppTheme.activeFilterChip : AppTheme.filterChip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            child: Text(
              label,
              style: isActive
                  ? AppTheme.labelMedium.copyWith(color: CupertinoColors.white)
                  : AppTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced status indicator
  static Widget enhancedStatusIndicator({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppTheme.spacingS),
          ],
          Text(text, style: AppTheme.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  // Enhanced section header
  static Widget enhancedSectionHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(subtitle, style: AppTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Enhanced empty state
  static Widget enhancedEmptyState({
    required String title,
    required String message,
    IconData? icon,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
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
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusExtraLarge,
                  ),
                ),
                child: Icon(icon, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
            Text(
              title,
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // Enhanced loading indicator
  static Widget enhancedLoadingIndicator({String? message}) {
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
              message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Enhanced navigation bar with gradient
  static ObstructingPreferredSizeWidget enhancedNavigationBar({
    required String title,
    Widget? leading,
    Widget? trailing,
    bool showGradient = true,
  }) {
    return CupertinoNavigationBar(
      middle: Text(title, style: AppTheme.headlineSmall),
      leading: leading,
      trailing: trailing,
      backgroundColor: showGradient
          ? Colors.transparent
          : AppTheme.backgroundSecondary,
      border: showGradient
          ? null
          : Border(
              bottom: BorderSide(
                color: AppTheme.backgroundQuaternary.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
    );
  }

  // Enhanced tab bar with animations
  static Widget enhancedTabBar({
    required List<BottomNavigationBarItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundSecondary, AppTheme.backgroundTertiary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.backgroundQuaternary.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoTabBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        activeColor: AppTheme.primary,
        inactiveColor: AppTheme.textTertiary,
      ),
    );
  }
}

// Reusable alert dialog widget to reduce boilerplate
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

    // Add custom actions
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

    // Add cancel button if requested
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

// Convenience methods for common dialog patterns
class AppAlertDialogs {
  // Simple confirmation dialog with OK button
  static AppAlertDialog confirm({
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

  // Custom dialog with multiple actions
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
