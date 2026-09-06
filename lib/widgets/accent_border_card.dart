import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';

class const AccentBorderCard({
  required final Color accentColor,
  required final Widget child,
  final VoidCallback? onTap,
  final EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 6),
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
