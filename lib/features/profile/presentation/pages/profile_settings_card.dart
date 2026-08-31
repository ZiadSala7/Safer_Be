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
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          title: context.tr(
            themeMode == ThemeMode.dark ? 'lightMode' : 'darkMode',
          ),
          onTap: onToggleTheme,
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.support_agent_rounded,
          title: context.tr('help'),
          onTap: () => SaferBeSupportChatSheet.show(context),
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
                isAr ? AppAssets.logoAr : AppAssets.logoEn,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              const Text(
                'v1.1.0 · Safer Be Inc.',
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
          Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(context.tr('explore')),
            ),
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
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

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
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
