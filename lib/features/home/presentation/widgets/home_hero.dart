import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';

part 'home_hero_actions.dart';

class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.l10n.isArabic;
    final app = AppControllerScope.of(context);
    final greeting = app.isGuest
        ? context.tr('heroTitle')
        : '${context.tr('welcomeBack')}, ${app.user?.name ?? context.tr('traveler')}';
    final subtitle = app.isGuest
        ? context.tr('heroSubtitle')
        : context.tr('heroSubtitleLoggedIn');
    return SizedBox(
      height: 310,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.alula, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66101B2D), Color(0xCC071A33)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        isAr ? AppAssets.logoAr : AppAssets.logoEn,
                        width: 90,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      if (!app.isGuest) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: _GlassPill(
                            icon: Icons.person_rounded,
                            label: app.user?.name ?? '',
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _GlassPill(
                        icon: Icons.star_rounded,
                        label: context.tr('points'),
                      ),
                      const SizedBox(width: 8),
                      const _GlassIcon(icon: Icons.notifications_none_rounded),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .84),
                        height: 1.55,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
