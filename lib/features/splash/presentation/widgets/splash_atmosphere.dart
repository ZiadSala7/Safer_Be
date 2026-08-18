import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SplashAtmosphere extends StatelessWidget {
  const SplashAtmosphere({
    required this.progress,
    required this.isDark,
    super.key,
  });

  final double progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF071A33), Color(0xFF0A2340)]
            : const [Color(0xFFFFFFFF), Color(0xFFF3F7FB)],
      ),
    ),
    child: CustomPaint(
      painter: _OpeningRingsPainter(progress: progress, isDark: isDark),
      size: Size.infinite,
    ),
  );
}

class _OpeningRingsPainter extends CustomPainter {
  const _OpeningRingsPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final enter = Curves.easeOut.transform((progress / .14).clamp(0.0, 1.0));
    final exit = Curves.easeIn.transform(
      ((progress - .22) / .18).clamp(0.0, 1.0),
    );
    final opacity = enter * (1 - exit);
    if (opacity <= 0) return;

    final color = isDark ? AppColors.tealLight : AppColors.teal;
    final center = size.center(Offset.zero);
    for (var index = 0; index < 2; index++) {
      final radius = 40 + (index * 17) + (enter * 8);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity * (.16 - index * .05))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OpeningRingsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
