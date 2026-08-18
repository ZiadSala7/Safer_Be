part of 'animated_wordmark.dart';

class _AnimatedMark extends StatelessWidget {
  const _AnimatedMark({
    required this.enter,
    required this.exit,
    required this.darkBackground,
  });

  final double enter;
  final double exit;
  final bool darkBackground;

  @override
  Widget build(BuildContext context) {
    final opacity = (enter * (1 - exit)).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: .84 + (.16 * enter),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: darkBackground
                ? Colors.white.withValues(alpha: .08)
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.teal.withValues(alpha: .24)),
          ),
          child: CustomPaint(painter: const _PlaneMarkPainter()),
        ),
      ),
    );
  }
}

class _PlaneMarkPainter extends CustomPainter {
  const _PlaneMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-.12);
    final plane = Path()
      ..moveTo(15, 0)
      ..lineTo(-2, -3)
      ..lineTo(-10, -12)
      ..lineTo(-14, -11)
      ..lineTo(-9, -2)
      ..lineTo(-16, -1)
      ..lineTo(-16, 1)
      ..lineTo(-9, 2)
      ..lineTo(-14, 11)
      ..lineTo(-10, 12)
      ..lineTo(-2, 3)
      ..close();
    canvas.drawPath(plane, Paint()..color = AppColors.orange);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
