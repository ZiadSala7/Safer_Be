import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

class TravelLoadingView extends StatefulWidget {
  const TravelLoadingView({
    required this.title,
    this.steps = const [],
    this.subtitle,
    this.badge,
    this.icon,
    this.logoAsset,
    super.key,
  });

  final String title;
  final List<String> steps;
  final String? subtitle;
  final String? badge;
  final IconData? icon;
  final String? logoAsset;

  @override
  State<TravelLoadingView> createState() => _TravelLoadingViewState();
}

class _TravelLoadingViewState extends State<TravelLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _radarController;
  late final AnimationController _rotateController;
  late final AnimationController _stepController;

  late final Animation<double> _pulseScale;
  late final Animation<double> _glowOpacity;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    // Pulse animation (breathing)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowOpacity = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Radar pulse wave animation
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Rotation shimmer ring animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Step timeline animation
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addListener(_onStepTick);

    if (widget.steps.isNotEmpty) {
      _stepController.forward();
    }
  }

  void _onStepTick() {
    if (_stepController.isCompleted && widget.steps.isNotEmpty) {
      if (_currentStep < widget.steps.length - 1) {
        if (mounted) {
          setState(() => _currentStep++);
          _stepController.forward(from: 0);
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _radarController.dispose();
    _rotateController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final resolvedLogo = widget.logoAsset ??
        (isArabic ? AppAssets.logoAr : AppAssets.monochromeLogo);

    final hasSteps = widget.steps.isNotEmpty;
    final progress = hasSteps
        ? ((_currentStep + _stepController.value) / widget.steps.length).clamp(
            0.0,
            1.0,
          )
        : null;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.badge != null && widget.badge!.isNotEmpty) ...[
              _TravelRouteBadge(badge: widget.badge!, icon: widget.icon),
              const SizedBox(height: 24),
            ],

            // Animated Centerpiece Logo
            _AnimatedMonochromeLogo(
              logoAsset: resolvedLogo,
              pulseScale: _pulseScale,
              glowOpacity: _glowOpacity,
              radarAnimation: _radarController,
              rotateAnimation: _rotateController,
              isDark: isDark,
              isArabic: isArabic,
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],

            // Live Steps List
            if (hasSteps) ...[
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.navySoft.withValues(alpha: 0.5)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: List.generate(widget.steps.length, (index) {
                    final isDone = index < _currentStep;
                    final isActive = index == _currentStep;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: AnimatedOpacity(
                        opacity: isActive || isDone ? 1.0 : 0.35,
                        duration: const Duration(milliseconds: 300),
                        child: Row(
                          children: [
                            _StepIndicator(
                              isDone: isDone,
                              isActive: isActive,
                              stepProgress: _stepController.value,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.steps[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onSurface
                                      : (isDone
                                          ? AppColors.teal
                                          : AppColors.muted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              // Linear Gradient Progress Bar
              _GradientProgressBar(progress: progress ?? 0.5),
            ] else ...[
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.teal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedMonochromeLogo extends StatelessWidget {
  const _AnimatedMonochromeLogo({
    required this.logoAsset,
    required this.pulseScale,
    required this.glowOpacity,
    required this.radarAnimation,
    required this.rotateAnimation,
    required this.isDark,
    required this.isArabic,
  });

  final String logoAsset;
  final Animation<double> pulseScale;
  final Animation<double> glowOpacity;
  final Animation<double> radarAnimation;
  final Animation<double> rotateAnimation;
  final bool isDark;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar Expanding Rings
          AnimatedBuilder(
            animation: radarAnimation,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  _RadarRing(
                    progress: radarAnimation.value,
                    maxRadius: 196,
                    color: AppColors.teal,
                  ),
                  _RadarRing(
                    progress: (radarAnimation.value + 0.5) % 1.0,
                    maxRadius: 196,
                    color: AppColors.teal,
                  ),
                ],
              );
            },
          ),

          // Pulsing Ambient Glow
          AnimatedBuilder(
            animation: glowOpacity,
            builder: (context, _) {
              return Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(
                        alpha: 0.38 * glowOpacity.value,
                      ),
                      blurRadius: 44,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: AppColors.orange.withValues(
                        alpha: 0.22 * glowOpacity.value,
                      ),
                      blurRadius: 52,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              );
            },
          ),

          // Rotating Gradient Accent Ring
          AnimatedBuilder(
            animation: rotateAnimation,
            builder: (context, _) {
              return Transform.rotate(
                angle: rotateAnimation.value * 2 * math.pi,
                child: Container(
                  width: 146,
                  height: 146,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.teal.withValues(alpha: 0.0),
                        AppColors.teal,
                        AppColors.orange,
                        AppColors.teal.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Central Logo Badge with Breathing Scale
          ScaleTransition(
            scale: pulseScale,
            child: Container(
              width: 136,
              height: 136,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.navySoft : Colors.white,
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: isDark ? 0.5 : 0.3),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.navy)
                        .withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: _buildLogoImage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoImage() {
    return Image.asset(
      logoAsset,
      fit: BoxFit.contain,
      width: 104,
      height: 104,
      errorBuilder: (context, error, stackTrace) {
        final fallback = isArabic ? AppAssets.logoEn : AppAssets.logoAr;
        return Image.asset(
          fallback,
          fit: BoxFit.contain,
          width: 104,
          height: 104,
          errorBuilder: (context, error2, stackTrace2) {
            return Image.asset(
              'assets/images/app_icon_safer_be.png',
              fit: BoxFit.contain,
              width: 104,
              height: 104,
              errorBuilder: (context, error3, stackTrace3) {
                return const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.teal,
                  size: 48,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RadarRing extends StatelessWidget {
  const _RadarRing({
    required this.progress,
    required this.maxRadius,
    required this.color,
  });

  final double progress;
  final double maxRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 118.0 + (maxRadius - 118.0) * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.35 * opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.isDone,
    required this.isActive,
    required this.stepProgress,
  });

  final bool isDone;
  final bool isActive;
  final double stepProgress;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return const Icon(
        Icons.check_circle_rounded,
        size: 20,
        color: AppColors.teal,
      );
    }
    if (isActive) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          value: stepProgress,
          color: AppColors.orange,
          backgroundColor: AppColors.orange.withValues(alpha: 0.18),
        ),
      );
    }
    return Icon(
      Icons.radio_button_unchecked_rounded,
      size: 20,
      color: AppColors.muted.withValues(alpha: 0.35),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: progress.clamp(0.04, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.teal, AppColors.orange],
            ),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelRouteBadge extends StatelessWidget {
  const _TravelRouteBadge({required this.badge, this.icon});

  final String badge;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.teal),
            const SizedBox(width: 6),
          ],
          Text(
            badge,
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
