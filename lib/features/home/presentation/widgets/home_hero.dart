import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../notifications/data/datasources/notification_store.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        AppAssets.getLogo(
                          isDark: true,
                          isArabic: isAr,
                          withoutBackground: true,
                        ),
                        width: 96,
                        height: 44,
                        fit: BoxFit.contain,
                        cacheHeight: 132,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!app.isGuest) ...[
                              Flexible(
                                child: _GlassPill(
                                  icon: Icons.person_rounded,
                                  label: app.user?.name ?? '',
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: _GlassPill(
                                icon: Icons.star_rounded,
                                label: context.tr('points'),
                              ),
                            ),
                            ValueListenableBuilder<int>(
                              valueListenable: NotificationStore.unreadCountNotifier,
                              builder: (context, unreadCount, _) => _GlassIcon(
                                icon: Icons.notifications_none_rounded,
                                badgeCount: unreadCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
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
