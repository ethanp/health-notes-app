import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
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
      duration: AppAnimation.slow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: AppAnimation.curve),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: AppAnimation.slideCurve),
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
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              introIcon(),
              VSpace.xl,
              introTextBlock(),
              VSpace.xxl,
              signInButtonSection(),
              VSpace.m,
              privacyMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget introIcon() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        ),
        child: const Icon(
          CupertinoIcons.heart_fill,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget introTextBlock() {
    final Widget title = Text(
      'Health Notes',
      textAlign: TextAlign.center,
      style: AppTypography.headlineLarge,
    );
    final Widget subtitle = Text(
      'Your personal health companion',
      textAlign: TextAlign.center,
      style: AppTypography.bodyLargeSecondary,
    );
    final Widget briefInfo = Text(
      'Extract insights about your health patterns by performing self-surveys.',
      textAlign: TextAlign.center,
      style: AppTypography.bodyMediumTertiary,
    );
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [title, VSpace.s, subtitle, VSpace.l, briefInfo],
        ),
      ),
    );
  }

  Widget signInButtonSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: signInButton()),
    );
  }

  Widget privacyMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        'Your health data stays private and secure',
        textAlign: TextAlign.center,
        style: AppTypography.captionQuaternary,
      ),
    );
  }

  Widget signInButton() {
    return EnhancedUIComponents.button(
      text: 'Continue with Google',
      onPressed: _isLoading ? () {} : () => signInButtonPressed(),
      isLoading: _isLoading,
      icon: CupertinoIcons.globe,
    );
  }

  Future<void> signInButtonPressed() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signInViaGoogle();
    } catch (e) {
      showSignInFailed(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void showSignInFailed(Object e) {
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => AppAlertDialogs.error(
          title: 'Sign In Failed',
          content: 'Please try again. Error: $e',
        ),
      );
    }
  }
}
