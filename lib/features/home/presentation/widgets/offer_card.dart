import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/travel_content.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({required this.offer, this.large = false, super.key});

  final TravelOffer offer;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
    width: large ? double.infinity : 210,
    height: large ? 190 : 145,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(21)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(offer.image, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xD9000000)],
            ),
          ),
        ),
        PositionedDirectional(
          top: 10,
          end: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${offer.discount}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
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
            children: [
              Text(
                context.tr(offer.titleKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 18 : 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                context.tr(offer.subtitleKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              if (large)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    offer.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
