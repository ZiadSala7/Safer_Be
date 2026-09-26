part of 'profile_page.dart';

class _ProfileSettingsCard extends StatelessWidget {
  const _ProfileSettingsCard({
    required this.themeMode,
    required this.onToggleLocale,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        _SettingsTile(
          icon: Icons.language_rounded,
          title: context.tr('language'),
          onTap: onToggleLocale,
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: themeMode == ThemeMode.dark
              ? Icons.dark_mode_outlined
              : Icons.light_mode_outlined,
          title: context.tr('theme'),
          value: context.tr(
            themeMode == ThemeMode.dark ? 'darkMode' : 'lightMode',
          ),
          onTap: () => _showThemeDialog(context),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.support_agent_rounded,
          title: context.tr('help'),
          onTap: () => SaferBeSupportChatSheet.show(context),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.chat_rounded,
          title: context.tr('chatWhatsApp'),
          value: '9200 11 244',
          onTap: () async {
            final uri = Uri.tryParse('https://wa.me/966920011244?text=Hello');
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.share_rounded,
          title: context.tr('shareApp'),
          value: 'Google Play & iOS',
          onTap: () => ShareAppSheet.show(context),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          title: context.tr('about'),
          onTap: () => _showAboutAppDialog(context),
        ),
      ],
    ),
  );

  void _showThemeDialog(BuildContext context) {
    final app = AppControllerScope.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.palette_outlined, color: AppColors.teal),
            const SizedBox(width: 10),
            Text(context.tr('chooseTheme')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.light_mode_rounded, color: AppColors.orange),
              title: Text(
                context.tr('lightMode'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: app.themeMode == ThemeMode.light
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
                  : null,
              onTap: () {
                app.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.dark_mode_rounded, color: AppColors.teal),
              title: Text(
                context.tr('darkMode'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: app.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
                  : null,
              onTap: () {
                app.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.getLogo(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  isArabic: isAr,
                  withoutBackground: true,
                ),
                height: 48,
                fit: BoxFit.contain,
                cacheHeight: 144,
              ),
              const SizedBox(height: 8),
              const Text(
                'v1.2.1 · Safer Be Inc.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        content: Text(
          isAr
              ? 'سافر بي — منصة السفر السعودية المتكاملة لحجز الطيران، الفنادق، والتنقلات بأعلى معايير الأمان والراحة.'
              : 'Safer Be — The premier Saudi travel platform for seamless flight, hotel, and transfer bookings with 24/7 dedicated support.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ShareAppSheet.show(context);
                },
                icon: const Icon(Icons.share_rounded, size: 15),
                label: Text(context.tr('shareApp')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(context.tr('explore')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? value;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.teal, size: 20),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null) ...[
          Text(
            value!,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
        ],
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}
