import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sign In Failed'),
            content: Text('Failed to sign in with Google: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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

              const Text(
                'Health Notes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Track your health journey with ease',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),

              const SizedBox(height: 64),

              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(12),
                onPressed: _isLoading ? null : _signInWithGoogle,
                child: _isLoading
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.globe,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              const Text(
                'By signing in, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
