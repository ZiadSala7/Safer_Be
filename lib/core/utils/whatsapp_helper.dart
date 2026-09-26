import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/home/domain/entities/travel_content.dart';
import '../../features/search/domain/entities/flight_offer.dart';
import '../../features/search/domain/entities/flight_search.dart';
import '../../features/search/domain/entities/hotel_offer.dart';
import '../localization/app_localizations.dart';

/// Centralized utility and UI widgets for WhatsApp communication and WhatsApp Contact Mode
/// according to the System Settings API specification (`show_payment_gateway_mobile = false`).
class AppWhatsAppHelper {
  AppWhatsAppHelper._();

  /// Default Safer Be official WhatsApp contact phone number.
  static const String defaultPhoneNumber = '966920011244';

  /// Default WhatsApp web link.
  static const String defaultWaUrl = 'https://wa.me/$defaultPhoneNumber';

  /// Launches WhatsApp with an optional prefilled message and target phone number.
  static Future<bool> launchWhatsApp({
    String? text,
    String? phoneNumber,
  }) async {
    final phone = (phoneNumber != null && phoneNumber.isNotEmpty)
        ? phoneNumber
        : defaultPhoneNumber;

    final query = (text != null && text.trim().isNotEmpty)
        ? '?text=${Uri.encodeComponent(text.trim())}'
        : '?text=Hello';

    final uri = Uri.parse('https://wa.me/$phone$query');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Launches WhatsApp with contextual flight inquiry details.
  static Future<bool> launchFlightInquiry({
    required BuildContext context,
    required FlightOffer offer,
    FlightSearch? search,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final cabin = resolveFlightCabinName(
      offerCabin: offer.cabinClass,
      searchCabinClass: search?.cabinClass ?? 1,
      isAr: isAr,
    );

    final departureDateStr = offer.departureTime != null
        ? '${offer.departureTime!.year}-${offer.departureTime!.month.toString().padLeft(2, '0')}-${offer.departureTime!.day.toString().padLeft(2, '0')}'
        : (search != null
            ? '${search.departure.year}-${search.departure.month.toString().padLeft(2, '0')}-${search.departure.day.toString().padLeft(2, '0')}'
            : '');

    final String message;
    if (isAr) {
      message = 'السلام عليكم سفر بي، أود الاستفسار وحجز الرحلة التالية:\n'
          '✈️ طيران: ${offer.airline}\n'
          '📍 المسار: ${offer.route.isNotEmpty ? offer.route : '${search?.origin ?? ''} → ${search?.destination ?? ''}'}\n'
          '📅 التاريخ: $departureDateStr\n'
          '💺 الدرجة: $cabin\n'
          '🔢 الرمز المرجعي: ${offer.referenceIndex ?? offer.id}';
    } else {
      message = 'Hello Safer Be, I would like to inquire about and book this flight:\n'
          '✈️ Airline: ${offer.airline}\n'
          '📍 Route: ${offer.route.isNotEmpty ? offer.route : '${search?.origin ?? ''} → ${search?.destination ?? ''}'}\n'
          '📅 Date: $departureDateStr\n'
          '💺 Cabin: $cabin\n'
          '🔢 Ref: ${offer.referenceIndex ?? offer.id}';
    }

    return launchWhatsApp(text: message);
  }

  /// Launches WhatsApp with contextual hotel inquiry details.
  static Future<bool> launchHotelInquiry({
    required BuildContext context,
    required HotelOffer offer,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final String message;
    if (isAr) {
      message = 'السلام عليكم سفر بي، أود الاستفسار وحجز الإقامة في الفندق التالي:\n'
          '🏨 الفندق: ${offer.name}\n'
          '📍 الموقع: ${offer.location.isNotEmpty ? offer.location : 'غير محدد'}\n'
          '⭐ التقييم: ${offer.rating > 0 ? '${offer.rating} نجوم' : '—'}\n'
          '🔢 الكود: ${offer.code}';
    } else {
      message = 'Hello Safer Be, I would like to inquire about and book a stay at:\n'
          '🏨 Hotel: ${offer.name}\n'
          '📍 Location: ${offer.location.isNotEmpty ? offer.location : 'N/A'}\n'
          '⭐ Rating: ${offer.rating > 0 ? '${offer.rating} stars' : '—'}\n'
          '🔢 Code: ${offer.code}';
    }

    return launchWhatsApp(text: message);
  }

  /// Launches WhatsApp with contextual offer details.
  static Future<bool> launchOfferInquiry({
    required BuildContext context,
    required TravelOffer offer,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = context.tr(offer.titleKey);

    final String message;
    if (isAr) {
      message = 'السلام عليكم سفر بي، أود الاستفسار والاستفادة من العرض التالي:\n'
          '🏷️ العرض: $title\n'
          '🎟️ كود العرض: ${offer.code.isNotEmpty ? offer.code : '—'}\n'
          '💰 الخصم: ${offer.formattedDiscount}';
    } else {
      message = 'Hello Safer Be, I would like to inquire about and use this offer:\n'
          '🏷️ Offer: $title\n'
          '🎟️ Promo Code: ${offer.code.isNotEmpty ? offer.code : '—'}\n'
          '💰 Discount: ${offer.formattedDiscount}';
    }

    return launchWhatsApp(text: message);
  }
}

/// A standard WhatsApp primary button for replacing booking actions in WhatsApp Contact Mode.
class WhatsAppBookingButton extends StatelessWidget {
  const WhatsAppBookingButton({
    required this.onPressed,
    this.label,
    this.iconSize = 20,
    this.fontSize = 15,
    this.height = 52,
    this.padding,
    super.key,
  });

  final VoidCallback onPressed;
  final String? label;
  final double iconSize;
  final double fontSize;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.chat_rounded, size: iconSize),
        label: Text(
          label ?? context.tr('contactViaWhatsApp'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
          elevation: 2,
        ),
      ),
    );
  }
}

/// An informative card shown in details pages when WhatsApp Contact Mode is active.
class WhatsAppInquiryBannerCard extends StatelessWidget {
  const WhatsAppInquiryBannerCard({
    required this.onPressed,
    this.title,
    this.subtitle,
    super.key,
  });

  final VoidCallback onPressed;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16A34A).withValues(alpha: 0.15)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF16A34A).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? context.tr('contactViaWhatsApp'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle ?? context.tr('whatsAppConsultation'),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('inquireViaWhatsApp'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
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
}
