part of 'onboarding_page.dart';

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final app = AppControllerScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: app.toggleLocale,
            icon: const Icon(Icons.language_rounded, size: 18),
            label: Text(context.tr('language')),
          ),
          const Spacer(),
          TextButton(onPressed: onSkip, child: Text(context.tr('skip'))),
        ],
      ),
    );
  }
}

class _OnboardingNextButton extends StatelessWidget {
  const _OnboardingNextButton({
    required this.isFinishing,
    required this.isLastPage,
    required this.onPressed,
  });

  final bool isFinishing;
  final bool isLastPage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
    child: SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: isFinishing ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isLastPage ? AppColors.orange : AppColors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: isFinishing
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr(isLastPage ? 'getStarted' : 'next'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                ],
              ),
      ),
    ),
  );
}
