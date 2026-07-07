import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        curve: AppAnimation.curve,
        decoration:
            isActive ? AppComponents.activeFilterChip : AppComponents.filterChip,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Text(
          label,
          style:
              isActive ? AppText.label.medium.white : AppText.label.medium,
        ),
      ),
    );
  }
}
