abstract final class AppAssets {
  // Official SaferBe Brand Logos
  /// Dark mode & English: transparent background
  static const logoDarkEn = 'assets/images/logo-01.png';

  /// Dark mode & Arabic: transparent background
  static const logoDarkAr = 'assets/images/logo-02.png';

  /// Light mode & English: light background canvas
  static const logoLightEn = 'assets/images/logo-03.png';

  /// Light mode & Arabic: light background canvas
  static const logoLightAr = 'assets/images/logo-04.png';

  /// Backward-compatible aliases (defaults to transparent background brand logos)
  static const logoAr = logoDarkAr;
  static const logoEn = logoDarkEn;

  /// Returns the correct logo asset path according to brightness, language, and background requirement.
  ///
  /// - When [withoutBackground] is true: returns [logoDarkAr] or [logoDarkEn] (transparent background).
  /// - When [isDark] is true: returns [logoDarkAr] or [logoDarkEn].
  /// - When [isDark] is false and [withoutBackground] is false: returns [logoLightAr] or [logoLightEn].
  static String getLogo({
    required bool isDark,
    required bool isArabic,
    bool withoutBackground = false,
  }) {
    if (withoutBackground || isDark) {
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

