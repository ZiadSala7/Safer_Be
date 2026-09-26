import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
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
part 'home_recent_searches.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _offersRepo.getAvailableOffers();
      if (mounted && offers.isNotEmpty) {
        setState(() => _liveOffers = offers);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final displayedOffers = _liveOffers ?? _repository.offers;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadOffers(),
          AppControllerScope.of(context).refreshSettings(forceRefresh: true),
        ]);
      },
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
      slivers: [
        const SliverToBoxAdapter(child: HomeHero()),
        const SliverToBoxAdapter(child: TravelSearchCard()),
        SliverToBoxAdapter(child: _RecentSearches()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: PopularRoutesSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (displayedOffers.isNotEmpty)
          SliverToBoxAdapter(
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: context.tr('quickServices')),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 600 ? 6 : 4;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: .9,
                      children: _repository.services
                          .map((service) => ServiceTile(service: service))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        const SliverToBoxAdapter(child: WhySaferBeSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: _TrustStrip()),
        const SliverToBoxAdapter(child: OfficialFooterTrustSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ),
  );
}
}

