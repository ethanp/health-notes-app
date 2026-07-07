import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

class AccentBorderCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const AccentBorderCard({
    super.key,
    required this.accentColor,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 6),
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
