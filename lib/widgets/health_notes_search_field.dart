import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';

class const HealthNotesSearchField({
  required final TextEditingController controller,
  required final String placeholder,
  required final ValueChanged<String> onChanged,
  final VoidCallback? onClear,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.medium,
      curve: AppAnimation.curve,
      decoration: AppComponents.searchField,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: EText.body.medium,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: EText.body.medium.muted,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.sm,
          ),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 18),
                ),
        ),
      ),
    );
  }
}
