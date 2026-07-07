import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isPrimary ? CupertinoColors.white : AppColors.primary;
    final textStyle =
        isPrimary ? AppText.buttonPrimary : AppText.buttonSecondary;

    return SizedBox(
      width: width,
      height: 48,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isLoading ? null : onPressed,
        child: Container(
          decoration: isPrimary
              ? AppComponents.primaryButton
              : AppComponents.secondaryButton,
          child: Center(
            child: isLoading
                ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon!, color: iconColor, size: 20),
                        HSpace.s,
                      ],
                      if (text.isNotEmpty) Text(text, style: textStyle),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
