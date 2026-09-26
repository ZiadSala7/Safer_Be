import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/flight_offer.dart';
import '../../domain/entities/flight_search.dart';

class FlightOfferCard extends StatelessWidget {
  const FlightOfferCard({required this.offer, this.onTap, super.key});
  final FlightOffer offer;
  final VoidCallback? onTap;

  String _time(BuildContext context, DateTime? value) => value == null
      ? '—'
      : MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(value),
          alwaysUse24HourFormat: false,
        );

  String _duration(BuildContext context) {
    if (offer.durationMinutes <= 0) return context.tr('durationUnavailable');
    final hours = offer.durationMinutes ~/ 60;
    final minutes = offer.durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _stops(BuildContext context) => offer.stops == 0
      ? context.tr('direct')
      : '${offer.stops} ${context.tr(offer.stops == 1 ? 'stop' : 'stops')}';

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE6F7FA),
                  foregroundColor: AppColors.teal,
                  child: Icon(Icons.flight_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.airline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (offer.cabinClass.isNotEmpty)
                        Text(
                          resolveFlightCabinName(
                            offerCabin: offer.cabinClass,
                            searchCabinClass: 1,
                            isAr: Localizations.localeOf(context).languageCode == 'ar',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (AppControllerScope.of(context).showPaymentGatewayMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${offer.price.toStringAsFixed(2)} ${offer.currency}',
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        context.tr('perTraveler'),
                        style: Theme.of(context).textTheme.bodySmall,
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
            if (offer.labels.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: offer.labels
                    .map(
                      (label) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                _FlightTime(time: _time(context, offer.departureTime)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _duration(context),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Divider(height: 1),
                      ),
                      Text(
                        _stops(context),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: offer.stops == 0 ? AppColors.teal : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _FlightTime(time: _time(context, offer.arrivalTime)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  offer.refundable
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 16,
                  color: offer.refundable ? AppColors.teal : null,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    context.tr(offer.refundable ? 'refundable' : 'nonRefundable'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (offer.baggage.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.luggage_outlined, size: 18),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      offer.baggage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Flexible(
                  child: _FeatureLabel(
                    icon: Icons.schedule_rounded,
                    label: context.tr(
                      offer.stops == 0 ? 'direct' : 'connections',
                    ),
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: _FeatureLabel(
                    icon: Icons.receipt_long_outlined,
                    label: context.tr(
                      offer.refundable ? 'flexible' : 'fareRules',
                    ),
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
    ),
  );
}

class _FlightTime extends StatelessWidget {
  const _FlightTime({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) => Text(
    time,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
