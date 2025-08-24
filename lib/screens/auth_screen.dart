import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen();

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                CupertinoIcons.heart_fill,
                size: 80,
                color: CupertinoColors.systemBlue,
              ),

              const SizedBox(height: 32),

              Text(
                'Health Notes',
                textAlign: TextAlign.center,
                style: AppTheme.titleLarge,
              ),

              const SizedBox(height: 8),

              Text(
                'Track your health journey with ease',
                textAlign: TextAlign.center,
                style: AppTheme.subtitle,
              ),

              const SizedBox(height: 64),

              signInButton(),

              const SizedBox(height: 16),

              Text(
                'Look at your health from a more "macro" perspective.',
                textAlign: TextAlign.center,
                style: AppTheme.captionSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget signInButton() {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: CupertinoColors.systemBlue,
      borderRadius: BorderRadius.circular(12),
      onPressed: _isLoading ? null : signInButtonPressed,
      child: _isLoading
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.globe,
                  color: CupertinoColors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Sign in with Google', style: AppTheme.button),
              ],
            ),
    );
  }

  Future<void> signInButtonPressed() async {
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.signInViaGoogle();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Sign In Failed', style: AppTheme.titleMedium),
            content: Text(
              'Failed to sign in with Google: $e',
              style: AppTheme.error,
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: AppTheme.buttonSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
