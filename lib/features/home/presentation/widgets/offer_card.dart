import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_url_resolver.dart';
import '../../../offers/presentation/widgets/offer_booking_sheet.dart';
import '../../../offers/presentation/widgets/offer_details_sheet.dart';
import '../../domain/entities/travel_content.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    required this.offer,
    this.large = false,
    this.onTap,
    super.key,
  });

  final TravelOffer offer;
  final bool large;
  final VoidCallback? onTap;

  void _copyCode(BuildContext context) {
    if (offer.code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: offer.code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${context.tr('codeCopied')}: ${offer.code}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildImage() {
    final resolved = resolveOfferImageUrl(offer.image);
    final fallbackAsset = offer.fallbackAsset;

    Widget fallback() => Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _genericFallback(),
    );

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
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
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
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
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return fallback();
  }

  Widget _genericFallback() {
    return Container(
      color: const Color(0xFF1C2430),
      child: Center(
        child: Image.asset(
          AppAssets.brandSymbol,
          width: 52,
          height: 52,
          color: Colors.white24,
          errorBuilder: (_, _, _) => const Icon(
            Icons.local_offer_outlined,
            color: Colors.white24,
            size: 40,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(21),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            OfferDetailsSheet.show(context, offer: offer);
          }
        },
        child: Container(
          width: large ? double.infinity : 210,
          height: large ? 225 : 145,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xEB000000)],
                  ),
                ),
              ),
              PositionedDirectional(
                top: 10,
                end: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    offer.formattedDiscount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (large && offer.validUntil != null)
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${context.tr('validUntil')}: ${_formatDate(offer.validUntil!)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                start: 13,
                end: 13,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(offer.titleKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: large ? 17 : 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(offer.subtitleKey),
                      maxLines: large ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    if (large && offer.code.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () => _copyCode(context),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.copy_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            offer.code,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _copyCode(context),
                                  child: Text(
                                    context.tr('copyCode'),
                                    style: const TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => OfferBookingSheet.show(
                                context,
                                offer: offer,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  context.tr('bookWithOffer'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
        ),
      ),
    );
  }
}
