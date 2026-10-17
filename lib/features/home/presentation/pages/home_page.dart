import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_press.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_effect.dart';
import '../../data/repositories/local_home_repository.dart';
import '../../../offers/data/repositories/api_offers_repository.dart';
import '../../domain/entities/travel_content.dart';
import '../../../offers/presentation/pages/offers_page.dart';
import '../../../support/presentation/pages/safer_be_support_chat_sheet.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_website_sections.dart';
import '../widgets/travel_cards.dart';
import '../widgets/travel_search_card.dart';

part 'home_horizontal_section.dart';
part 'home_trust_strip.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repository = LocalHomeRepository();
  final _offersRepo = ApiOffersRepository();
  List<TravelOffer>? _liveOffers;
  bool _loadingOffers = true;

  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _offersRepo.getAvailableOffers();
      if (mounted) {
        setState(() {
          _liveOffers = offers.isNotEmpty ? offers : null;
          _loadingOffers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingOffers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedOffers = _liveOffers ?? _repository.offers;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _refreshKey++;
          _loadingOffers = true;
        });
        await Future.wait([
          _loadOffers(),
          AppControllerScope.of(context).refreshSettings(forceRefresh: true),
        ]);
      },
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(
            child: _AnimatedEntrance(delayMs: 0, child: HomeHero()),
          ),
          const SliverToBoxAdapter(
            child: _AnimatedEntrance(delayMs: 50, child: TravelSearchCard()),
          ),
          SliverToBoxAdapter(
            child: _AnimatedEntrance(
              delayMs: 100,
              child: TopDestinationHotelsSection(key: ValueKey('top-dest-$_refreshKey')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(
            child: _AnimatedEntrance(delayMs: 150, child: PopularRoutesSection()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_loadingOffers && _liveOffers == null)
            const SliverToBoxAdapter(
              child: _AnimatedEntrance(
                delayMs: 200,
                child: _OffersShimmerSection(),
              ),
            )
          else if (displayedOffers.isNotEmpty)
            SliverToBoxAdapter(
              child: _AnimatedEntrance(
                delayMs: 200,
                child: _HorizontalSection(
                  title: context.tr('exclusive'),
                  action: context.tr('seeAll'),
                  height: 145,
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(context.tr('offers'))),
                        body: const OffersPage(),
                      ),
                    ),
                  ),
                  children: displayedOffers
                      .map((offer) => OfferCard(offer: offer))
                      .toList(),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
        const SliverToBoxAdapter(
          child: _AnimatedEntrance(
            delayMs: 250,
            child: WhySaferBeSection(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        const SliverToBoxAdapter(
          child: _AnimatedEntrance(
            delayMs: 280,
            child: VipPrivilegeCard(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(
          child: _AnimatedEntrance(
            delayMs: 310,
            child: TravelerReviewsSection(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        const SliverToBoxAdapter(
          child: _AnimatedEntrance(
            delayMs: 340,
            child: _TrustStrip(),
          ),
        ),
        const SliverToBoxAdapter(
          child: _AnimatedEntrance(
            delayMs: 370,
            child: OfficialFooterTrustSection(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ),
  );
}
}

class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({
    required this.child,
    this.delayMs = 0,
  });

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

