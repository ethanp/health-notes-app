import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class EnhancedUIComponents {
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
        placeholderStyle: AppText.inputPlaceholder,
        style: AppText.input,
        onChanged: onChanged,
        onSuffixTap: showSuffix ? onSuffixTap : null,
        decoration: const BoxDecoration(),
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
      decoration: AppComponents.tintedDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: color, size: 16), HSpace.s],
          Text(text, style: AppText.label.small.copyWith(color: color)),
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
                Text(title, style: AppText.headline.small),
                if (subtitle != null) ...[
                  VSpace.xs,
                  Text(subtitle, style: AppText.body.small),
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
                  borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                ),
                child: Icon(icon, size: 48, color: AppColors.primary),
              ),
              VSpace.l,
            ],
            Text(
              title,
              style: AppText.headline.medium,
              textAlign: TextAlign.center,
            ),
            VSpace.m,
            Text(
              message,
              style: AppText.body.medium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[VSpace.l, action],
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
            VSpace.m,
            Text(
              message,
              style: AppText.body.medium,
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
      middle: Text(title, style: AppText.headline.small),
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
