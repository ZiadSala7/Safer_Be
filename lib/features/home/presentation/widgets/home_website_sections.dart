import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/domain/entities/flight_search.dart';
import '../../../search/presentation/pages/flight_results_page.dart';

class PopularRouteItem {
  const PopularRouteItem({
    required this.fromCode,
    required this.toCode,
    required this.fromNameAr,
    required this.toNameAr,
    required this.fromNameEn,
    required this.toNameEn,
    required this.priceHint,
  });

  final String fromCode;
  final String toCode;
  final String fromNameAr;
  final String toNameAr;
  final String fromNameEn;
  final String toNameEn;
  final String priceHint;
}

const popularFlightRoutes = [
  PopularRouteItem(
    fromCode: 'RUH',
    toCode: 'DXB',
    fromNameAr: 'الرياض',
    toNameAr: 'دبي',
    fromNameEn: 'Riyadh',
    toNameEn: 'Dubai',
    priceHint: '380 SAR',
  ),
  PopularRouteItem(
    fromCode: 'JED',
    toCode: 'CAI',
    fromNameAr: 'جدة',
    toNameAr: 'القاهرة',
    fromNameEn: 'Jeddah',
    toNameEn: 'Cairo',
    priceHint: '420 SAR',
  ),
  PopularRouteItem(
    fromCode: 'DMM',
    toCode: 'BAH',
    fromNameAr: 'الدمام',
    toNameAr: 'المنامة',
    fromNameEn: 'Dammam',
    toNameEn: 'Manama',
    priceHint: '290 SAR',
  ),
  PopularRouteItem(
    fromCode: 'RUH',
    toCode: 'LHR',
    fromNameAr: 'الرياض',
    toNameAr: 'لندن',
    fromNameEn: 'Riyadh',
    toNameEn: 'London',
    priceHint: '1,150 SAR',
  ),
  PopularRouteItem(
    fromCode: 'JED',
    toCode: 'DXB',
    fromNameAr: 'جدة',
    toNameAr: 'دبي',
    fromNameEn: 'Jeddah',
    toNameEn: 'Dubai',
    priceHint: '395 SAR',
  ),
  PopularRouteItem(
    fromCode: 'RUH',
    toCode: 'IST',
    fromNameAr: 'الرياض',
    toNameAr: 'إسطنبول',
    fromNameEn: 'Riyadh',
    toNameEn: 'Istanbul',
    priceHint: '650 SAR',
  ),
];

class PopularRoutesSection extends StatelessWidget {
  const PopularRoutesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('popularRoutes'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('popularRoutesDesc'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 106,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: popularFlightRoutes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final route = popularFlightRoutes[index];
              return _PopularRouteCard(
                route: route,
                isAr: isAr,
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PopularRouteCard extends StatelessWidget {
  const _PopularRouteCard({
    required this.route,
    required this.isAr,
    required this.isDark,
  });

  final PopularRouteItem route;
  final bool isAr;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          String currency = 'SAR';
          try {
            currency = AppControllerScope.of(context).currency;
          } catch (_) {}

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlightResultsPage(
                search: FlightSearch(
                  origin: route.fromCode,
                  destination: route.toCode,
                  departure: DateTime.now().add(const Duration(days: 3)),
                  currency: currency,
                ),
              ),
            ),
          );
        },
        child: Container(
          width: 175,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : AppColors.teal.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    route.fromCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.flight_takeoff_rounded,
                      size: 14,
                      color: AppColors.orange,
                    ),
                  ),
                  Text(
                    route.toCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${isAr ? route.fromNameAr : route.fromNameEn} → ${isAr ? route.toNameAr : route.toNameEn}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      context.tr('fromPrice'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    route.priceHint,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WhySaferBeSection extends StatelessWidget {
  const WhySaferBeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = [
      ('500K+', context.tr('happyTravelers'), Icons.people_outline_rounded),
      ('150+', context.tr('destinationsCount'), Icons.public_rounded),
      ('25+', context.tr('awardsWon'), Icons.emoji_events_outlined),
      ('10+', context.tr('yearsExperience'), Icons.history_rounded),
    ];

    final pillars = [
      (
        Icons.connecting_airports_rounded,
        context.tr('wideOptions'),
        context.tr('wideOptionsDesc'),
      ),
      (
        Icons.savings_outlined,
        context.tr('competitivePrices'),
        context.tr('competitivePricesDesc'),
      ),
      (
        Icons.bolt_rounded,
        context.tr('fastExperience'),
        context.tr('fastExperienceDesc'),
      ),
      (
        Icons.support_agent_rounded,
        context.tr('realSupport'),
        context.tr('realSupportDesc'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('whySaferBe'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('whySaferBeSubtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 11.5,
                ),
          ),
          const SizedBox(height: 14),

          // Stats Counter Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.navy, AppColors.navySoft]
                    : [const Color(0xFF0F365E), AppColors.teal],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: stats.map((stat) {
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stat.$3, color: const Color(0xFFFFB23F), size: 18),
                      const SizedBox(height: 4),
                      Text(
                        stat.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Value Proposition Pillars (2x2 Grid)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pillars.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.20,
            ),
            itemBuilder: (context, index) {
              final pillar = pillars[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(pillar.$1, color: AppColors.teal, size: 18),
                    const SizedBox(height: 4),
                    Text(
                      pillar.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pillar.$3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9.5,
                            color: AppColors.muted,
                            height: 1.2,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class OfficialFooterTrustSection extends StatelessWidget {
  const OfficialFooterTrustSection({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launch('tel:+966920011244'),
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: Text(
                      context.tr('callUs'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: BorderSide(color: AppColors.teal.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _launch('https://wa.me/966920011244?text=Hello'),
                    icon: const Icon(Icons.chat_rounded, size: 16),
                    label: Text(
                      context.tr('chatWhatsApp'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Official Location & Hotline Info
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr('officialAddress'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.headset_mic_outlined, size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('officialHotline'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email_outlined, size: 15, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('officialEmail'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // Payment Methods Strip
            Text(
              context.tr('paymentMethodsAvailable'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: const [
                _PaymentBadge(label: 'مدى Mada'),
                _PaymentBadge(label: 'Visa'),
                _PaymentBadge(label: 'Mastercard'),
                _PaymentBadge(label: 'Apple Pay'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
