import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../support/presentation/pages/safer_be_support_chat_sheet.dart';
import '../../domain/entities/hotel_offer.dart';
import '../../domain/entities/hotel_search.dart';
import 'hotel_booking_page.dart';

class HotelDetailsPage extends StatefulWidget {
  const HotelDetailsPage({
    required this.offer,
    required this.search,
    super.key,
  });

  final HotelOffer offer;
  final HotelSearch search;

  @override
  State<HotelDetailsPage> createState() => _HotelDetailsPageState();
}

class _HotelDetailsPageState extends State<HotelDetailsPage> {
  bool isDescriptionExpanded = false;

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatShortDate(value);

  VoidCallback _bookStay(BuildContext context) {
    if (widget.offer.code.isEmpty) {
      return () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('missingBookingCode'))),
      );
    }
    return () {
      final app = AppControllerScope.of(context);
      if (!app.showPaymentGatewayMobile) {
        AppWhatsAppHelper.launchHotelInquiry(
          context: context,
          offer: widget.offer,
        );
        return;
      }
      if (app.isGuest) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.login_rounded, color: AppColors.teal, size: 28),
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
          builder: (_) => HotelBookingPage(
            offer: widget.offer,
            search: widget.search,
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final nights =
        widget.search.checkOut.difference(widget.search.checkIn).inDays;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: _StayBookingBar(
        offer: widget.offer,
        onPressed: _bookStay(context),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 310,
            backgroundColor: isDark ? AppColors.navy : AppColors.navySoft,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _GlassCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: _GlassCircleButton(
                  icon: Icons.support_agent_rounded,
                  onTap: () => SaferBeSupportChatSheet.show(context),
                ),
              ),
            ],
            title: Text(
              context.tr('stayDetails'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _HeroHotelImage(offer: widget.offer),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel Title, Location & Rating Card
                  _HotelHeaderCard(offer: widget.offer),
                  const SizedBox(height: 18),

                  // Stay Dates & Guest Info Card
                  _StayDatesCard(
                    checkIn: _date(context, widget.search.checkIn),
                    checkOut: _date(context, widget.search.checkOut),
                    nights: nights,
                    adults: widget.search.adults,
                    children: widget.search.children,
                  ),
                  const SizedBox(height: 18),

                  // Starting Rate & Live Search Price Panel
                  _LivePricePanel(offer: widget.offer, nights: nights),
                  const SizedBox(height: 22),

                  // Stay Highlights & Amenities
                  _SectionHeader(
                    icon: Icons.workspace_premium_outlined,
                    title: context.tr('stayHighlights'),
                  ),
                  const SizedBox(height: 10),
                  _HotelHighlightsGrid(offer: widget.offer),
                  const SizedBox(height: 22),

                  // Property Description
                  if (widget.offer.description.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.article_outlined,
                      title: context.tr('aboutThisStay'),
                    ),
                    const SizedBox(height: 10),
                    _DescriptionCard(
                      description: widget.offer.description,
                      isExpanded: isDescriptionExpanded,
                      onToggle: () {
                        setState(() {
                          isDescriptionExpanded = !isDescriptionExpanded;
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Room Selection Notice Card
                  _RoomOptionsPreviewCard(offer: widget.offer),
                  const SizedBox(height: 22),

                  if (AppControllerScope.of(context).showPaymentGatewayMobile) ...[
                    // Booking Flow Steps
                    _SectionHeader(
                      icon: Icons.route_outlined,
                      title: context.tr('bookingFlow'),
                    ),
                    const SizedBox(height: 10),
                    _BookingStepTile(
                      number: '1',
                      icon: Icons.meeting_room_outlined,
                      title: context.tr('roomAvailability'),
                      subtitle: context.tr('roomAvailabilityBody'),
                    ),
                    _BookingStepTile(
                      number: '2',
                      icon: Icons.person_outline_rounded,
                      title: context.tr('guestDetails'),
                      subtitle: context.tr('guestDetailsBody'),
                    ),
                    _BookingStepTile(
                      number: '3',
                      icon: Icons.verified_outlined,
                      title: context.tr('bookingReference'),
                      subtitle: context.tr('bookingReferenceBody'),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // WhatsApp Inquiry & Booking Card
                    WhatsAppInquiryBannerCard(
                      title: context.tr('contactViaWhatsApp'),
                      subtitle: context.tr('whatsAppHotelConsultation'),
                      onPressed: () => AppWhatsAppHelper.launchHotelInquiry(
                        context: context,
                        offer: widget.offer,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Guarantee Banner
                  _HotelTrustCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHotelImage extends StatelessWidget {
  const _HeroHotelImage({required this.offer});

  final HotelOffer offer;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      offer.imageUrl.isEmpty
          ? const _HotelFallbackImage()
          : Image.network(
              offer.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _HotelFallbackImage(),
            ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: .25),
              Colors.transparent,
              Colors.black.withValues(alpha: .65),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
      ),
      PositionedDirectional(
        start: 16,
        end: 16,
        bottom: 16,
        child: Row(
          children: [
            _HeroPill(
              icon: Icons.verified_rounded,
              label: context.tr('liveRooms'),
              color: AppColors.teal,
            ),
            const SizedBox(width: 8),
            _HeroPill(
              icon: Icons.shield_outlined,
              label: context.tr('secureRequest'),
              color: AppColors.orange,
            ),
            if (offer.supplier.isNotEmpty) ...[
              const SizedBox(width: 8),
              _HeroPill(
                icon: Icons.cloud_done_rounded,
                label: offer.supplier.toUpperCase(),
                color: AppColors.navySoft,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _HotelHeaderCard extends StatelessWidget {
  const _HotelHeaderCard({required this.offer});
  final HotelOffer offer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  offer.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              if (offer.rating > 0) ...[
                const SizedBox(width: 12),
                _StarRatingPill(rating: offer.rating),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 19,
                color: AppColors.orange,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  offer.location.isNotEmpty
                      ? offer.location
                      : context.tr('locationUnavailable'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _QuickTag(
                icon: Icons.check_circle_outline_rounded,
                label: context.tr('instantConfirmation'),
              ),
              const SizedBox(width: 8),
              _QuickTag(
                icon: Icons.wifi_rounded,
                label: 'Free WiFi',
              ),
              const SizedBox(width: 8),
              _QuickTag(
                icon: Icons.support_agent_rounded,
                label: '24/7 Support',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StayDatesCard extends StatelessWidget {
  const _StayDatesCard({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
  });

  final String checkIn;
  final String checkOut;
  final int nights;
  final int adults;
  final int children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            // Check-in
            Expanded(
              child: _DateColumn(
                icon: Icons.calendar_today_rounded,
                label: context.tr('checkInLabel'),
                date: checkIn,
              ),
            ),

            // Nights badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.nights_stay_rounded,
                    size: 16,
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$nights ${context.tr(nights == 1 ? 'night' : 'nights')}',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Check-out
            Expanded(
              child: _DateColumn(
                icon: Icons.event_available_rounded,
                label: context.tr('checkOutLabel'),
                date: checkOut,
                alignEnd: true,
              ),
            ),
          ],
        ),
        const Divider(height: 22),
        Row(
          children: [
            const Icon(Icons.people_alt_outlined, size: 18, color: AppColors.teal),
            const SizedBox(width: 8),
            Text(
              '${context.tr('guests')}: ',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            Text(
              '$adults ${context.tr(adults == 1 ? 'adult' : 'adults')}${children > 0 ? ', $children ${context.tr(children == 1 ? 'child' : 'children')}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({
    required this.icon,
    required this.label,
    required this.date,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final String date;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!alignEnd) ...[
            Icon(icon, size: 14, color: AppColors.muted),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (alignEnd) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: AppColors.muted),
          ],
        ],
      ),
      const SizedBox(height: 4),
      Text(
        date,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      ),
    ],
  );
}

class _LivePricePanel extends StatelessWidget {
  const _LivePricePanel({required this.offer, required this.nights});

  final HotelOffer offer;
  final int nights;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.teal.withValues(alpha: 0.12),
          AppColors.teal.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        if (AppControllerScope.of(context).showPaymentGatewayMobile) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${offer.price.toStringAsFixed(2)} ${offer.currency}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ ${context.tr('stay')}',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('taxesAndFees'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_rounded,
              color: Color(0xFF16A34A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('contactViaWhatsApp'),
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('inquireViaWhatsApp'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _HotelHighlightsGrid extends StatelessWidget {
  const _HotelHighlightsGrid({required this.offer});
  final HotelOffer offer;

  @override
  Widget build(BuildContext context) {
    final amenities = offer.amenities;
    if (amenities.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenities
            .take(10)
            .map(
              (amenity) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
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
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
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
        mainAxisExtent: 76,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      children: [
        _ServiceHighlightTile(
          icon: Icons.meeting_room_rounded,
          label: context.tr('roomOptions'),
          color: AppColors.teal,
        ),
        _ServiceHighlightTile(
          icon: Icons.support_agent_rounded,
          label: context.tr('travelSupport'),
          color: AppColors.orange,
          onTap: () => SaferBeSupportChatSheet.show(context),
        ),
        _ServiceHighlightTile(
          icon: Icons.lock_outline_rounded,
          label: context.tr('protectedFlow'),
          color: AppColors.teal,
        ),
        _ServiceHighlightTile(
          icon: Icons.receipt_long_outlined,
          label: context.tr('instantConfirmation'),
          color: AppColors.orange,
        ),
      ],
    );
  }
}

class _ServiceHighlightTile extends StatelessWidget {
  const _ServiceHighlightTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  final String description;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          maxLines: isExpanded ? null : 4,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
          ),
        ),
        if (description.length > 200) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onToggle,
            child: Text(
              isExpanded ? 'Show less' : 'Read more...',
              style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _RoomOptionsPreviewCard extends StatelessWidget {
  const _RoomOptionsPreviewCard({required this.offer});
  final HotelOffer offer;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.orange.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.bed_rounded,
            color: AppColors.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('roomOptions'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('roomAvailabilityBody'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.orange,
        ),
      ],
    ),
  );
}

class _BookingStepTile extends StatelessWidget {
  const _BookingStepTile({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String number;
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
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HotelTrustCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.teal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE6F7FA),
          foregroundColor: AppColors.teal,
          radius: 18,
          child: Icon(Icons.verified_user_outlined, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('secureCheckout'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('supportAssistance'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StayBookingBar extends StatelessWidget {
  const _StayBookingBar({required this.offer, required this.onPressed});

  final HotelOffer offer;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AppControllerScope.of(context).showPaymentGatewayMobile
          ? Row(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.bed_rounded, size: 20),
                    label: Text(
                      context.tr('bookStay'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                  ),
                ),
              ],
            )
          : WhatsAppBookingButton(
              height: 52,
              onPressed: () => AppWhatsAppHelper.launchHotelInquiry(
                context: context,
                offer: offer,
              ),
            ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
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
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.25),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _StarRatingPill extends StatelessWidget {
  const _StarRatingPill({required this.rating});
  final num rating;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFB020).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFFFB020).withValues(alpha: 0.4),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFB020), size: 18),
        const SizedBox(width: 4),
        Text(
          '$rating',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: Color(0xFFD97706),
          ),
        ),
      ],
    ),
  );
}

class _QuickTag extends StatelessWidget {
  const _QuickTag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.teal),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

class _HotelFallbackImage extends StatelessWidget {
  const _HotelFallbackImage();

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: const Center(
      child: Icon(Icons.hotel_rounded, size: 60, color: AppColors.teal),
    ),
  );
}
