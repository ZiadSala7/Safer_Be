import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/animated_press.dart';
import '../../../../core/widgets/app_store_badges.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/shimmer_effect.dart';
import '../../data/repositories/api_top_destinations_repository.dart';
import '../../domain/entities/top_destination_item.dart';
import '../../../profile/presentation/pages/about_us_page.dart';
import '../../../profile/presentation/pages/branches_page.dart';
import '../../../profile/presentation/pages/contact_us_page.dart';
import '../../../profile/presentation/pages/faq_page.dart';
import '../../../profile/presentation/pages/wallet_page.dart';
import '../../../search/domain/entities/flight_search.dart';
import '../../../search/domain/entities/hotel_search.dart';
import '../../../search/presentation/pages/flight_results_page.dart';
import '../../../search/presentation/pages/hotel_results_page.dart';

class PopularRouteItem {
  const PopularRouteItem({
    required this.id,
    required this.fromCode,
    required this.toCode,
    required this.fromNameAr,
    required this.toNameAr,
    required this.fromNameEn,
    required this.toNameEn,
    required this.image,
  });

  final String id;
  final String fromCode;
  final String toCode;
  final String fromNameAr;
  final String toNameAr;
  final String fromNameEn;
  final String toNameEn;
  final String image;
}

const popularFlightRoutes = [
  PopularRouteItem(
    id: 'ruh-dxb',
    fromCode: 'RUH',
    toCode: 'DXB',
    fromNameAr: 'الرياض',
    toNameAr: 'دبي',
    fromNameEn: 'Riyadh',
    toNameEn: 'Dubai',
    image: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=900&h=700&fit=crop&q=80',
  ),
  PopularRouteItem(
    id: 'ruh-jed',
    fromCode: 'RUH',
    toCode: 'JED',
    fromNameAr: 'الرياض',
    toNameAr: 'جدة',
    fromNameEn: 'Riyadh',
    toNameEn: 'Jeddah',
    image: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&h=700&fit=crop&q=80',
  ),
  PopularRouteItem(
    id: 'jed-ruh',
    fromCode: 'JED',
    toCode: 'RUH',
    fromNameAr: 'جدة',
    toNameAr: 'الرياض',
    fromNameEn: 'Jeddah',
    toNameEn: 'Riyadh',
    image: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&h=700&fit=crop&q=80',
  ),
  PopularRouteItem(
    id: 'jed-cai',
    fromCode: 'JED',
    toCode: 'CAI',
    fromNameAr: 'جدة',
    toNameAr: 'القاهرة',
    fromNameEn: 'Jeddah',
    toNameEn: 'Cairo',
    image: 'https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=900&h=700&fit=crop&q=80',
  ),
  PopularRouteItem(
    id: 'ruh-cai',
    fromCode: 'RUH',
    toCode: 'CAI',
    fromNameAr: 'الرياض',
    toNameAr: 'القاهرة',
    fromNameEn: 'Riyadh',
    toNameEn: 'Cairo',
    image: 'https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=900&h=700&fit=crop&q=80',
  ),
  PopularRouteItem(
    id: 'dxb-ruh',
    fromCode: 'DXB',
    toCode: 'RUH',
    fromNameAr: 'دبي',
    toNameAr: 'الرياض',
    fromNameEn: 'Dubai',
    toNameEn: 'Riyadh',
    image: 'https://images.unsplash.com/photo-1518684079-3c830dcef090?w=900&h=700&fit=crop&q=80',
  ),
  PopularRouteItem(
    id: 'jed-dxb',
    fromCode: 'JED',
    toCode: 'DXB',
    fromNameAr: 'جدة',
    toNameAr: 'دبي',
    fromNameEn: 'Jeddah',
    toNameEn: 'Dubai',
    image: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=900&h=700&fit=crop&q=80',
  ),
  PopularRouteItem(
    id: 'ruh-auh',
    fromCode: 'RUH',
    toCode: 'AUH',
    fromNameAr: 'الرياض',
    toNameAr: 'أبو ظبي',
    fromNameEn: 'Riyadh',
    toNameEn: 'Abu Dhabi',
    image: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=900&h=700&fit=crop&q=80',
  ),
];

class PopularRoutesSection extends StatefulWidget {
  const PopularRoutesSection({
    this.autoScroll = true,
    super.key,
  });

  final bool autoScroll;

  @override
  State<PopularRoutesSection> createState() => _PopularRoutesSectionState();
}

class _PopularRoutesSectionState extends State<PopularRoutesSection> {
  late final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.autoScroll) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      const double step = 242.0; // card width (230) + spacing (12)
      final current = _scrollController.offset;
      final next = current + step;

      if (current >= maxScroll - 10) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _scrollController.animateTo(
          next.clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

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
                  Expanded(
                    child: Text(
                      context.tr('popularRoutes'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
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
          height: 180,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _scrollTimer?.cancel();
              } else if (notification is ScrollEndNotification) {
                if (widget.autoScroll) {
                  _startAutoScroll();
                }
              }
              return false;
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: popularFlightRoutes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
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
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
          width: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.orange.withValues(alpha: 0.28)
                  : AppColors.teal.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.orange.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.network(
                route.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: isDark ? AppColors.navySoft : const Color(0xFF0F365E),
                ),
              ),
              // Gradient Overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x77000000),
                      Color(0xF0000000),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              // Top Flight Code Pill
              PositionedDirectional(
                top: 12,
                end: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flight_takeoff_rounded,
                        color: AppColors.orange,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        route.fromCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          '→',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        route.toCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Content
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAr
                          ? '${route.fromNameAr}  ←  ${route.toNameAr}'
                          : '${route.fromNameEn}  →  ${route.toNameEn}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          context.tr('bookRoute'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final stats = [
      (
        value: '500K+',
        label: context.tr('happyTravelers'),
        icon: Icons.people_alt_rounded,
        color: const Color(0xFFFFB23F),
      ),
      (
        value: '150+',
        label: context.tr('destinationsCount'),
        icon: Icons.flight_takeoff_rounded,
        color: const Color(0xFF38BDF8),
      ),
      (
        value: '25+',
        label: context.tr('awardsWon'),
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF34D399),
      ),
      (
        value: '10+',
        label: context.tr('yearsExperience'),
        icon: Icons.history_rounded,
        color: const Color(0xFFA78BFA),
      ),
    ];

    final pillars = [
      _PillarItem(
        icon: Icons.connecting_airports_rounded,
        gradient: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
        title: context.tr('wideOptions'),
        desc: context.tr('wideOptionsDesc'),
        tag: isAr ? '+500 شركة' : '500+ Airlines',
      ),
      _PillarItem(
        icon: Icons.savings_rounded,
        gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
        title: context.tr('competitivePrices'),
        desc: context.tr('competitivePricesDesc'),
        tag: isAr ? 'ضمان السعر' : 'Best Price',
      ),
      _PillarItem(
        icon: Icons.bolt_rounded,
        gradient: const [Color(0xFFFD7803), Color(0xFFFBBF24)],
        title: context.tr('fastExperience'),
        desc: context.tr('fastExperienceDesc'),
        tag: isAr ? 'تأكيد فوري' : 'Instant',
      ),
      _PillarItem(
        icon: Icons.support_agent_rounded,
        gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
        title: context.tr('realSupport'),
        desc: context.tr('realSupportDesc'),
        tag: isAr ? 'متاح 24/7' : '24/7 Active',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top World-Class Standards Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.orange.withValues(alpha: 0.22),
                        AppColors.teal.withValues(alpha: 0.15),
                      ]
                    : [
                        AppColors.teal.withValues(alpha: 0.12),
                        AppColors.orange.withValues(alpha: 0.10),
                      ],
              ),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: isDark
                    ? AppColors.orange.withValues(alpha: 0.4)
                    : AppColors.teal.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 13,
                  color: isDark ? AppColors.orange : AppColors.teal,
                ),
                const SizedBox(width: 5),
                Text(
                  context.tr('worldClassStandard'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.orangeLight : AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Header with Dual-Accent Bar & Verified Pill
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.teal],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('whySaferBe'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.orange.withValues(alpha: 0.18)
                      : AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isDark
                        ? AppColors.orange.withValues(alpha: 0.4)
                        : AppColors.teal.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: isDark ? AppColors.orange : AppColors.teal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('verifiedPillar'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.orange : AppColors.teal,
                      ),
                    ),
                  ],
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
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 14),

          // Stats Counter Row - Luxury Glowing Executive Metric Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF071A33), Color(0xFF0F365E), Color(0xFF0284C7)]
                    : const [Color(0xFF0A294E), Color(0xFF0F437B), Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? AppColors.orange.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.orange.withValues(alpha: 0.12)
                      : AppColors.navy.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 38,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: stats[i].color.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stats[i].color.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(stats[i].icon, color: stats[i].color, size: 17),
                        ),
                        const SizedBox(height: 5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            stats[i].value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            stats[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4 Pillars Cards (2x2 Resilient Layout without overflow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _PillarCard(item: pillars[0], isDark: isDark),
                    const SizedBox(height: 10),
                    _PillarCard(item: pillars[2], isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    _PillarCard(item: pillars[1], isDark: isDark),
                    const SizedBox(height: 10),
                    _PillarCard(item: pillars[3], isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillarItem {
  const _PillarItem({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.desc,
    required this.tag,
  });

  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String desc;
  final String tag;
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.item, required this.isDark});
  final _PillarItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      scaleDown: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppColors.orange.withValues(alpha: 0.16)
                : Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.orange.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        item.gradient.first.withValues(alpha: 0.22),
                        item.gradient.last.withValues(alpha: 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.gradient.first.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.gradient.first.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: item.gradient.first, size: 17),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.gradient.first.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.gradient.first.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      item.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: item.gradient.first,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9.5,
                    color: AppColors.muted,
                    height: 1.3,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A show-stopping VIP Loyalty Privilege Card for Safer Be.
class VipPrivilegeCard extends StatelessWidget {
  const VipPrivilegeCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppControllerScope.of(context).isFreePurchase) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedPress(
        scaleDown: 0.98,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0F243E), Color(0xFF071426), Color(0xFF101C2E)]
                  : const [Color(0xFF0A2240), Color(0xFF0E2F54), Color(0xFF08182B)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Subtle Brand Symbol Watermark
              PositionedDirectional(
                end: -25,
                bottom: -30,
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    AppAssets.brandSymbol,
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top VIP Badge Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFB23F), Color(0xFFF26A21)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF26A21).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('vipPrivilegeTitle'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAr ? 'عضوية النخبة الحصرية' : 'Exclusive Elite Membership',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFFFFB23F).withValues(alpha: 0.9),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'VIP ELITE',
                            style: TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('vipPrivilegeSubtitle'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3 Gold Perk Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildVipPerk(
                          icon: Icons.monetization_on_rounded,
                          text: context.tr('vipPerk1'),
                        ),
                        _buildVipPerk(
                          icon: Icons.hotel_rounded,
                          text: context.tr('vipPerk2'),
                        ),
                        _buildVipPerk(
                          icon: Icons.support_agent_rounded,
                          text: context.tr('vipPerk3'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletPage(initialAction: 'addPoints'),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: AppColors.orange.withValues(alpha: 0.4),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('joinVipNow'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildVipPerk({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFFFB23F)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Authentic Verified Traveler Reviews & Ratings Carousel.
class TravelerReviewsSection extends StatelessWidget {
  const TravelerReviewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final reviews = [
      (
        nameAr: 'م. فهد الشمري',
        nameEn: 'Eng. Fahad Al-Shammari',
        cityAr: 'الرياض 🇸🇦',
        cityEn: 'Riyadh 🇸🇦',
        route: 'RUH ✈ DXB',
        routeDesc: isAr ? 'طيران الإمارات' : 'Emirates',
        rating: 5,
        reviewAr: 'أفضل تطبيق حجز طيران وفنادق جربته، تذاكر فورية وأسعار واضحة بدون أي زيادات خفية عند الدفع. خدمة العملاء ممتازة وسريعة.',
        reviewEn: 'Best flight & hotel booking platform I tried. Instant tickets and clear prices with no hidden fees at payment. Customer service is 10/10.',
      ),
      (
        nameAr: 'سارة العتيبي',
        nameEn: 'Sarah Al-Otaibi',
        cityAr: 'جدة 🇸🇦',
        cityEn: 'Jeddah 🇸🇦',
        route: 'JED 🏨 DXB',
        routeDesc: isAr ? 'فندق الريتز كارلتون' : 'The Ritz-Carlton',
        rating: 5,
        reviewAr: 'حجزت فندق في دبي بخصم ولا أروع، والموظفين متجاوبين على الواتساب على مدار الساعة. تجربة راقية جداً وسأعتمد التطبيق دائماً.',
        reviewEn: 'Booked a luxury stay in Dubai with a great discount. WhatsApp customer support replied within seconds. Superb experience!',
      ),
      (
        nameAr: 'د. خالد الدوسري',
        nameEn: 'Dr. Khaled Al-Dossari',
        cityAr: 'الدمام 🇸🇦',
        cityEn: 'Dammam 🇸🇦',
        route: 'DMM ✈ CAI',
        routeDesc: isAr ? 'الخطوط السعودية' : 'Saudia Airlines',
        rating: 5,
        reviewAr: 'ميزة نقاط الولاء جوك VIP خيالية، وفرت لي مبلغ ممتاز في رحلتي الثانية. تطبيق ذكي ومريح لكل مسافر.',
        reviewEn: 'The VIP loyalty points are amazing, saved me good money on my second flight. Very smart and intuitive travel app.',
      ),
      (
        nameAr: 'نورة القحطاني',
        nameEn: 'Noura Al-Qahtani',
        cityAr: 'أبها 🇸🇦',
        cityEn: 'Abha 🇸🇦',
        route: 'AHB ✈ RUH',
        routeDesc: isAr ? 'طيران أديل' : 'Flyadeal',
        rating: 5,
        reviewAr: 'منتهى السلاسة والسرعة في الحجز، وأمان الدفع عالي جداً وتأكيد الحجز يوصل في ثوانٍ. شكراً لفريق سافر بي.',
        reviewEn: 'Seamless and rapid booking experience. High payment security and confirmation arrived in seconds. Kudos to Safer Be!',
      ),
    ];

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
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('travelerReviews'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                        SizedBox(width: 3),
                        Text(
                          '4.9 / 5',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      context.tr('travelerReviewsSubtitle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontSize: 11.5,
                          ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• ${context.tr('verifiedRatingCount')}',
                    style: TextStyle(
                      color: isDark ? AppColors.orangeLight : AppColors.teal,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 178,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final r = reviews[index];
              return _ReviewCard(
                name: isAr ? r.nameAr : r.nameEn,
                city: isAr ? r.cityAr : r.cityEn,
                route: r.route,
                routeDesc: r.routeDesc,
                review: isAr ? r.reviewAr : r.reviewEn,
                rating: r.rating,
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.city,
    required this.route,
    required this.routeDesc,
    required this.review,
    required this.rating,
    required this.isDark,
  });

  final String name;
  final String city;
  final String route;
  final String routeDesc;
  final String review;
  final int rating;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      scaleDown: 0.97,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppColors.orange.withValues(alpha: 0.18)
                : Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.orange.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
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
                CircleAvatar(
                  radius: 17,
                  backgroundColor: isDark
                      ? AppColors.orange.withValues(alpha: 0.22)
                      : AppColors.teal.withValues(alpha: 0.14),
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: TextStyle(
                      color: isDark ? AppColors.orangeLight : AppColors.teal,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ),
                      Text(
                        city,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.teal.withValues(alpha: 0.18)
                        : const Color(0xFF0284C7).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    route,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    rating,
                    (_) => const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFB23F),
                    ),
                  ),
                ),
                Text(
                  routeDesc,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF071A33) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? AppColors.orange.withValues(alpha: 0.22)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.orange.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Prestigious Brand Showcase Header
            Row(
              children: [
                const SaferBeBrandAvatar(
                  size: 46,
                  isVerified: true,
                  backgroundColor: AppColors.navy,
                  borderColor: AppColors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'سافر بي للسياحة والسفر' : 'Safer Be Travel & Tourism',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'منصة سعودية معتمدة لحجوزات الطيران والفنادق'
                            : 'Licensed Saudi platform for flights & hotels',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                              color: AppColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Direct Concierge & VIP Support Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _launch('tel:+966920011244'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.orangeLight : AppColors.teal,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.orange.withValues(alpha: 0.45)
                            : AppColors.teal.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_in_talk_rounded, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isAr ? 'اتصل الآن' : 'Call Now',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _launch('https://wa.me/966920011244?text=Hello'),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                    label: Text(
                      context.tr('chatWhatsApp'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Official Headquarters & Contact Info Tile
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A223E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('officialAddress'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10.5,
                                color: AppColors.muted,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => _launch('tel:+966920011244'),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.headset_mic_rounded, size: 14, color: AppColors.orange),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('officialHotline'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _launch('mailto:info@safer-be.com'),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.alternate_email_rounded, size: 14, color: AppColors.teal),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('officialEmail'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Quick Navigation Directory Pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDirectoryChip(
                  context,
                  label: context.tr('aboutUs'),
                  icon: Icons.info_outline_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsPage()),
                  ),
                ),
                _buildDirectoryChip(
                  context,
                  label: context.tr('branches'),
                  icon: Icons.store_mall_directory_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BranchesPage()),
                  ),
                ),
                _buildDirectoryChip(
                  context,
                  label: context.tr('faq'),
                  icon: Icons.help_outline_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaqPage()),
                  ),
                ),
                _buildDirectoryChip(
                  context,
                  label: context.tr('contactUs'),
                  icon: Icons.contact_support_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactUsPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 5. Official Accreditation & Security Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('licensedByGacaFull'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 13, color: AppColors.muted.withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.tr('securityStandards'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 9.5,
                                color: AppColors.muted,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // 6. Download App Section
            const AppDownloadFooterSection(),
            const Divider(height: 24),

            // 7. Copyright & Saudi Pride Note
            Center(
              child: Column(
                children: [
                  Text(
                    context.tr('allRightsReserved'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('madeInSaudi'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 9.5,
                          color: AppColors.muted.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDirectoryChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isDark ? AppColors.orangeLight : AppColors.teal),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class TopDestinationHotelsSection extends StatefulWidget {
  const TopDestinationHotelsSection({
    this.autoScroll = true,
    super.key,
  });

  final bool autoScroll;

  @override
  State<TopDestinationHotelsSection> createState() => _TopDestinationHotelsSectionState();
}

class _TopDestinationHotelsSectionState extends State<TopDestinationHotelsSection>
    with SingleTickerProviderStateMixin {
  final _repository = ApiTopDestinationsRepository();
  late final ScrollController _scrollController = ScrollController();
  late List<TopDestinationItem> _destinations = _repository.defaultDestinations;
  bool _loading = false;
  bool _isUserInteracting = false;
  Timer? _resumeTimer;

  // Each card width (215) + spacing (12)
  static const double _cardStride = 227.0;

  // Continuous scroll speed in pixels per second
  static const double _scrollSpeed = 40.0;

  AnimationController? _ticker;
  double _lastTickTime = 0;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    if (widget.autoScroll && _destinations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initContinuousScroll());
    }
  }

  void _initContinuousScroll() {
    if (_destinations.length < 2 || !widget.autoScroll) return;
    _ticker?.dispose();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    _lastTickTime = 0;
    _ticker!.repeat();
  }

  void _onTick() {
    if (!mounted || !_scrollController.hasClients || _isUserInteracting) return;
    final controller = _ticker!;
    final currentTime = (controller.lastElapsedDuration?.inMicroseconds ?? 0).toDouble();
    if (_lastTickTime == 0) {
      _lastTickTime = currentTime;
      return;
    }
    final dt = (currentTime - _lastTickTime) / 1000000.0; // seconds
    _lastTickTime = currentTime;

    if (dt <= 0 || dt > 0.5) return; // skip large jumps

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final current = _scrollController.offset;
    final cycleLength = _destinations.length * _cardStride;

    double next = current + _scrollSpeed * dt;
    // Seamless loop: when scrolled past one full set, jump back
    if (next >= cycleLength) {
      next -= cycleLength;
    }

    _scrollController.jumpTo(next.clamp(0.0, maxScroll));
  }

  void _pauseAutoScroll() {
    _isUserInteracting = true;
    _resumeTimer?.cancel();
  }

  void _resumeAutoScrollAfterDelay() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        _isUserInteracting = false;
        _lastTickTime = 0; // reset to avoid a big dt jump
      }
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDestinations({bool force = false}) async {
    if (force) {
      setState(() => _loading = true);
    }
    try {
      final items = await _repository.getTopDestinations(forceRefresh: force);
      if (mounted) {
        setState(() {
          _destinations = items;
          _loading = false;
        });
        if (widget.autoScroll && items.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initContinuousScroll();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _destinations;

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
                      color: isDark ? AppColors.orange : AppColors.teal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('topDestinations'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('topDestinationsDesc'),
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
          height: 240,
          child: _loading && _destinations.isEmpty
              ? ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, _) => _TopDestinationSkeleton(isDark: isDark),
                )
              : Listener(
                  onPointerDown: (_) => _pauseAutoScroll(),
                  onPointerUp: (_) => _resumeAutoScrollAfterDelay(),
                  onPointerCancel: (_) => _resumeAutoScrollAfterDelay(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null) {
                        _pauseAutoScroll();
                      } else if (notification is ScrollEndNotification) {
                        _resumeAutoScrollAfterDelay();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length * 10,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = items[index % items.length];
                        return _TopDestinationCard(
                          destination: item,
                          isAr: isAr,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TopDestinationCard extends StatelessWidget {
  const _TopDestinationCard({
    required this.destination,
    required this.isAr,
    required this.isDark,
  });

  final TopDestinationItem destination;
  final bool isAr;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          String currency = 'SAR';
          try {
            currency = AppControllerScope.of(context).currency;
          } catch (_) {}

          final targetCityCode = destination.cityCode.isNotEmpty
              ? destination.cityCode
              : destination.destinationCode;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HotelResultsPage(
                search: HotelSearch(
                  cityCode: targetCityCode,
                  checkIn: DateTime.now().add(const Duration(days: 7)),
                  checkOut: DateTime.now().add(const Duration(days: 10)),
                  currency: currency,
                ),
              ),
            ),
          );
        },
        child: Container(
          width: 215,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.orange.withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.orange.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.network(
                destination.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: isDark ? AppColors.navySoft : const Color(0xFF0F365E),
                ),
              ),
              // Gradient Overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x66000000),
                      Color(0xF5000000),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              // Top Bar: Country Flag & Popular Badge
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (destination.flagUrl.isNotEmpty)
                      Container(
                        width: 28,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white60, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          destination.flagUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(),
                        ),
                      )
                    else
                      const SizedBox(),
                    if (destination.rank > 0 && destination.rank <= 10)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.orange
                              : AppColors.teal.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              context.tr('popular'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom Details
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      destination.localizedCityName(isAr),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destination.localizedCountryName(isAr),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            context.tr('exploreHotels'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.orangeLight : AppColors.teal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                          size: 13,
                          color: isDark ? AppColors.orangeLight : AppColors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopDestinationSkeleton extends StatelessWidget {
  const _TopDestinationSkeleton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: 215,
        height: 240,
        decoration: BoxDecoration(
          color: isDark ? AppColors.navySoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.orange.withValues(alpha: 0.12)
                : AppColors.teal.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 30, height: 18, borderRadius: 4),
                ShimmerBox(width: 52, height: 18, borderRadius: 10),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 120, height: 18, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 70, height: 12, borderRadius: 4),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 80, height: 22, borderRadius: 8),
                    ShimmerBox(width: 40, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
