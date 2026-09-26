import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../offers/presentation/pages/offers_page.dart';
import '../../../search/presentation/pages/hotel_booking_status_page.dart';
import '../../../trips/presentation/pages/flight_booking_details_page.dart';
import '../../data/datasources/notification_store.dart';
import '../../domain/entities/notification_payload.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<StoredNotification>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = NotificationStore.getNotifications();
    });
  }

  Future<void> _handleNotificationTap(StoredNotification item) async {
    if (!item.isRead) {
      await NotificationStore.markAsRead(item.id);
      _load();
    }

    final payload = item.payload;
    if (payload == null) return;

    if (!mounted) return;

    if (payload.isBookingEvent) {
      final ref = payload.bookingReference;
      if (ref != null && ref.isNotEmpty) {
        if (payload.isHotel) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HotelBookingStatusPage(bookingReference: ref),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlightBookingDetailsPage(bookingReference: ref),
            ),
          );
        }
        return;
      }
    }

    if (payload.isOfferEvent) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OffersPage(
            initialOfferId: payload.offerId,
            isStandalone: true,
          ),
        ),
      );
      return;
    }
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (difference.inMinutes < 1) {
      return isAr ? 'الآن' : 'Just now';
    } else if (difference.inMinutes < 60) {
      return isAr
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return isAr
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return isAr
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays}d ago';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  IconData _getIconForType(String type, NotificationPayload? payload) {
    if (payload?.isHotel == true) return Icons.hotel_rounded;
    if (payload?.isFlight == true || type.contains('flight') || type.contains('booking')) {
      return Icons.flight_takeoff_rounded;
    }
    if (payload?.isOfferEvent == true || type.contains('offer')) {
      return Icons.local_offer_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getIconBgColor(String type, NotificationPayload? payload) {
    if (payload?.isHotel == true) return AppColors.orange.withValues(alpha: 0.15);
    if (payload?.isOfferEvent == true || type.contains('offer')) {
      return const Color(0xFFFFB23F).withValues(alpha: 0.15);
    }
    return AppColors.teal.withValues(alpha: 0.15);
  }

  Color _getIconColor(String type, NotificationPayload? payload) {
    if (payload?.isHotel == true) return AppColors.orange;
    if (payload?.isOfferEvent == true || type.contains('offer')) {
      return const Color(0xFFFF9500);
    }
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('notifications'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              if (value == 'markAllAsRead') {
                await NotificationStore.markAllAsRead();
                _load();
              } else if (value == 'clearAll') {
                await NotificationStore.clearAll();
                _load();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('allNotificationsCleared')),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'markAllAsRead',
                child: Row(
                  children: [
                    const Icon(Icons.done_all_rounded, size: 20, color: AppColors.teal),
                    const SizedBox(width: 10),
                    Text(context.tr('markAllAsRead')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clearAll',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('clearAll'),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<StoredNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications = snapshot.data ?? const [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined,
                        size: 40,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('noNotifications'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('noNotificationsDesc'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final iconBg = _getIconBgColor(item.type, item.payload);
                final iconColor = _getIconColor(item.type, item.payload);
                final icon = _getIconForType(item.type, item.payload);

                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await NotificationStore.deleteNotification(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('notificationDeleted')),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: InkWell(
                    onTap: () => _handleNotificationTap(item),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: item.isRead
                            ? Theme.of(context).colorScheme.surface
                            : (isDark
                                ? AppColors.teal.withValues(alpha: 0.08)
                                : const Color(0xFFF0F9FA)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.isRead
                              ? (isDark ? Colors.white10 : Colors.black12)
                              : AppColors.teal.withValues(alpha: 0.35),
                          width: item.isRead ? 1 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(icon, color: iconColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title.isEmpty ? 'Safer Be' : item.title,
                                        style: TextStyle(
                                          fontWeight: item.isRead
                                              ? FontWeight.w700
                                              : FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!item.isRead) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.teal,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (item.body.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    item.body,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      height: 1.4,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  _formatTime(context, item.timestamp),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
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
              },
            ),
          );
        },
      ),
    );
  }
}
