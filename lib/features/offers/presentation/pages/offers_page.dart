import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/request_state_view.dart';
import '../../../home/domain/entities/travel_content.dart';
import '../../../home/presentation/widgets/travel_cards.dart';
import '../../data/repositories/local_offers_repository.dart';
import '../../domain/entities/offer_filter.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});
  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  OfferFilter selected = OfferFilter.all;
  final repository = LocalOffersRepository();

  List<TravelOffer> get _filteredOffers {
    final all = repository.getAll();
    if (selected == OfferFilter.all) return all;
    final key = selected.name;
    return all.where((offer) => offer.category == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final keys = ['all', 'flights', 'hotels', 'transfers', 'domestic'];
    final filtered = _filteredOffers;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                context.tr('offers'),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: OfferFilter.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final filter = OfferFilter.values[index];
                  return ChoiceChip(
                    label: Text(context.tr(keys[index])),
                    selected: selected == filter,
                    onSelected: (_) => setState(() => selected = filter),
                  );
                },
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: RequestStateView(
                icon: Icons.local_offer_outlined,
                title: context.tr('noOffersForFilter'),
                message: context.tr('noOffersForFilterBody'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    OfferCard(offer: filtered[index], large: true),
              ),
            ),
        ],
      ),
    );
  }
}
