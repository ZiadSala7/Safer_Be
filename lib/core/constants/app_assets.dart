abstract final class AppAssets {
  // Official SaferBe Brand Logos
  /// Dark mode & English: crisp white & orange for dark theme
  static const logoDarkEn = 'assets/images/logo_dark_en.png';

  /// Dark mode & Arabic: crisp white & orange for dark theme
  static const logoDarkAr = 'assets/images/logo_dark_ar.png';

  /// Light mode & English: navy & orange
  static const logoLightEn = 'assets/images/logo-01.png';

  /// Light mode & Arabic: navy & orange
  static const logoLightAr = 'assets/images/logo-02.png';

  /// Backward-compatible aliases
  static const logoAr = logoDarkAr;
  static const logoEn = logoDarkEn;

  /// Returns the correct logo asset path according to brightness and language.
  static String getLogo({
    required bool isDark,
    required bool isArabic,
    bool withoutBackground = false,
  }) {
    if (isDark) {
      return isArabic ? logoDarkAr : logoDarkEn;
    }
    return isArabic ? logoLightAr : logoLightEn;
  }
  static const brandSymbol = 'assets/images/saferBeUnique.png';
  static const brandCropped = 'assets/images/safer_be_logo_cropped.png';
  static const appIcon = 'assets/images/app_icon_safer_be.png';
  static const monochromeLogo = 'assets/images/ic_launcher_monochrome.png';
  static const alula = 'assets/images/destinations/alula_hero.png';
  static const riyadh = 'assets/images/destinations/riyadh.png';
  static const jeddah = 'assets/images/destinations/jeddah.png';
  static const transfer = 'assets/images/destinations/airport_transfer.png';
  static const onboardingDiscover = 'assets/images/onboarding/discover.webp';
  static const onboardingPlan = 'assets/images/onboarding/plan.webp';
  static const onboardingSupport = 'assets/images/onboarding/support.webp';
}

