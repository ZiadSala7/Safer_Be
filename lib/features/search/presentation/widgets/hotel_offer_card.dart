import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/hotel_offer.dart';

class HotelOfferCard extends StatelessWidget {
  const HotelOfferCard({required this.offer, this.onTap, super.key});
  final HotelOffer offer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: offer.imageUrl.isEmpty
                    ? const _HotelImageFallback()
                    : Image.network(
                        offer.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _HotelImageFallback(),
                      ),
              ),
              PositionedDirectional(
                top: 12,
                start: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (AppControllerScope.of(context).showPaymentGatewayMobile)
                      _Pill(
                        icon: Icons.verified_outlined,
                        label: context.tr('livePrice'),
                        color: AppColors.teal,
                      )
                    else
                      _Pill(
                        icon: Icons.chat_rounded,
                        label: context.tr('inquireViaWhatsApp'),
                        color: const Color(0xFF16A34A),
                      ),
                    if (offer.supplier.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _Pill(
                        icon: Icons.cloud_done_rounded,
                        label: offer.supplier.toUpperCase(),
                        color: AppColors.navySoft,
                      ),
                    ],
                  ],
                ),
              ),
              if (offer.rating > 0)
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: _Pill(
                    icon: Icons.star_rounded,
                    label: offer.rating.toString(),
                    color: const Color(0xFFFFB020),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        offer.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (AppControllerScope.of(context).showPaymentGatewayMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.tr('fromPrice'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                          Text(
                            '${offer.price.toStringAsFixed(2)} ${offer.currency}',
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_rounded,
                              size: 13,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('inquireViaWhatsApp'),
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        offer.location.isEmpty
                            ? context.tr('locationUnavailable')
                            : offer.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: _FeatureLabel(
                        icon: Icons.bed_outlined,
                        label: context.tr('rooms'),
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _FeatureLabel(
                        icon: Icons.payments_outlined,
                        label: context.tr('reserve'),
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('details'),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.orange,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeatureLabel extends StatelessWidget {
  const _FeatureLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
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
    child: const Center(child: Icon(Icons.hotel_rounded, size: 42)),
  );
}
