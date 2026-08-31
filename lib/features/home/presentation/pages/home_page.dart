import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../data/repositories/local_home_repository.dart';
import '../../../support/presentation/pages/safer_be_support_chat_sheet.dart';
import '../widgets/home_hero.dart';
import '../widgets/travel_cards.dart';
import '../widgets/travel_search_card.dart';

part 'home_horizontal_section.dart';
part 'home_recent_searches.dart';
part 'home_trust_strip.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final repository = LocalHomeRepository();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        const SliverToBoxAdapter(child: HomeHero()),
        const SliverToBoxAdapter(child: TravelSearchCard()),
        SliverToBoxAdapter(child: _RecentSearches()),
        SliverToBoxAdapter(
          child: _HorizontalSection(
            title: context.tr('exclusive'),
            action: context.tr('seeAll'),
            height: 145,
            children: repository.offers
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
                      children: repository.services
                          .map((service) => ServiceTile(service: service))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _HorizontalSection(
            title: context.tr('saudiDestinations'),
            action: context.tr('explore'),
            height: 116,
            children: repository.destinations
                .map((destination) => DestinationCard(destination: destination))
                .toList(),
          ),
        ),
        SliverToBoxAdapter(child: _TrustStrip()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
