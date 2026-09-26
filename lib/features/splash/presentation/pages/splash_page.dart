import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/data/repositories/local_onboarding_repository.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../shell/presentation/pages/app_shell.dart';
import '../../data/repositories/splash_timing_repository.dart';
import '../widgets/animated_wordmark.dart';
import '../widgets/splash_atmosphere.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;
  final timing = const SplashTimingRepository();
  final onboardingRepository = LocalOnboardingRepository();
  bool navigating = false;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(vsync: this, duration: timing.duration)
      ..forward();
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _openNextPage();
      }
    });
  }

  Future<void> _openNextPage() async {
    if (navigating) return;
    navigating = true;
    final completed = await onboardingRepository.hasCompletedOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => completed
            ? const AppShell()
            : OnboardingPage(repository: onboardingRepository),
        transitionDuration: const Duration(milliseconds: 520),
        transitionsBuilder: (_, value, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: value, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.navy : AppColors.canvas;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final logo = AppAssets.getLogo(
      isDark: isDark,
      isArabic: isArabic,
      withoutBackground: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              SplashAtmosphere(progress: animation.value, isDark: isDark),
              Center(
                child: AnimatedWordmark(
                  progress: animation.value,
                  asset: logo,
                  darkBackground: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
