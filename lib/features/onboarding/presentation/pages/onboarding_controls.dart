part of 'onboarding_page.dart';

class _OnboardingBottomControls extends StatelessWidget {
  const _OnboardingBottomControls({
    required this.isFinishing,
    required this.isLastPage,
    required this.accentColor,
    required this.onNext,
    required this.onSignIn,
  });

  final bool isFinishing;
  final bool isLastPage;
  final Color accentColor;
  final VoidCallback onNext;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isFinishing ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastPage ? Colors.white : Colors.white,
                foregroundColor: isLastPage ? const Color(0xFF1E1B4B) : const Color(0xFF0F172A),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isFinishing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF0F172A),
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
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastPage
                              ? Icons.flight_takeoff_rounded
                              : (Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded),
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),

          // Secondary Action on Last Slide
          if (isLastPage) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: isFinishing ? null : onSignIn,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              child: Text(
                '${context.tr('alreadyHaveAccount')} ${context.tr('signIn')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white70,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
