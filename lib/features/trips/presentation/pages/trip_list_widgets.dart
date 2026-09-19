part of 'trips_page.dart';

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, this.onTap});

  final Trip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isHotel = trip.type == 'hotel';
    final s = trip.status.toLowerCase().trim();
    final isConfirmed = s == 'confirmed' || s == 'paid';
    final isTicketed = s == 'ticketed';
    final isPending = s == 'pending' || s == 'processing' || s.isEmpty;
    final isReleased = s == 'released' || s == 'cancelled' || s == 'canceled';
    final isRefunded = s == 'refunded' || s == 'refund_requested';

    final Color statusColor = (isConfirmed || isTicketed)
        ? AppColors.teal
        : isRefunded
        ? Colors.purple
        : isReleased
        ? Colors.grey
        : (isPending ? AppColors.orange : Colors.redAccent);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isHotel
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8FBFF),
                child: Icon(
                  isHotel ? Icons.hotel_rounded : Icons.flight_rounded,
                  color: isHotel ? AppColors.orange : AppColors.teal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.reference.isNotEmpty
                          ? '${trip.provider} · ${trip.date}\n${context.tr('reference')}: ${trip.reference}'
                          : '${trip.provider} · ${trip.date}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _tripStatusLabel(context, trip.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 6),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _tripStatusLabel(BuildContext context, String status) {
    final s = status.toLowerCase().trim();
    if (s == 'ticketed') return context.tr('statusTicketed');
    if (s == 'confirmed') return context.tr('statusConfirmed');
    if (s == 'paid') return context.tr('statusPaid');
    if (s == 'released') return context.tr('statusReleased');
    if (s == 'refunded' || s == 'refund_requested') return context.tr('statusRefunded');
    if (s == 'failed' || s.contains('failed')) return context.tr('statusFailed');
    if (s == 'cancelled' || s == 'canceled') return context.tr('statusCancelled');
    return context.tr('statusPending');
  }
}

