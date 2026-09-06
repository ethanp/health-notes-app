import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/services/auth_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/app_dialogs.dart';

class const AuthScreen() extends ConsumerStatefulWidget {
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState()
    extends ConsumerState<AuthScreen>
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
    return AnimatedContainer(
      duration: AppAnimation.slow,
      decoration: const BoxDecoration(gradient: EColors.scaffoldGradient),
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
              EColors.accent.withValues(alpha: 0.1),
              EColors.accent.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        ),
        child: const Icon(
          Icons.favorite,
          size: 80,
          color: EColors.accent,
        ),
      ),
    );
  }

  Widget introTextBlock() {
    final Widget title = Text(
      'Health Notes',
      textAlign: TextAlign.center,
      style: EText.headline.large,
    );
    final Widget subtitle = Text(
      'Your personal health companion',
      textAlign: TextAlign.center,
      style: EText.body.large.secondary,
    );
    final Widget briefInfo = Text(
      'Extract insights about your health patterns by performing self-surveys.',
      textAlign: TextAlign.center,
      style: EText.body.medium.tertiary,
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
        style: EText.caption.quaternary,
      ),
    );
  }

  Widget signInButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : signInButtonPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.public),
        label: const Text('Continue with Google'),
      ),
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
      showDialog(
        context: context,
        builder: (context) => AppAlertDialogs.error(
          title: 'Sign In Failed',
          content: 'Please try again. Error: $e',
        ),
      );
    }
  }
}
