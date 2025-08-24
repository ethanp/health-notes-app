import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/providers/user_profile_provider.dart';

class AuthUtils {
  static Future<void> showSignOutDialog(BuildContext context) async {
    final shouldSignOut = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final userProfileAsync = ref.watch(userProfileProvider);

          return userProfileAsync.when(
            data: (userProfile) => CupertinoAlertDialog(
              title: Text('Sign Out', style: AppTheme.headlineSmall),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (userProfile != null) ...[
                    const SizedBox(height: 8),
                    if (userProfile.avatarUrl != null)
                      ClipOval(
                        child: Image.network(
                          userProfile.avatarUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                CupertinoIcons.person_circle_fill,
                                size: 60,
                                color: CupertinoColors.systemGrey,
                              ),
                        ),
                      )
                    else
                      const Icon(
                        CupertinoIcons.person_circle_fill,
                        size: 60,
                        color: CupertinoColors.systemGrey,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      userProfile.fullName,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Are you sure you want to sign out?',
                    style: AppTheme.bodyMedium,
                  ),
                ],
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
            loading: () => CupertinoAlertDialog(
              title: Text('Sign Out', style: AppTheme.headlineSmall),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(height: 16),
                  Text('Loading user information...'),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text('Cancel', style: AppTheme.buttonSecondary),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            error: (error, stack) => CupertinoAlertDialog(
              title: Text('Sign Out', style: AppTheme.headlineSmall),
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
        },
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
              title: Text('Error', style: AppTheme.headlineSmall),
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
