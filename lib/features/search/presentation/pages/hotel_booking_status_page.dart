import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/travel_loading_view.dart';
import '../../../trips/data/repositories/api_trips_repository.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/hotel_booking_details.dart';

class HotelBookingStatusPage extends StatefulWidget {
  const HotelBookingStatusPage({
    required this.bookingReference,
    this.paymentUrl,
    this.hotelName,
    this.supplier,
    this.price,
    this.currency,
    this.checkIn,
    this.checkOut,
    this.roomName,
    super.key,
  });

  final String bookingReference;
  final String? paymentUrl;
  final String? hotelName;
  final String? supplier;
  final num? price;
  final String? currency;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? roomName;

  @override
  State<HotelBookingStatusPage> createState() => _HotelBookingStatusPageState();
}

class _HotelBookingStatusPageState extends State<HotelBookingStatusPage> {
  final repository = ApiTravelSearchRepository();
  final tripsRepository = ApiTripsRepository();
  final paymentIdController = TextEditingController();

  HotelBookingDetails? bookingDetails;
  bool loading = true;
  bool verifyingCallback = false;
  String? errorMessage;
  String? callbackMessage;
  Timer? pollTimer;
  int pollCount = 0;
  static const int maxPollAttempts = 8;

  @override
  void initState() {
    super.initState();
    _fetchBookingStatus();
    _startPolling();
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    paymentIdController.dispose();
    super.dispose();
  }

  void _startPolling() {
    pollTimer?.cancel();
    pollCount = 0;
    pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      pollCount++;
      if (pollCount > maxPollAttempts) {
        timer.cancel();
        return;
      }
      await _fetchBookingStatus(showLoader: false);
      if (bookingDetails?.isConfirmed == true ||
          bookingDetails?.isFailed == true ||
          bookingDetails?.isCancelled == true) {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchBookingStatus({bool showLoader = true}) async {
    if (widget.bookingReference.isEmpty) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Missing booking reference';
        });
      }
      return;
    }
    if (showLoader && mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final details = await repository.getHotelBookingDetails(
        widget.bookingReference,
      );
      if (!mounted) return;
      setState(() {
        bookingDetails = details;
        loading = false;
        errorMessage = null;
      });

      // Synchronize live status with local trips
      await tripsRepository.saveTrip(
        Trip(
          route: details.hotelName.isNotEmpty
              ? details.hotelName
              : (widget.hotelName ?? 'Hotel Stay'),
          date: details.checkIn.isNotEmpty
              ? details.checkIn
              : (widget.checkIn?.toIso8601String().split('T').first ?? ''),
          provider: details.supplier.isNotEmpty
              ? details.supplier.toUpperCase()
              : (widget.supplier?.toUpperCase() ?? 'HOTEL'),
          reference: widget.bookingReference,
          type: 'hotel',
          status: details.status,
        ),
      );
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        loading = false;
        // Don't overwrite if we already have data
        if (bookingDetails == null) {
          errorMessage = '$exception';
        }
      });
    }
  }

  Future<void> _verifyPaymentCallback() async {
    final paymentId = paymentIdController.text.trim();
    if (paymentId.isEmpty) return;
    setState(() {
      verifyingCallback = true;
      callbackMessage = null;
    });

    try {
      final result = await repository.verifyHotelPaymentCallback(paymentId);
      if (!mounted) return;
      setState(() {
        callbackMessage = result.isPaid
            ? context.tr('callbackVerifiedSuccess')
            : (result.message.isNotEmpty
                ? result.message
                : context.tr('callbackVerifiedFailed'));
      });
      await _fetchBookingStatus(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        callbackMessage = '${context.tr('callbackVerifiedFailed')}: $e';
      });
    } finally {
      if (mounted) setState(() => verifyingCallback = false);
    }
  }

  Future<void> _openPayment() async {
    final url = widget.paymentUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _copyReference() {
    Clipboard.setData(ClipboardData(text: widget.bookingReference));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('referenceCopied')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(BuildContext context, String rawDate, DateTime? fallback) {
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        return MaterialLocalizations.of(context).formatShortDate(parsed);
      }
      return rawDate;
    }
    if (fallback != null) {
      return MaterialLocalizations.of(context).formatShortDate(fallback);
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    final details = bookingDetails;
    final isConfirmed = details?.isConfirmed ?? false;
    final isPending = details == null ? true : details.isPending;
    final isFailed = details?.isFailed ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('bookingStatusTitle')),
        actions: [
          IconButton(
            onPressed: loading ? null : () => _fetchBookingStatus(showLoader: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('refreshStatus'),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context, isConfirmed, isPending, isFailed),
      body: loading && details == null
          ? TravelLoadingView(
              badge: widget.bookingReference,
              title: context.tr('checkingLiveStatus'),
              subtitle: widget.hotelName,
            )
          : RefreshIndicator(
              onRefresh: () => _fetchBookingStatus(showLoader: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _buildStatusBanner(context, isConfirmed, isPending, isFailed),
                  const SizedBox(height: 16),
                  _buildReferenceCard(context),
                  const SizedBox(height: 16),
                  _buildDetailsCard(context, details),
                  const SizedBox(height: 16),
                  _buildPaymentVerificationCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    bool isConfirmed,
    bool isPending,
    bool isFailed,
  ) {
    final Color color;
    final IconData icon;
    final String title;
    final String description;

    if (isConfirmed) {
      color = AppColors.teal;
      icon = Icons.check_circle_rounded;
      title = context.tr('bookingConfirmedTitle');
      description = context.tr('bookingConfirmedDesc');
    } else if (isFailed) {
      color = Colors.redAccent;
      icon = Icons.error_outline_rounded;
      title = context.tr('paymentFailedTitle');
      description = context.tr('paymentFailedDesc');
    } else {
      color = AppColors.orange;
      icon = Icons.hourglass_top_rounded;
      title = context.tr('paymentPendingTitle');
      description = context.tr('paymentPendingDesc');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(BuildContext context) {
    final statusText = bookingDetails != null
        ? _statusLabel(context, bookingDetails!.status)
        : context.tr('statusPending');
    final isConfirmed = bookingDetails?.isConfirmed ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('bookingReference'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isConfirmed ? AppColors.teal : AppColors.orange)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: isConfirmed ? AppColors.teal : AppColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  widget.bookingReference,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: _copyReference,
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: context.tr('referenceCopied'),
              ),
            ],
          ),
          if (bookingDetails?.confirmationNumber.isNotEmpty == true) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('confirmationCode'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  bookingDetails!.confirmationNumber,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
          if (bookingDetails?.supplierBookingId.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('supplierBookingId'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  bookingDetails!.supplierBookingId,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, HotelBookingDetails? details) {
    final hotelName = details?.hotelName.isNotEmpty == true
        ? details!.hotelName
        : (widget.hotelName ?? 'Hotel Stay');
    final supplier = details?.supplier.isNotEmpty == true
        ? details!.supplier
        : (widget.supplier ?? 'juniper');
    final price = details != null && details.totalPrice > 0
        ? details.totalPrice
        : (widget.price ?? 0);
    final currency = details?.currency.isNotEmpty == true
        ? details!.currency
        : (widget.currency ?? 'SAR');
    final checkIn = _formatDate(context, details?.checkIn ?? '', widget.checkIn);
    final checkOut = _formatDate(context, details?.checkOut ?? '', widget.checkOut);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('hotelDetails'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hotelName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (widget.roomName != null && widget.roomName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.roomName!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('checkInDate'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      checkIn,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.tr('checkOutDate'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      checkOut,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('provider'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                supplier.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (details?.leadGuestName.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('guestName'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  details!.leadGuestName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
          if (price > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('totalPaid'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${price.toStringAsFixed(2)} $currency',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentVerificationCard(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      title: Text(
        context.tr('verifyByPaymentId'),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      leading: const Icon(Icons.verified_user_outlined, color: AppColors.teal),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('enterPaymentId'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: paymentIdController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: '123456789',
                        prefixIcon: Icon(Icons.tag_rounded),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: verifyingCallback ? null : _verifyPaymentCallback,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size(70, 48),
                    ),
                    child: verifyingCallback
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.tr('verifyNow')),
                  ),
                ],
              ),
              if (callbackMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  callbackMessage!,
                  style: TextStyle(
                    color: callbackMessage!.contains('success') ||
                            callbackMessage!.contains('نجاح')
                        ? AppColors.teal
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    bool isConfirmed,
    bool isPending,
    bool isFailed,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPending && widget.paymentUrl != null && widget.paymentUrl!.isNotEmpty)
              FilledButton.icon(
                onPressed: _openPayment,
                icon: const Icon(Icons.payment_rounded),
                label: Text(
                  context.tr('reopenPaymentGateway'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            if (isPending && widget.paymentUrl != null && widget.paymentUrl!.isNotEmpty)
              const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _fetchBookingStatus(showLoader: true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('refreshStatus'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('backToHome'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, String raw) {
    final s = raw.toLowerCase().trim();
    if (s == 'confirmed' || s == 'ticketed' || s == 'completed') {
      return context.tr('statusConfirmed');
    }
    if (s == 'paid') {
      return context.tr('statusPaid');
    }
    if (s == 'failed' || s.contains('failed') || s == 'rejected') {
      return context.tr('statusFailed');
    }
    if (s == 'cancelled' || s == 'canceled' || s == 'released') {
      return context.tr('statusCancelled');
    }
    return context.tr('statusPending');
  }
}
