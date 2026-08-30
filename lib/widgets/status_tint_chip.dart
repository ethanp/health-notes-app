import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class const StatusTintChip({
  required final String text,
  required final Color color,
  final IconData? icon,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          Text(text, style: EText.label.small.copyWith(color: color)),
        ],
      ),
    );
  }
}
