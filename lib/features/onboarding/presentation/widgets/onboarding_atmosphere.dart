import 'dart:math' as math;
import 'package:flutter/material.dart';

class OnboardingAtmosphere extends StatelessWidget {
  const OnboardingAtmosphere({
    required this.gradientColors,
    required this.accentColor,
    super.key,
  });

  final List<Color> gradientColors;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient Base
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          // Ambient Radial Light
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.35),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Custom Flight Trails & Travel Doodles Painter
          CustomPaint(
            painter: _AtmospherePainter(accentColor: accentColor),
          ),
        ],
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter({required this.accentColor});

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final starPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Flight Curve 1
    final path1 = Path();
    path1.moveTo(size.width * 0.05, size.height * 0.18);
    path1.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.10,
      size.width * 0.92,
      size.height * 0.22,
    );
    _drawDashedPath(canvas, path1, trailPaint, 6, 6);

    // Mini Airplane Marker
    _drawPlaneIcon(canvas, Offset(size.width * 0.92, size.height * 0.22), -0.2);

    // Sparkle Stars
    _drawStar(canvas, Offset(size.width * 0.18, size.height * 0.12), 4, starPaint);
    _drawStar(canvas, Offset(size.width * 0.85, size.height * 0.14), 5, starPaint);
    _drawStar(canvas, Offset(size.width * 0.50, size.height * 0.07), 3.5, starPaint);
    _drawStar(canvas, Offset(size.width * 0.12, size.height * 0.26), 4, starPaint);

    // Soft Floating Circles
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.28), 2.5, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.21), 2.0, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.16), 1.8, dotPaint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    }
    final strokePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);
    canvas.drawCircle(center, radius * 0.35, paint);
  }

  void _drawPlaneIcon(Canvas canvas, Offset offset, double angle) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, -6);
    path.lineTo(4, 4);
    path.lineTo(0, 2);
    path.lineTo(-4, 4);
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
