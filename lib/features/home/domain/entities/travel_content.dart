import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/image_url_resolver.dart';

/// Represents a gallery image attached to an offer from
/// POST/GET /api/v1/admin/offers/{id}/gallery
class OfferGalleryImage {
  const OfferGalleryImage({
    required this.imageUrl,
    this.altText,
    this.isPrimary = false,
    this.sortOrder = 0,
    this.id,
  });

  final int? id;
  final String imageUrl;
  final String? altText;
  final bool isPrimary;
  final int sortOrder;

  factory OfferGalleryImage.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final url = (json['image_url'] ??
            json['imageUrl'] ??
            json['url'] ??
            json['path'] ??
            json['image'] ??
            '')
        .toString();
    return OfferGalleryImage(
      id: id,
      imageUrl: resolveOfferImageUrl(url),
      altText: json['alt_text']?.toString() ?? json['alt']?.toString(),
      isPrimary: json['is_primary'] == true ||
          json['is_primary'] == 1 ||
          json['primary'] == true,
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'image_url': imageUrl,
    if (altText != null) 'alt_text': altText,
    'is_primary': isPrimary,
    'sort_order': sortOrder,
  };
}

/// Represents a specific condition constraint on an offer
/// e.g. condition_type: "destination", condition_value: "DXB"
class OfferCondition {
  const OfferCondition({
    required this.conditionType,
    required this.conditionValue,
  });

  final String conditionType;
  final String conditionValue;

  factory OfferCondition.fromJson(Map<String, dynamic> json) {
    return OfferCondition(
      conditionType: (json['condition_type'] ?? json['type'] ?? '').toString(),
      conditionValue:
          (json['condition_value'] ?? json['value'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'condition_type': conditionType,
    'condition_value': conditionValue,
  };
}

class TravelOffer {
  const TravelOffer({
    required this.titleKey,
    required this.subtitleKey,
    required this.code,
    required this.image,
    required this.discount,
    this.category = 'all',
    this.id,
    this.discountType = 'percentage',
    this.currency,
    this.validFrom,
    this.validUntil,
    this.maxDiscount,
    this.minBookingAmount,
    this.priority,
    this.status,
    this.type,
    this.usageLimit,
    this.perUserLimit,
    this.conditions = const [],
    this.gallery = const [],
  });

  final int? id;
  final String titleKey;
  final String subtitleKey;
  final String code;
  final String image;
  final int discount;
  final String category;
  final String discountType;
  final String? currency;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final num? maxDiscount;
  final num? minBookingAmount;
  final int? priority;
  final String? status;
  final String? type;
  final int? usageLimit;
  final int? perUserLimit;
  final List<OfferCondition> conditions;
  final List<OfferGalleryImage> gallery;

  String get title => titleKey;
  String get description => subtitleKey;

  String get formattedDiscount {
    if (discountType.toLowerCase() == 'fixed') {
      final curr = currency != null && currency!.isNotEmpty ? currency! : 'SAR';
      return '$discount $curr';
    }
    return '$discount%';
  }

  bool get isExpired {
    if (validUntil == null) return false;
    return validUntil!.isBefore(DateTime.now());
  }

  /// Returns the resolved, fully qualified URL for the main image.
  String get resolvedImageUrl => resolveOfferImageUrl(image);

  /// Appropriate local scenic travel asset used as reliable visual fallback.
  String get fallbackAsset {
    final cat = category.toLowerCase();
    if (cat == 'flights') return AppAssets.jeddah;
    if (cat == 'hotels') return AppAssets.alula;
    if (cat == 'transfers') return AppAssets.transfer;
    return AppAssets.riyadh;
  }

  /// Returns all available images including primary and gallery images.
  List<String> get allImageUrls {
    final list = <String>[];
    final primary = resolvedImageUrl;
    if (primary.isNotEmpty) list.add(primary);
    for (final g in gallery) {
      final gUrl = resolveOfferImageUrl(g.imageUrl);
      if (gUrl.isNotEmpty && !list.contains(gUrl)) {
        list.add(gUrl);
      }
    }
    return list;
  }
}

class Destination {
  const Destination({
    required this.nameKey,
    required this.caption,
    required this.image,
  });
  final String nameKey;
  final String caption;
  final String image;
}

class QuickService {
  const QuickService({required this.labelKey, required this.icon});
  final String labelKey;
  final IconData icon;
}
