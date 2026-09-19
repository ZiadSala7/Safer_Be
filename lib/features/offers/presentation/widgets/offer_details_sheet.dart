import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_url_resolver.dart';
import '../../../home/domain/entities/travel_content.dart';
import '../../domain/utils/offer_destination_resolver.dart';
import 'offer_booking_sheet.dart';

/// A rich modal bottom sheet that displays comprehensive marketing offer details,
/// high-resolution gallery images, terms & conditions, and one-tap promo code copying.
class OfferDetailsSheet extends StatefulWidget {
  const OfferDetailsSheet({
    required this.offer,
    super.key,
  });

  final TravelOffer offer;

  static Future<void> show(
    BuildContext context, {
    required TravelOffer offer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OfferDetailsSheet(offer: offer),
    );
  }

  @override
  State<OfferDetailsSheet> createState() => _OfferDetailsSheetState();
}

class _OfferDetailsSheetState extends State<OfferDetailsSheet> {
  int _currentImageIndex = 0;
  bool _copied = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _copyPromoCode() {
    if (widget.offer.code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: widget.offer.code));
    HapticFeedback.lightImpact();

    setState(() => _copied = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${context.tr('codeCopied')}: ${widget.offer.code}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _useOfferAndBook() {
    _copyPromoCode();
    Navigator.of(context).pop();
    OfferBookingSheet.show(context, offer: widget.offer);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'flights':
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'hotels':
      case 'hotel':
      case 'stay':
        return Icons.hotel_rounded;
      case 'transfers':
      case 'transfer':
        return Icons.directions_car_rounded;
      case 'domestic':
        return Icons.explore_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }

  Widget _buildGalleryImage(String url, String fallbackAsset) {
    final resolved = resolveOfferImageUrl(url);

    Widget fallback() => Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFF1E2633),
        child: Center(
          child: Image.asset(
            AppAssets.brandSymbol,
            width: 64,
            height: 64,
            color: Colors.white24,
            errorBuilder: (_, _, _) => const Icon(
              Icons.local_offer_outlined,
              color: Colors.white24,
              size: 48,
            ),
          ),
        ),
      ),
    );

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              fallback(),
              Container(
                color: Colors.black26,
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (resolved.startsWith('assets/')) {
      return Image.asset(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }

    return fallback();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = widget.offer.allImageUrls;
    final fallbackAsset = widget.offer.fallbackAsset;
    final displayImages = images.isNotEmpty ? images : [fallbackAsset];
    final isExpired = widget.offer.isExpired;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161C26) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top drag handle & close button bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Hero Image / Gallery Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 220,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: displayImages.length,
                              onPageChanged: (index) {
                                setState(() => _currentImageIndex = index);
                              },
                              itemBuilder: (context, index) {
                                return _buildGalleryImage(
                                  displayImages[index],
                                  fallbackAsset,
                                );
                              },
                            ),

                            // Top & Bottom Gradients
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black38,
                                    Colors.transparent,
                                    Color(0xB3000000),
                                  ],
                                  stops: [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),

                            // Category badge (Top-Start)
                            PositionedDirectional(
                              top: 14,
                              start: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _categoryIcon(widget.offer.category),
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      context.tr(widget.offer.category),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Discount pill (Top-End)
                            PositionedDirectional(
                              top: 14,
                              end: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.orange,
                                      Color(0xFFFF8F00),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.offer.formattedDiscount,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),

                            // Status badge (Bottom-Start)
                            PositionedDirectional(
                              bottom: 14,
                              start: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? Colors.red.withValues(alpha: 0.85)
                                      : Colors.green.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isExpired
                                          ? context.tr('expiredOffer')
                                          : context.tr('activeOffer'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Carousel dots (Bottom-End)
                            if (displayImages.length > 1)
                              PositionedDirectional(
                                bottom: 14,
                                end: 14,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    displayImages.length,
                                    (i) => Container(
                                      width: _currentImageIndex == i ? 16 : 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(left: 3),
                                      decoration: BoxDecoration(
                                        color: _currentImageIndex == i
                                            ? Colors.white
                                            : Colors.white38,
                                        borderRadius:
                                            BorderRadius.circular(99),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Title
                    Text(
                      context.tr(widget.offer.titleKey),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E2633),
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      context.tr(widget.offer.subtitleKey),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Promo Code Ticket Card
                    if (widget.offer.code.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF222B3A)
                              : const Color(0xFFF3F6FA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.confirmation_number_outlined,
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
                                    context.tr('offerCode'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.offer.code,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E2633),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _copyPromoCode,
                              style: FilledButton.styleFrom(
                                backgroundColor: _copied
                                    ? AppColors.teal
                                    : AppColors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                _copied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                size: 16,
                              ),
                              label: Text(
                                _copied
                                    ? context.tr('codeCopied')
                                    : context.tr('copyCode'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Offer Terms & Conditions Grid
                    Text(
                      context.tr('offerDetails'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E2633),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Details Specs
                    _buildSpecTile(
                      context,
                      icon: Icons.percent_rounded,
                      title: context.tr('discountValue'),
                      value: widget.offer.formattedDiscount,
                      isDark: isDark,
                    ),

                    if (widget.offer.maxDiscount != null)
                      _buildSpecTile(
                        context,
                        icon: Icons.vertical_align_top_rounded,
                        title: context.tr('maxDiscount'),
                        value:
                            '${widget.offer.maxDiscount} ${widget.offer.currency ?? 'SAR'}',
                        isDark: isDark,
                      ),

                    if (widget.offer.minBookingAmount != null)
                      _buildSpecTile(
                        context,
                        icon: Icons.shopping_bag_outlined,
                        title: context.tr('minBookingAmount'),
                        value:
                            '${widget.offer.minBookingAmount} ${widget.offer.currency ?? 'SAR'}',
                        isDark: isDark,
                      ),

                    _buildSpecTile(
                      context,
                      icon: Icons.calendar_month_outlined,
                      title: context.tr('validityPeriod'),
                      value: widget.offer.validUntil != null
                          ? '${widget.offer.validFrom != null ? '${_formatDate(widget.offer.validFrom!)} → ' : ''}${_formatDate(widget.offer.validUntil!)}'
                          : context.tr('validOngoing'),
                      isDark: isDark,
                    ),

                    if (widget.offer.perUserLimit != null)
                      _buildSpecTile(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: context.tr('perUserLimit'),
                        value:
                            '${widget.offer.perUserLimit} ${context.tr('times')}',
                        isDark: isDark,
                      ),

                    if (widget.offer.usageLimit != null)
                      _buildSpecTile(
                        context,
                        icon: Icons.groups_outlined,
                        title: context.tr('usageLimit'),
                        value:
                            '${widget.offer.usageLimit} ${context.tr('times')}',
                        isDark: isDark,
                      ),

                    // Conditions tags (from Postman collection)
                    if (widget.offer.conditions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.tr('conditions'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.offer.conditions.map((c) {
                          return Chip(
                            backgroundColor: isDark
                                ? const Color(0xFF222B3A)
                                : const Color(0xFFEEF2F7),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black12,
                            ),
                            label: Text(
                              '${c.conditionType.toUpperCase()}: ${c.conditionValue}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Destination Pre-filled Info Card
                    Builder(
                      builder: (context) {
                        final prefill =
                            OfferDestinationResolver.resolve(widget.offer);
                        final isHotel =
                            prefill.bookingType == OfferBookingType.hotel;
                        final destName = isHotel
                            ? prefill.city.name
                            : prefill.destinationAirport.city;
                        final destSub = isHotel
                            ? prefill.city.country
                            : prefill.destinationAirport.name;

                        return InkWell(
                          onTap: _useOfferAndBook,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF222B3A)
                                  : const Color(0xFFF3F6FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.orange.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isHotel
                                        ? Icons.hotel_rounded
                                        : Icons.flight_takeoff_rounded,
                                    color: AppColors.orange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            destName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1E2633),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.orange
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              context.tr(
                                                'offerDestinationPreFilled',
                                              ),
                                              style: const TextStyle(
                                                color: AppColors.orange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$destSub • ${context.tr('selectDatesForOffer')}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: AppColors.orange,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Book / Use Offer CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _useOfferAndBook,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          context.tr('bookWithOffer'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E2633),
            ),
          ),
        ],
      ),
    );
  }
}
