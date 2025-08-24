import 'package:flutter/cupertino.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';

class AuthUtils {
  static Future<void> showSignOutDialog(BuildContext context) async {
    final shouldSignOut = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Sign Out', style: AppTheme.titleMedium),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.buttonSecondary),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Sign Out', style: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        final authService = AuthService();
        await authService.signOut();
      } catch (e) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text('Error', style: AppTheme.titleMedium),
              content: Text('Failed to sign out: $e', style: AppTheme.error),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK', style: AppTheme.buttonSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
