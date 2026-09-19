import '../../../../core/network/json_read.dart';
import '../../../../core/utils/image_url_resolver.dart';
import '../../../home/domain/entities/travel_content.dart';

/// Represents a marketing offer retrieved from GET /api/v1/offers/available
/// according to Traveling Safer API V1 - Offers Module Documentation.
class MarketingOffer extends TravelOffer {
  const MarketingOffer({
    required super.titleKey,
    required super.subtitleKey,
    required super.code,
    required super.image,
    required super.discount,
    super.id,
    super.discountType = 'percentage',
    super.currency,
    super.validFrom,
    super.validUntil,
    super.category = 'all',
    super.maxDiscount,
    super.minBookingAmount,
    super.priority,
    super.status,
    super.type,
    super.usageLimit,
    super.perUserLimit,
    super.conditions = const [],
    super.gallery = const [],
  });

  factory MarketingOffer.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final title = readText(
      json,
      ['title', 'name', 'titleKey'],
      'Special Offer',
    );
    final description = readText(
      json,
      ['description', 'subtitle', 'subtitleKey', 'details', 'alt_text'],
      '',
    );
    final code = readText(
      json,
      ['code', 'promo_code', 'coupon', 'coupon_code'],
      '',
    );
    final discountType = readText(
      json,
      ['discount_type', 'type'],
      'percentage',
    ).toLowerCase();
    final discountVal = readNumber(
      json,
      ['discount_value', 'discount', 'value', 'amount'],
      0,
    );
    final currency = json['currency']?.toString();

    final rawMax = readNumber(json, ['max_discount', 'maxDiscount'], 0);
    final maxDiscount = rawMax > 0 ? rawMax : null;

    final rawMin = readNumber(
      json,
      ['min_booking_amount', 'minBookingAmount', 'min_spend'],
      0,
    );
    final minBookingAmount = rawMin > 0 ? rawMin : null;

    final rawPriority = readNumber(json, ['priority'], 0).toInt();
    final priority = rawPriority > 0 ? rawPriority : null;

    final status = readText(json, ['status', 'state'], 'active');
    final offerType = readText(json, ['type', 'offer_type'], '');

    final rawUsage = readNumber(
      json,
      ['usage_limit', 'usageLimit'],
      0,
    ).toInt();
    final usageLimit = rawUsage > 0 ? rawUsage : null;

    final rawPerUser = readNumber(
      json,
      ['per_user_limit', 'perUserLimit'],
      0,
    ).toInt();
    final perUserLimit = rawPerUser > 0 ? rawPerUser : null;

    DateTime? validFrom;
    for (final k in ['valid_from', 'starts_at', 'start_date', 'from']) {
      if (json[k] != null) {
        validFrom = DateTime.tryParse(json[k].toString());
        if (validFrom != null) break;
      }
    }

    DateTime? validUntil;
    for (final k in ['valid_until', 'ends_at', 'end_date', 'until']) {
      if (json[k] != null) {
        validUntil = DateTime.tryParse(json[k].toString());
        if (validUntil != null) break;
      }
    }

    // Parse conditions
    final List<OfferCondition> conditions = [];
    final rawConditions = json['conditions'];
    if (rawConditions is List) {
      for (final c in rawConditions) {
        if (c is Map<String, dynamic>) {
          conditions.add(OfferCondition.fromJson(c));
        } else if (c is Map) {
          conditions.add(OfferCondition.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    // Parse gallery
    final List<OfferGalleryImage> gallery = [];
    final rawGallery = json['gallery'] ??
        json['images'] ??
        json['photos'] ??
        json['gallery_images'];
    if (rawGallery is List) {
      for (final g in rawGallery) {
        if (g is Map<String, dynamic>) {
          gallery.add(OfferGalleryImage.fromJson(g));
        } else if (g is Map) {
          gallery.add(
            OfferGalleryImage.fromJson(Map<String, dynamic>.from(g)),
          );
        } else if (g is String && g.trim().isNotEmpty) {
          gallery.add(OfferGalleryImage(imageUrl: g.trim()));
        }
      }
    }

    // Find main image URL
    String? rawImageUrl;
    for (final key in [
      'image_url',
      'imageUrl',
      'image',
      'photo_url',
      'photoUrl',
      'banner_url',
      'bannerUrl',
      'thumbnail_url',
      'thumbnailUrl',
      'thumbnail',
      'banner',
      'photo',
      'cover_image',
      'primary_image',
    ]) {
      final val = json[key];
      if (val is String && val.trim().isNotEmpty) {
        rawImageUrl = val.trim();
        break;
      } else if (val is Map) {
        final nested =
            val['url'] ?? val['image_url'] ?? val['path'] ?? val['src'];
        if (nested != null && nested.toString().trim().isNotEmpty) {
          rawImageUrl = nested.toString().trim();
          break;
        }
      }
    }

    if (rawImageUrl == null || rawImageUrl.isEmpty) {
      final primary = gallery.where((g) => g.isPrimary).firstOrNull ??
          gallery.firstOrNull;
      if (primary != null) {
        rawImageUrl = primary.imageUrl;
      }
    }

    final imageUrl = resolveOfferImageUrl(rawImageUrl);

    final specifiedCategory = readText(json, ['category'], '').toLowerCase();
    final category = specifiedCategory.isNotEmpty
        ? specifiedCategory
        : inferCategory(title, description, offerType: offerType, conditions: conditions);

    return MarketingOffer(
      id: id,
      titleKey: title,
      subtitleKey: description,
      code: code,
      image: imageUrl,
      discount: discountVal.toInt(),
      discountType: discountType,
      currency: currency,
      validFrom: validFrom,
      validUntil: validUntil,
      category: category,
      maxDiscount: maxDiscount,
      minBookingAmount: minBookingAmount,
      priority: priority,
      status: status,
      type: offerType,
      usageLimit: usageLimit,
      perUserLimit: perUserLimit,
      conditions: conditions,
      gallery: gallery,
    );
  }

  factory MarketingOffer.fromTravelOffer(TravelOffer offer) {
    if (offer is MarketingOffer) return offer;
    return MarketingOffer(
      id: offer.id,
      titleKey: offer.titleKey,
      subtitleKey: offer.subtitleKey,
      code: offer.code,
      image: offer.image,
      discount: offer.discount,
      discountType: offer.discountType,
      currency: offer.currency,
      validFrom: offer.validFrom,
      validUntil: offer.validUntil,
      category: offer.category,
      maxDiscount: offer.maxDiscount,
      minBookingAmount: offer.minBookingAmount,
      priority: offer.priority,
      status: offer.status,
      type: offer.type,
      usageLimit: offer.usageLimit,
      perUserLimit: offer.perUserLimit,
      conditions: offer.conditions,
      gallery: offer.gallery,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'title': titleKey,
    'description': subtitleKey,
    'code': code,
    'discount_type': discountType,
    'discount_value': discount,
    if (currency != null) 'currency': currency,
    if (validFrom != null) 'valid_from': validFrom!.toIso8601String(),
    if (validUntil != null) 'valid_until': validUntil!.toIso8601String(),
    'image_url': image,
    'category': category,
    if (maxDiscount != null) 'max_discount': maxDiscount,
    if (minBookingAmount != null) 'min_booking_amount': minBookingAmount,
    if (priority != null) 'priority': priority,
    if (status != null) 'status': status,
    if (type != null) 'type': type,
    if (usageLimit != null) 'usage_limit': usageLimit,
    if (perUserLimit != null) 'per_user_limit': perUserLimit,
    if (conditions.isNotEmpty)
      'conditions': conditions.map((c) => c.toJson()).toList(),
    if (gallery.isNotEmpty)
      'gallery': gallery.map((g) => g.toJson()).toList(),
  };

  /// Infers offer category based on title, description, offerType, and conditions.
  static String inferCategory(
    String title,
    String description, {
    String offerType = '',
    List<OfferCondition> conditions = const [],
  }) {
    final t = offerType.toLowerCase();
    if (t == 'flight' || t == 'flights') return 'flights';
    if (t == 'hotel' || t == 'hotels' || t == 'stay') return 'hotels';
    if (t == 'transfer' || t == 'transfers' || t == 'chauffeur') return 'transfers';
    if (t == 'domestic') return 'domestic';

    for (final c in conditions) {
      final type = c.conditionType.toLowerCase();
      final val = c.conditionValue.toLowerCase();
      if (type == 'destination') {
        if (val == 'dxb' || val == 'cai' || val == 'lhr' || val == 'ist') {
          return 'flights';
        }
      }
      if (type == 'airline') return 'flights';
      if (type == 'hotel') return 'hotels';
    }

    final text = '$title $description'.toLowerCase();
    if (text.contains('transfer') ||
        text.contains('chauffeur') ||
        text.contains('taxi') ||
        text.contains('car') ||
        text.contains('ride') ||
        text.contains('drive') ||
        text.contains('pickup') ||
        text.contains('توصيل') ||
        text.contains('نقل') ||
        text.contains('سيارة')) {
      return 'transfers';
    }
    if (text.contains('hotel') ||
        text.contains('resort') ||
        text.contains('stay') ||
        text.contains('room') ||
        text.contains('suite') ||
        text.contains('فندق') ||
        text.contains('فنادق') ||
        text.contains('منتجع') ||
        text.contains('إقامة') ||
        text.contains('غرفة')) {
      return 'hotels';
    }
    if (text.contains('flight') ||
        text.contains('dxb') ||
        text.contains('airline') ||
        text.contains('airport') ||
        text.contains('fly') ||
        text.contains('طيران') ||
        text.contains('رحلات') ||
        text.contains('رحلة')) {
      return 'flights';
    }
    if (text.contains('domestic') ||
        text.contains('saudi') ||
        text.contains('riyadh') ||
        text.contains('jeddah') ||
        text.contains('alula') ||
        text.contains('dammam') ||
        text.contains('موسم') ||
        text.contains('سياحة') ||
        text.contains('العلا') ||
        text.contains('الرياض') ||
        text.contains('جدة') ||
        text.contains('الدمام') ||
        text.contains('داخلي')) {
      return 'domestic';
    }
    return 'all';
  }
}
