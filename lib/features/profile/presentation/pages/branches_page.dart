import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/whatsapp_helper.dart';

class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final branches = [
      _BranchData(
        titleKey: 'riyadhBranch',
        addressKey: 'riyadhBranchAddress',
        phone: '920011244',
        mapUrl: 'https://maps.google.com/?q=Majdoul+Tower+Riyadh',
      ),
      _BranchData(
        titleKey: 'jeddahBranch',
        addressKey: 'jeddahBranchAddress',
        phone: '920011244',
        mapUrl: 'https://maps.google.com/?q=Al+Andalus+Jeddah',
      ),
      _BranchData(
        titleKey: 'khobarBranch',
        addressKey: 'khobarBranchAddress',
        phone: '920011244',
        mapUrl: 'https://maps.google.com/?q=Al+Rashid+Mall+Al+Khobar',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('branches'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: branches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final branch = branches[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.teal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(branch.titleKey),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(branch.addressKey),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('workingHours'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('tel:${branch.phone}');
                            await launchUrl(uri);
                          },
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          label: Text(context.tr('callUsNow')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(branch.mapUrl);
                            if (uri != null) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: Text(context.tr('openInMaps')),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => AppWhatsAppHelper.launchWhatsApp(),
                        icon: const Icon(
                          Icons.chat_rounded,
                          color: Color(0xFF16A34A),
                        ),
                        tooltip: 'WhatsApp',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BranchData {
  final String titleKey;
  final String addressKey;
  final String phone;
  final String mapUrl;

  const _BranchData({
    required this.titleKey,
    required this.addressKey,
    required this.phone,
    required this.mapUrl,
  });
}
