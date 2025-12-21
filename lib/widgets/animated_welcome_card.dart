import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/theme/spacing.dart';

class AnimatedWelcomeCard extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Widget? action;
  final bool showAnimation;

  const AnimatedWelcomeCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.iconColor,
    this.action,
    this.showAnimation = true,
  });

  @override
  State<AnimatedWelcomeCard> createState() => _AnimatedWelcomeCardState();
}

class _AnimatedWelcomeCardState extends State<AnimatedWelcomeCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    if (widget.showAnimation) {
      _pulseController.repeat(reverse: true);
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: AppAnimation.slow,
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _floatAnimation]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value * 4),
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (widget.iconColor ?? AppColors.primary).withValues(
                              alpha: 0.1,
                            ),
                            (widget.iconColor ?? AppColors.primary).withValues(
                              alpha: 0.05,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppRadius.extraLarge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.iconColor ?? AppColors.primary)
                                .withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 64,
                        color: widget.iconColor ?? AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            VSpace.l,
            Text(
              widget.title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            VSpace.m,
            Text(
              widget.message,
              style: AppTypography.bodyMediumSecondary,
              textAlign: TextAlign.center,
            ),
            if (widget.action != null) ...[VSpace.l, widget.action!],
          ],
        ),
      ),
    );
  }
}

class AnimatedProgressCard extends StatefulWidget {
  final String title;
  final String message;
  final double progress;
  final Color? progressColor;
  final IconData? icon;

  const AnimatedProgressCard({
    super.key,
    required this.title,
    required this.message,
    required this.progress,
    this.progressColor,
    this.icon,
  });

  @override
  State<AnimatedProgressCard> createState() => _AnimatedProgressCardState();
}

class _AnimatedProgressCardState extends State<AnimatedProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: AppAnimation.curve,
          ),
        );
    _progressController.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.progress,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: AppAnimation.curve,
            ),
          );
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedUIComponents.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.progressColor ?? AppColors.primary,
                  size: 24,
                ),
                HSpace.s,
              ],
              Expanded(
                child: Text(widget.title, style: AppTypography.labelLarge),
              ),
            ],
          ),
          VSpace.s,
          Text(widget.message, style: AppTypography.bodySmallTertiary),
          VSpace.m,
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: AppTypography.labelMedium.copyWith(
                          color: widget.progressColor ?? AppColors.primary,
                        ),
                      ),
                      Text(
                        '${widget.progress * 100}%',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  VSpace.s,
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundQuaternary,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.progressColor ?? AppColors.primary,
                              (widget.progressColor ?? AppColors.primary)
                                  .withValues(alpha: 0.7),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
