import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/pages/app_shell.dart';
import '../../data/repositories/local_onboarding_repository.dart';
import '../../domain/entities/onboarding_item.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../widgets/onboarding_indicator.dart';
import '../widgets/onboarding_slide.dart';

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

  Future<void> finish() async {
    if (isFinishing) return;
    setState(() => isFinishing = true);
    await widget.repository.completeOnboarding();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  void next() {
    if (currentIndex == _onboardingItems.length - 1) {
      finish();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = currentIndex == _onboardingItems.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingTopBar(onSkip: finish),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: _onboardingItems.length,
                onPageChanged: (index) => setState(() => currentIndex = index),
                itemBuilder: (_, index) =>
                    OnboardingSlide(item: _onboardingItems[index]),
              ),
            ),
            const SizedBox(height: 22),
            OnboardingIndicator(
              count: _onboardingItems.length,
              currentIndex: currentIndex,
            ),
            _OnboardingNextButton(
              isFinishing: isFinishing,
              isLastPage: lastPage,
              onPressed: next,
            ),
          ],
        ),
      ),
    );
  }
}
