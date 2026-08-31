import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/onboarding_item.dart';
import 'onboarding_essentials_card.dart';
import 'onboarding_fast_booking_card.dart';
import 'onboarding_inspiration_card.dart';
import 'onboarding_loyalty_card.dart';
import 'onboarding_payment_card.dart';
import 'onboarding_support_card.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.item,
    super.key,
  });

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),

                // Slide Title
                Text(
                  context.tr(item.titleKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Slide Subtitle
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    context.tr(item.subtitleKey),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Interactive Feature Showcase Card
                _buildShowcaseCard(item.type),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShowcaseCard(OnboardingSlideType type) {
    switch (type) {
      case OnboardingSlideType.inspiration:
        return const OnboardingInspirationCard();
      case OnboardingSlideType.support:
        return const OnboardingSupportCard();
      case OnboardingSlideType.fastBooking:
        return const OnboardingFastBookingCard();
      case OnboardingSlideType.loyalty:
        return const OnboardingLoyaltyCard();
      case OnboardingSlideType.payment:
        return const OnboardingPaymentCard();
      case OnboardingSlideType.essentials:
        return const OnboardingEssentialsCard();
    }
  }
}
