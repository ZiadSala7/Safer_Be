import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingPaymentCard extends StatelessWidget {
  const OnboardingPaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      AppAssets.brandSymbol,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.payment_rounded,
                        color: AppColors.teal,
                        size: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr('onboardingPaymentHeader'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Icon(Icons.lock_outline_rounded, color: Color(0xFF16A34A), size: 13),
                const SizedBox(width: 3),
                Text(
                  context.tr('secure'),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Option 1: Apple Pay (Selected)
                _PaymentMethodTile(
                  title: context.tr('onboardingPayWithApplePay'),
                  subtitle: '',
                  icon: Icons.apple_rounded,
                  iconColor: Colors.black,
                  isSelected: true,
                ),
                const SizedBox(height: 5),

                // Option 2: Credit or Debit Card (Mada, Visa, Mastercard)
                _PaymentMethodTile(
                  title: context.tr('onboardingCreditOrDebitCard'),
                  subtitle: 'Mada, Visa, Mastercard',
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFF2563EB),
                  isSelected: false,
                ),
                const SizedBox(height: 5),

                // Option 3: Tabby
                _PaymentMethodTile(
                  title: context.tr('onboardingTabby'),
                  subtitle: context.tr('onboardingTabbyDesc'),
                  icon: Icons.splitscreen_rounded,
                  iconColor: const Color(0xFF059669),
                  isSelected: false,
                ),
                const SizedBox(height: 5),

                // Option 4: Tamara
                _PaymentMethodTile(
                  title: context.tr('onboardingTamara'),
                  subtitle: context.tr('onboardingTamaraDesc'),
                  icon: Icons.shopping_bag_outlined,
                  iconColor: const Color(0xFFEA580C),
                  isSelected: false,
                ),
                const SizedBox(height: 8),

                // Apple Pay Quick Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apple_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('onboardingApplePayBtn'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            size: 15,
            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}
