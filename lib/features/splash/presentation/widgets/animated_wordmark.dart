import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';


class AnimatedWordmark extends StatelessWidget {
  const AnimatedWordmark({
    required this.progress,
    required this.asset,
    required this.darkBackground,
    super.key,
  });

  final double progress;
  final String asset;
  final bool darkBackground;

  @override
  Widget build(BuildContext context) {
    // Phase 1: Smooth Physics Entrance (Scale + Elevation + Opacity)
    final enterScale = _animate(0.06, 0.44, Curves.easeOutCubic);
    final enterSlide = _animate(0.06, 0.44, Curves.easeOutCubic);
    final enterOpacity = _animate(0.04, 0.32, Curves.easeOut);

    // Phase 2: Gentle Atmospheric Halo Pulse
    final haloProgress = _animate(0.15, 0.85, Curves.easeInOut);
    final haloScale = 0.90 + (0.15 * math.sin(haloProgress * math.pi));

    // Phase 3: Premium Light Sweep across the logo
    final shimmerProgress = _animate(0.42, 0.76, Curves.easeInOut);

    // Phase 4: Gentle Floating Hover
    final floatProgress = _animate(0.40, 0.88, Curves.linear);
    final hoverOffset = math.sin(floatProgress * math.pi * 2) * 2.5;

    // Phase 5: Exit Transition
    final exitProgress = _animate(0.90, 1.0, Curves.easeIn);
    final exitFade = 1.0 - exitProgress;
    final exitScale = 1.0 + (0.05 * exitProgress);

    final currentScale = (0.80 + (0.20 * enterScale)) * exitScale;
    final totalOpacity = (enterOpacity * exitFade).clamp(0.0, 1.0);
    final currentSlideY = (16.0 * (1.0 - enterSlide)) + hoverOffset;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = math.min(screenWidth * 0.72, 280.0);

    return Semantics(
      label: 'Safer Be',
      image: true,
      child: Opacity(
        opacity: totalOpacity,
        child: Transform.translate(
          offset: Offset(0, currentSlideY),
          child: Transform.scale(
            scale: currentScale,
            child: SizedBox(
              width: width,
              child: AspectRatio(
                aspectRatio: 2.75,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Ambient Luminous Halo behind the logo
                    Positioned.fill(
                      child: Transform.scale(
                        scale: haloScale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(40),
                            gradient: RadialGradient(
                              colors: darkBackground
                                  ? [
                                      AppColors.tealLight.withValues(alpha: 0.18),
                                      AppColors.orange.withValues(alpha: 0.08),
                                      Colors.transparent,
                                    ]
                                  : [
                                      AppColors.teal.withValues(alpha: 0.08),
                                      AppColors.orange.withValues(alpha: 0.05),
                                      Colors.transparent,
                                    ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Central Crisp Brand Logo with Optional Light Sweep
                    if (shimmerProgress > 0.0 && shimmerProgress < 1.0)
                      ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) {
                          final sweepOffset = -1.2 + (shimmerProgress * 2.4);
                          return LinearGradient(
                            begin: Alignment(sweepOffset - 0.3, -0.3),
                            end: Alignment(sweepOffset + 0.3, 0.3),
                            colors: [
                              Colors.transparent,
                              (darkBackground ? Colors.white : Colors.white)
                                  .withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        child: Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          cacheWidth: (width * 3).round(),
                        ),
                      )
                    else
                      Image.asset(
                        asset,
                        fit: BoxFit.contain,
                        cacheWidth: (width * 3).round(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _animate(double begin, double end, Curve curve) =>
      curve.transform(((progress - begin) / (end - begin)).clamp(0.0, 1.0));
}
