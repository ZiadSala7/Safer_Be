import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/travel_content.dart';

class ServiceTile extends StatelessWidget {
  const ServiceTile({required this.service, super.key});

  final QuickService service;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(service.icon, color: AppColors.teal, size: 24),
          const SizedBox(height: 6),
          Text(
            context.tr(service.labelKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}
