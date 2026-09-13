import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

abstract final class ScheduleFormFields() {
  static InputDecoration decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: EText.body.medium.muted,
      filled: true,
      fillColor: EColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: const BorderSide(color: EColors.surfaceRaised),
      ),
    );
  }

  static Widget labeled({
    required String label,
    required TextEditingController controller,
    String? hint,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: EText.label.medium),
        VSpace.s,
        TextField(
          controller: controller,
          style: EText.body.medium,
          decoration: decoration(hint: hint),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
