import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';

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
          duration: AppTheme.animationSlow,
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
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (widget.iconColor ?? AppTheme.primary).withValues(
                              alpha: 0.1,
                            ),
                            (widget.iconColor ?? AppTheme.primary).withValues(
                              alpha: 0.05,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusExtraLarge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.iconColor ?? AppTheme.primary)
                                .withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 64,
                        color: widget.iconColor ?? AppTheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              widget.title,
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              widget.message,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.action != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              widget.action!,
            ],
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
      duration: AppTheme.animationSlow,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: AppTheme.animationCurve,
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
              curve: AppTheme.animationCurve,
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
                  color: widget.progressColor ?? AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
              ],
              Expanded(child: Text(widget.title, style: AppTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            widget.message,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: AppTheme.spacingM),
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
                        style: AppTheme.labelMedium.copyWith(
                          color: widget.progressColor ?? AppTheme.primary,
                        ),
                      ),
                      Text(
                        '${widget.progress * 100}%',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundQuaternary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.progressColor ?? AppTheme.primary,
                              (widget.progressColor ?? AppTheme.primary)
                                  .withValues(alpha: 0.7),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
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
