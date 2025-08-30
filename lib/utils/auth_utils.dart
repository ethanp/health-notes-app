import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/providers/user_profile_provider.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';

class AuthUtils {
  static Future<void> showSignOutDialog(BuildContext context) async {
    final shouldSignOut = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final userProfileAsync = ref.watch(userProfileProvider);

          return userProfileAsync.when(
            data: (userProfile) => AppAlertDialogs.custom(
              title: 'Sign Out',
              contentWidget: Column(
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
              showCancelButton: true,
              cancelText: 'Cancel',
              actions: [
                AppAlertDialogAction(text: 'Sign Out', isDestructive: true),
              ],
            ),
            loading: () => AppAlertDialogs.custom(
              title: 'Sign Out',
              contentWidget: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(height: 16),
                  Text('Loading user information...'),
                ],
              ),
              showCancelButton: true,
              cancelText: 'Cancel',
              actions: [],
            ),
            error: (error, stack) => AppAlertDialogs.confirmDestructive(
              title: 'Sign Out',
              content: 'Are you sure you want to sign out?',
              confirmText: 'Sign Out',
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
            builder: (context) => AppAlertDialogs.error(
              title: 'Error',
              content: 'Failed to sign out: $e',
            ),
          );
        }
      }
    }
  }
}
