import 'package:flutter/material.dart';

class TravelOffer {
  const TravelOffer({
    required this.titleKey,
    required this.subtitleKey,
    required this.code,
    required this.image,
    required this.discount,
    this.category = 'all',
  });
  final String titleKey;
  final String subtitleKey;
  final String code;
  final String image;
  final int discount;
  final String category;
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
