import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../shell/presentation/pages/app_shell.dart';
import '../../data/repositories/local_onboarding_repository.dart';
import '../../domain/entities/onboarding_item.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../widgets/onboarding_atmosphere.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/onboarding_top_bar.dart';

part 'onboarding_controls.dart';
part 'onboarding_items.dart';

class OnboardingPage extends StatefulWidget {
  OnboardingPage({OnboardingRepository? repository, super.key})
    : repository = repository ?? LocalOnboardingRepository();

  final OnboardingRepository repository;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final pageController = PageController();
  int currentIndex = 0;
  bool isFinishing = false;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> finish({bool openLogin = false}) async {
    if (isFinishing) return;
    setState(() => isFinishing = true);
    await widget.repository.completeOnboarding();
    if (!mounted) return;

    if (openLogin) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  void next() {
    if (currentIndex == _onboardingItems.length - 1) {
      finish();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void selectSlide(int index) {
    if (index < 0 || index >= _onboardingItems.length) return;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _onboardingItems[currentIndex];
    final lastPage = currentIndex == _onboardingItems.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Smooth Animated Atmosphere Background
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: OnboardingAtmosphere(
                key: ValueKey(currentItem.type),
                gradientColors: currentItem.gradientColors,
                accentColor: currentItem.accentColor,
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  OnboardingTopBar(
                    currentIndex: currentIndex,
                    totalSlides: _onboardingItems.length,
                    accentColor: currentItem.accentColor,
                    onSkip: finish,
                    onSelectSlide: selectSlide,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: _onboardingItems.length,
                      onPageChanged: (index) =>
                          setState(() => currentIndex = index),
                      itemBuilder: (_, index) =>
                          OnboardingSlide(item: _onboardingItems[index]),
                    ),
                  ),
                  _OnboardingBottomControls(
                    isFinishing: isFinishing,
                    isLastPage: lastPage,
                    accentColor: currentItem.accentColor,
                    onNext: next,
                    onSignIn: () => finish(openLogin: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
