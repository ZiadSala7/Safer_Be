import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/entities/travel_content.dart';
import '../../domain/repositories/home_repository.dart';

class LocalHomeRepository implements HomeRepository {
  @override
  List<TravelOffer> get offers => const [];

  @override
  List<Destination> get destinations => const [
    Destination(nameKey: 'riyadh', caption: 'KAFD', image: AppAssets.riyadh),
    Destination(nameKey: 'jeddah', caption: 'Red Sea', image: AppAssets.jeddah),
    Destination(
      nameKey: 'alulaTitle',
      caption: 'Heritage & nature',
      image: AppAssets.alula,
    ),
  ];

  @override
  List<QuickService> get services => const [
    QuickService(labelKey: 'flights', icon: Icons.flight_takeoff_rounded),
    QuickService(labelKey: 'hotels', icon: Icons.hotel_rounded),
    QuickService(
      labelKey: 'transfers',
      icon: Icons.directions_car_filled_rounded,
    ),
    QuickService(labelKey: 'business', icon: Icons.business_center_rounded),
  ];
}
