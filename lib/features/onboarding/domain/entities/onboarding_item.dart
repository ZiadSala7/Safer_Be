import 'package:flutter/material.dart';

enum OnboardingSlideType {
  inspiration,
  support,
  fastBooking,
  loyalty,
  payment,
  essentials,
}

class OnboardingItem {
  const OnboardingItem({
    required this.type,
    required this.titleKey,
    required this.subtitleKey,
    required this.gradientColors,
    required this.accentColor,
    this.badgeKey,
    this.image = '',
  });

  final OnboardingSlideType type;
  final String titleKey;
  final String subtitleKey;
  final List<Color> gradientColors;
  final Color accentColor;
  final String? badgeKey;
  final String image;
}
