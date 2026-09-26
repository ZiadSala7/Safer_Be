import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    required this.currentIndex,
    required this.totalSlides,
    required this.accentColor,
    required this.onSkip,
    required this.onSelectSlide,
    super.key,
  });

  final int currentIndex;
  final int totalSlides;
  final Color accentColor;
  final VoidCallback onSkip;
  final ValueChanged<int> onSelectSlide;

  @override
  Widget build(BuildContext context) {
    final app = AppControllerScope.of(context);
    final isArabic = context.l10n.isArabic;
    final isLast = currentIndex == totalSlides - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Segmented Story Progress Bar
          Row(
            children: List.generate(totalSlides, (index) {
              final isPassed = index < currentIndex;
              final isActive = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelectSlide(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 18,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: isActive ? 4.5 : 3.5,
                      decoration: BoxDecoration(
                        color: isActive
                            ? accentColor
                            : isPassed
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Controls Row: Language Switcher, Centered Safer Be Logo & Skip/Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Language Switcher Glass Pill
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: app.toggleLocale,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.tr('language'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Safer Be Logo Watermark Capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  AppAssets.getLogo(
                    isDark: true,
                    isArabic: isArabic,
                    withoutBackground: true,
                  ),
                  height: 22,
                  fit: BoxFit.contain,
                  cacheHeight: 66,
                ),
              ),

              // Skip / Close Button
              if (!isLast)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSkip,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('skip'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 60),
            ],
          ),
        ],
      ),
    );
  }
}
