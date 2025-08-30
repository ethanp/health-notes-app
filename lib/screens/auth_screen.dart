import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen();

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: AppTheme.animationCurve),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: AppTheme.slideCurve),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedUIComponents.animatedGradientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.1),
                        AppTheme.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusExtraLarge,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.heart_fill,
                    size: 80,
                    color: AppTheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXL),

              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Health Notes',
                        textAlign: TextAlign.center,
                        style: AppTheme.headlineLarge,
                      ),

                      const SizedBox(height: AppTheme.spacingS),

                      Text(
                        'Your personal health companion',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingL),

                      Text(
                        'Track symptoms, medications, and insights to better understand your health patterns',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXXL),

              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: signInButton(),
                ),
              ),

              const SizedBox(height: AppTheme.spacingM),

              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Your health data stays private and secure',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textQuaternary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget signInButton() {
    return EnhancedUIComponents.enhancedButton(
      text: 'Continue with Google',
      onPressed: _isLoading ? () {} : () => signInButtonPressed(),
      isLoading: _isLoading,
      icon: CupertinoIcons.globe,
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
          builder: (context) => AppAlertDialogs.error(
            title: 'Sign In Failed',
            content: 'Please try again. Error: $e',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
