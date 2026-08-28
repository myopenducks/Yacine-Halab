import 'package:flutter/material.dart';

/// CustomPainter drawing solely the elegant, flowing boutique flourish lines (خطوط الزخرفة)
/// framing the composition with delicate, curved contour ribbons.
class BoutiqueBackgroundPainter extends CustomPainter {
  const BoutiqueBackgroundPainter({
    this.strokeColor = const Color(0xFF2C1A11),
    this.opacity = 0.12,
  });

  final Color strokeColor;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.90
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // ─────────────────────────────────────────────────────────────
    // 1. TOP & HEADER FLOURISH CURVES (زخرفة علوية انسيابية)
    // ─────────────────────────────────────────────────────────────

    // Top-left cascading decorative swirl arc
    final pTopLeft = Path()
      ..moveTo(-w * 0.05, h * 0.08)
      ..cubicTo(w * 0.15, h * 0.04, w * 0.28, h * 0.14, w * 0.20, h * 0.22)
      ..cubicTo(w * 0.14, h * 0.28, w * 0.02, h * 0.24, 0, h * 0.32)
      ..moveTo(w * 0.05, h * 0.02)
      ..cubicTo(w * 0.22, h * 0.06, w * 0.35, h * 0.18, w * 0.30, h * 0.26);
    canvas.drawPath(pTopLeft, paint);

    // Top-right flowing decorative waves framing the title
    final pTopRightWave = Path()
      ..moveTo(w * 0.55, h * 0.06)
      ..cubicTo(w * 0.70, h * 0.02, w * 0.90, h * 0.12, w * 0.85, h * 0.24)
      ..cubicTo(w * 0.80, h * 0.32, w * 0.95, h * 0.36, w * 1.05, h * 0.30)
      ..moveTo(w * 0.65, h * 0.10)
      ..cubicTo(w * 0.78, h * 0.08, w * 0.92, h * 0.18, w * 0.90, h * 0.26);
    canvas.drawPath(pTopRightWave, paint);

    // ─────────────────────────────────────────────────────────────
    // 2. MID-SECTION INTERCONNECTING RIBBONS (زخرفة وسطى)
    // ─────────────────────────────────────────────────────────────

    // Sweeping luxury ribbon behind title and above inputs
    final pMidRibbon = Path()
      ..moveTo(-w * 0.08, h * 0.44)
      ..cubicTo(w * 0.20, h * 0.40, w * 0.40, h * 0.48, w * 0.65, h * 0.42)
      ..cubicTo(w * 0.85, h * 0.38, w * 0.95, h * 0.46, w * 1.08, h * 0.43)
      ..moveTo(-w * 0.05, h * 0.47)
      ..cubicTo(w * 0.22, h * 0.43, w * 0.42, h * 0.51, w * 0.68, h * 0.45)
      ..cubicTo(w * 0.88, h * 0.41, w * 0.98, h * 0.49, w * 1.10, h * 0.46);
    canvas.drawPath(pMidRibbon, paint);

    // ─────────────────────────────────────────────────────────────
    // 3. BOTTOM SECTION DECORATIVE CONTOURS (زخرفة سفلية)
    // ─────────────────────────────────────────────────────────────

    // Multi-tier intertwining ornamental flourish curves at bottom
    final pBottomFlourish = Path()
      ..moveTo(-w * 0.10, h * 0.78)
      ..cubicTo(w * 0.18, h * 0.72, w * 0.38, h * 0.85, w * 0.50, h * 0.94)
      ..cubicTo(w * 0.62, h * 1.02, w * 0.82, h * 0.88, w * 1.10, h * 0.84)
      // Second nested flourish
      ..moveTo(-w * 0.06, h * 0.82)
      ..cubicTo(w * 0.22, h * 0.76, w * 0.40, h * 0.89, w * 0.52, h * 0.97)
      ..cubicTo(w * 0.64, h * 1.05, w * 0.85, h * 0.92, w * 1.08, h * 0.88)
      // Third ambient flourish loops
      ..moveTo(w * 0.30, h * 0.65)
      ..cubicTo(w * 0.45, h * 0.60, w * 0.70, h * 0.66, w * 0.95, h * 0.62)
      ..moveTo(w * 0.35, h * 0.86)
      ..cubicTo(w * 0.50, h * 0.80, w * 0.68, h * 0.84, w * 0.80, h * 0.76);
    canvas.drawPath(pBottomFlourish, paint);
  }

  @override
  bool shouldRepaint(covariant BoutiqueBackgroundPainter oldDelegate) => false;
}
