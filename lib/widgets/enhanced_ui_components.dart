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

  // Enhanced list item with animations
  static Widget enhancedListItem({
    required Widget child,
    required VoidCallback onTap,
    EdgeInsetsGeometry? padding,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: AppTheme.animationFast,
          curve: AppTheme.animationCurve,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
                child: child,
              ),
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: AppTheme.spacingM),
            color: AppTheme.backgroundQuaternary.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  // Enhanced navigation bar with gradient
  static PreferredSizeWidget enhancedNavigationBar({
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
