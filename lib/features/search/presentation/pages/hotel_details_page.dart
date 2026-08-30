import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/entities/hotel_offer.dart';
import '../../domain/entities/hotel_search.dart';
import 'hotel_booking_page.dart';

class HotelDetailsPage extends StatelessWidget {
  const HotelDetailsPage({
    required this.offer,
    required this.search,
    super.key,
  });

  final HotelOffer offer;
  final HotelSearch search;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  VoidCallback _bookStay(BuildContext context) {
    if (offer.code.isEmpty) {
      return () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('missingBookingCode'))),
      );
    }
    return () {
      final app = AppControllerScope.of(context);
      if (app.isGuest) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.login_rounded, color: AppColors.teal),
            title: Text(context.tr('signIn')),
            content: Text(context.tr('signInToBook')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('signIn')),
              ),
            ],
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HotelBookingPage(offer: offer, search: search),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final nights = search.checkOut.difference(search.checkIn).inDays;
    return Scaffold(
      bottomNavigationBar: _BookingBar(
        offer: offer,
        onPressed: _bookStay(context),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 300,
            backgroundColor: AppColors.navySoft,
            foregroundColor: Colors.white,
            title: Text(context.tr('stayDetails')),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _HeroImage(offer: offer),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    offer.location.isEmpty
                                        ? context.tr('locationUnavailable')
                                        : offer.location,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (offer.rating > 0) ...[
                        const SizedBox(width: 12),
                        _RatingBadge(rating: offer.rating),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StayMetric(
                          icon: Icons.calendar_month_rounded,
                          label: context.tr('checkInLabel'),
                          value: _date(context, search.checkIn),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StayMetric(
                          icon: Icons.event_available_rounded,
                          label: context.tr('checkOutLabel'),
                          value: _date(context, search.checkOut),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StayMetric(
                          icon: Icons.nights_stay_outlined,
                          label: context.tr('duration'),
                          value:
                              '$nights ${context.tr(nights == 1 ? 'night' : 'nights')}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StayMetric(
                          icon: Icons.people_outline,
                          label: context.tr('guests'),
                          value:
                              '${search.adults} ${context.tr('adults')}${search.children > 0 ? ', ${search.children} ${context.tr('children')}' : ''}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PricePanel(offer: offer),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.workspace_premium_outlined,
                    title: context.tr('stayHighlights'),
                  ),
                  const SizedBox(height: 10),
                  _HighlightGrid(offer: offer),
                  if (offer.description.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(
                      icon: Icons.article_outlined,
                      title: context.tr('aboutThisStay'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      offer.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.route_outlined,
                    title: context.tr('bookingFlow'),
                  ),
                  const SizedBox(height: 10),
                  _NextStep(
                    icon: Icons.meeting_room_outlined,
                    title: context.tr('roomAvailability'),
                    subtitle: context.tr('roomAvailabilityBody'),
                  ),
                  _NextStep(
                    icon: Icons.person_outline,
                    title: context.tr('guestDetails'),
                    subtitle: context.tr('guestDetailsBody'),
                  ),
                  _NextStep(
                    icon: Icons.verified_outlined,
                    title: context.tr('bookingReference'),
                    subtitle: context.tr('bookingReferenceBody'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.offer});

  final HotelOffer offer;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      offer.imageUrl.isEmpty
          ? const _HotelImageFallback()
          : Image.network(
              offer.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _HotelImageFallback(),
            ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: .05),
              Colors.black.withValues(alpha: .44),
            ],
          ),
        ),
      ),
      PositionedDirectional(
        start: 16,
        end: 16,
        bottom: 18,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroPill(
              icon: Icons.verified_outlined,
              label: context.tr('liveRooms'),
            ),
            _HeroPill(
              icon: Icons.payments_outlined,
              label: context.tr('secureRequest'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.offer, required this.onPressed});

  final HotelOffer offer;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: .35),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('fromPrice'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${offer.price.toStringAsFixed(2)} ${offer.currency}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.bed_rounded, size: 19),
              label: Text(
                context.tr('bookStay'),
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.offer});

  final HotelOffer offer;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.teal.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.teal.withValues(alpha: .16)),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE6F7FA),
          foregroundColor: AppColors.teal,
          child: Icon(Icons.payments_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${offer.price.toStringAsFixed(2)} ${offer.currency}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                context.tr('startingPriceLiveSearch'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StayMetric extends StatelessWidget {
  const _StayMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 78),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .35),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.teal, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HighlightGrid extends StatelessWidget {
  const _HighlightGrid({required this.offer});
  final HotelOffer offer;

  @override
  Widget build(BuildContext context) {
    final amenities = offer.amenities;
    if (amenities.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenities
            .take(8)
            .map(
              (amenity) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: .2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }

    return GridView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 82,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      children: [
        _HighlightTile(
          icon: Icons.wifi_rounded,
          label: context.tr('roomOptions'),
        ),
        _HighlightTile(
          icon: Icons.support_agent_rounded,
          label: context.tr('travelSupport'),
        ),
        _HighlightTile(
          icon: Icons.lock_outline_rounded,
          label: context.tr('protectedFlow'),
        ),
        _HighlightTile(
          icon: Icons.receipt_long_outlined,
          label: context.tr('referenceSent'),
        ),
      ],
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .35),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.orange, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.teal, size: 20),
      const SizedBox(width: 8),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.teal),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final num rating;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFB020).withValues(alpha: .14),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFB020), size: 18),
        const SizedBox(width: 3),
        Text('$rating', style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .35),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.orange.withValues(alpha: .1),
          foregroundColor: AppColors.orange,
          child: Icon(icon, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HotelImageFallback extends StatelessWidget {
  const _HotelImageFallback();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: const Center(child: Icon(Icons.hotel_rounded, size: 52)),
  );
}
