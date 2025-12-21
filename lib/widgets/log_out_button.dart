import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/auth_utils.dart';

class LogOutButton extends StatelessWidget {
  const LogOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onPressed: () => AuthUtils.showSignOutDialog(context),
      child: Text(
        'Log out',
        style: AppTypography.bodyMedium.copyWith(
          color: CupertinoColors.systemBlue,
        ),
      ),
    );
  }
}


