import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/booking_file_helper.dart';
import '../../../../core/widgets/travel_loading_view.dart';
import '../../../support/presentation/pages/safer_be_support_chat_sheet.dart';
import '../../data/repositories/api_trips_repository.dart';
import '../../domain/entities/flight_booking_details.dart';
import '../../domain/entities/trip.dart';

class FlightBookingDetailsPage extends StatefulWidget {
  const FlightBookingDetailsPage({
    required this.bookingReference,
    this.initialTrip,
    this.guestEmail,
    this.guestLastName,
    super.key,
  });

  final String bookingReference;
  final Trip? initialTrip;
  final String? guestEmail;
  final String? guestLastName;

  @override
  State<FlightBookingDetailsPage> createState() =>
      _FlightBookingDetailsPageState();
}

class _FlightBookingDetailsPageState extends State<FlightBookingDetailsPage> {
  final tripsRepository = ApiTripsRepository();

  FlightBookingDetails? bookingDetails;
  bool loading = true;
  bool downloadingTicket = false;
  bool downloadingInvoice = false;
  bool releasingPnr = false;
  bool requestingRefund = false;
  String? errorMessage;
  Timer? pollTimer;
  int pollCount = 0;
  static const int maxPollAttempts = 6;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
    _startPollingIfNeeded();
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  void _startPollingIfNeeded() {
    pollTimer?.cancel();
    pollCount = 0;
    pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      pollCount++;
      if (pollCount > maxPollAttempts) {
        timer.cancel();
        return;
      }
      await _fetchBookingDetails(showLoader: false);
      if (bookingDetails?.isTicketed == true ||
          bookingDetails?.isReleased == true ||
          bookingDetails?.isRefunded == true ||
          bookingDetails?.isFailed == true) {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchBookingDetails({bool showLoader = true}) async {
    if (widget.bookingReference.isEmpty) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = context.tr('bookingNotFound');
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
      final details = await tripsRepository.getFlightBookingDetails(
        widget.bookingReference,
        guestEmail: widget.guestEmail,
        guestLastName: widget.guestLastName,
      );
      if (!mounted) return;
      setState(() {
        bookingDetails = details;
        loading = false;
        errorMessage = null;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        loading = false;
        if (bookingDetails == null) {
          errorMessage = '$exception';
        }
      });
    }
  }

  Future<void> _downloadTicketPdf() async {
    setState(() => downloadingTicket = true);
    try {
      final bytes = await tripsRepository.downloadFlightTicket(
        widget.bookingReference,
      );
      if (bytes.isEmpty) {
        throw 'Empty document received';
      }
      final path = await BookingFileHelper.saveAndOpenDocument(
        bytes: bytes,
        fileName: 'Ticket_${widget.bookingReference}.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('downloadSuccess')} ($path)'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('downloadFailed')}: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => downloadingTicket = false);
    }
  }

  Future<void> _downloadInvoicePdf() async {
    setState(() => downloadingInvoice = true);
    try {
      final bytes = await tripsRepository.downloadFlightInvoice(
        widget.bookingReference,
      );
      if (bytes.isEmpty) {
        throw 'Empty document received';
      }
      final path = await BookingFileHelper.saveAndOpenDocument(
        bytes: bytes,
        fileName: 'Invoice_${widget.bookingReference}.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('downloadSuccess')} ($path)'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('downloadFailed')}: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => downloadingInvoice = false);
    }
  }

  Future<void> _handleReleasePnr() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.cancel_schedule_send_rounded, color: Colors.redAccent, size: 32),
        title: Text(
          context.tr('releaseConfirmTitle'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          context.tr('releaseConfirmBody'),
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('confirmRelease')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => releasingPnr = true);
    try {
      await tripsRepository.releaseFlightBooking(widget.bookingReference);
      pollTimer?.cancel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('bookingReleased')),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchBookingDetails(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => releasingPnr = false);
    }
  }

  Future<void> _handleRequestRefund() async {
    final reasonController = TextEditingController(text: 'Customer request');
    final amountController = TextEditingController(
      text: bookingDetails != null && bookingDetails!.totalPrice > 0
          ? bookingDetails!.totalPrice.toStringAsFixed(2)
          : '',
    );

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_exchange_rounded, color: AppColors.teal, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('requestRefund'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('refundAmount'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                suffixText: bookingDetails?.currency ?? 'SAR',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('refundReason'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: context.tr('refundReason'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(context.tr('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      context.tr('submitRefund'),
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

    if (submitted != true || !mounted) return;

    setState(() => requestingRefund = true);
    try {
      final amount = num.tryParse(amountController.text.trim());
      await tripsRepository.requestFlightRefund(
        widget.bookingReference,
        amount: amount,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('refundSuccess')),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchBookingDetails(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => requestingRefund = false);
    }
  }

  void _copy(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = bookingDetails;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('flightDetailsTitle')),
        actions: [
          IconButton(
            onPressed: () => SaferBeSupportChatSheet.show(
              context,
              bookingReference: widget.bookingReference,
            ),
            icon: const Icon(Icons.support_agent_rounded, color: AppColors.teal),
            tooltip: context.tr('support'),
          ),
          IconButton(
            onPressed: loading ? null : () => _fetchBookingDetails(showLoader: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('refreshStatus'),
          ),
        ],
      ),
      bottomNavigationBar: details != null
          ? _buildBottomActions(context, details)
          : null,
      body: loading && details == null
          ? TravelLoadingView(
              badge: widget.bookingReference,
              title: context.tr('checkingLiveStatus'),
              subtitle: widget.initialTrip?.route,
            )
          : RefreshIndicator(
              onRefresh: () => _fetchBookingDetails(showLoader: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (errorMessage != null && details == null)
                    _buildErrorCard(context, errorMessage!)
                  else ...[
                    _buildStatusBanner(context, details),
                    const SizedBox(height: 16),
                    _buildReferenceCard(context, details),
                    const SizedBox(height: 16),
                    _buildFlightRouteCard(context, details),
                    const SizedBox(height: 16),
                    _buildPassengersCard(context, details),
                    const SizedBox(height: 16),
                    _buildPriceSummaryCard(context, details),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _fetchBookingDetails(showLoader: true),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr('refreshStatus')),
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, FlightBookingDetails? details) {
    final isTicketed = details?.isTicketed ?? false;
    final isConfirmed = details?.isConfirmed ?? false;
    final isReleased = details?.isReleased ?? false;
    final isRefunded = details?.isRefunded ?? false;
    final isFailed = details?.isFailed ?? false;

    final Color color;
    final IconData icon;
    final String title;
    final String description;

    if (isTicketed) {
      color = AppColors.teal;
      icon = Icons.confirmation_number_rounded;
      title = context.tr('statusTicketed');
      description = context.tr('flightBookedDesc');
    } else if (isConfirmed) {
      color = AppColors.teal;
      icon = Icons.check_circle_rounded;
      title = context.tr('bookingConfirmedTitle');
      description = context.tr('bookingConfirmedDesc');
    } else if (isReleased) {
      color = Colors.grey;
      icon = Icons.cancel_outlined;
      title = context.tr('statusReleased');
      description = context.tr('bookingReleased');
    } else if (isRefunded) {
      color = Colors.purple;
      icon = Icons.currency_exchange_rounded;
      title = context.tr('statusRefunded');
      description = context.tr('refundSuccess');
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(BuildContext context, FlightBookingDetails? details) {
    final ref = details?.bookingReference.isNotEmpty == true
        ? details!.bookingReference
        : widget.bookingReference;
    final pnr = details?.pnr ?? widget.initialTrip?.pnr ?? '';
    final ticketNo = details?.ticketNumber ?? '';

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
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _copy(ref, context.tr('referenceCopied')),
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: context.tr('referenceCopied'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            ref,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          if (pnr.isNotEmpty) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('pnr'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    SelectableText(
                      pnr,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _copy(pnr, 'PNR copied'),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (ticketNo.isNotEmpty) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('ticketNumber'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    SelectableText(
                      ticketNo,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.teal),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _copy(ticketNo, 'Ticket number copied'),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlightRouteCard(BuildContext context, FlightBookingDetails? details) {
    final airline = details?.airline.isNotEmpty == true
        ? details!.airline
        : (widget.initialTrip?.provider ?? 'Airline');
    final flightNo = details?.flightNumber ?? '';
    final origin = details?.origin.isNotEmpty == true
        ? details!.origin
        : (widget.initialTrip?.route.split('→').first.trim() ?? '');
    final destination = details?.destination.isNotEmpty == true
        ? details!.destination
        : (widget.initialTrip?.route.split('→').length == 2
            ? widget.initialTrip!.route.split('→').last.trim()
            : '');
    final departure = details?.departureTime.isNotEmpty == true
        ? details!.departureTime
        : (widget.initialTrip?.date ?? '');
    final arrival = details?.arrivalTime ?? '';
    final cabin = details?.cabinClass ?? 'Economy';
    final duration = details?.duration ?? '';

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
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE8FBFF),
                    child: Icon(Icons.flight_takeoff_rounded, color: AppColors.teal, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    airline,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              if (flightNo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    flightNo,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      origin.isNotEmpty ? origin : '--',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      departure,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (duration.isNotEmpty)
                    Text(
                      duration,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.teal),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      destination.isNotEmpty ? destination : '--',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arrival.isNotEmpty ? arrival : '--',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
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
                context.tr('cabinClass'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              Text(
                cabin,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersCard(BuildContext context, FlightBookingDetails? details) {
    final passengers = details?.passengers ?? const [];
    if (passengers.isEmpty) return const SizedBox.shrink();

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
            context.tr('passengerDetails'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...passengers.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: AppColors.teal, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (p.ticketNumber.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${context.tr('ticketNumber')}: ${p.ticketNumber}',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.type,
                      style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard(BuildContext context, FlightBookingDetails? details) {
    final price = details != null && details.totalPrice > 0
        ? details.totalPrice
        : (widget.initialTrip?.price ?? 0);
    final currency = details?.currency.isNotEmpty == true
        ? details!.currency
        : (widget.initialTrip?.currency ?? 'SAR');

    if (price <= 0 || !AppControllerScope.of(context).showPaymentGatewayMobile) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.tr('totalPaid'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '${price.toStringAsFixed(2)} $currency',
            style: const TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, FlightBookingDetails details) {
    final canDownloadTicket = details.canDownloadTicket;
    final canDownloadInvoice = details.canDownloadInvoice;
    final canRelease = details.canRelease;
    final canRefund = details.canRefund;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (downloadingTicket || !canDownloadTicket)
                        ? null
                        : _downloadTicketPdf,
                    icon: downloadingTicket
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.airplane_ticket_rounded, size: 18),
                    label: Text(
                      context.tr('downloadTicket'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (downloadingInvoice || !canDownloadInvoice)
                        ? null
                        : _downloadInvoicePdf,
                    icon: downloadingInvoice
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_long_rounded, size: 18),
                    label: Text(
                      context.tr('downloadInvoice'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (canRelease) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: releasingPnr ? null : _handleReleasePnr,
                icon: releasingPnr
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                      )
                    : const Icon(Icons.cancel_schedule_send_rounded, color: Colors.redAccent, size: 18),
                label: Text(
                  context.tr('releaseBooking'),
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            if (canRefund) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: requestingRefund ? null : _handleRequestRefund,
                icon: requestingRefund
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                      )
                    : const Icon(Icons.currency_exchange_rounded, color: AppColors.orange, size: 18),
                label: Text(
                  context.tr('requestRefund'),
                  style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.orange),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
