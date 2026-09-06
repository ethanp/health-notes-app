import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';

class const AppFilterChip({
  required final String label,
  required final bool isActive,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        curve: AppAnimation.curve,
        decoration: isActive
            ? AppComponents.activeFilterChip
            : AppComponents.filterChip,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Text(
          label,
          style: isActive ? EText.label.medium.white : EText.label.medium,
        ),
      ),
    );
  }
}
