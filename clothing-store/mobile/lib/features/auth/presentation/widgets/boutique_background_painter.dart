import 'package:flutter/material.dart';

/// CustomPainter drawing rich, luxurious boutique flourishes (زخرفة),
/// flowing contour curves, display tables, and interconnected decorative arcs.
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
    // 1. TOP & HEADER ORNAMENTAL FLOURISHES (زخرفة علوية)
    // ─────────────────────────────────────────────────────────────

    // Top-left cascading decorative swirl arc
    final pTopLeft = Path()
      ..moveTo(-w * 0.05, h * 0.08)
      ..cubicTo(w * 0.15, h * 0.04, w * 0.28, h * 0.14, w * 0.20, h * 0.22)
      ..cubicTo(w * 0.14, h * 0.28, w * 0.02, h * 0.24, 0, h * 0.32)
      ..moveTo(w * 0.05, h * 0.02)
      ..cubicTo(w * 0.22, h * 0.06, w * 0.35, h * 0.18, w * 0.30, h * 0.26);
    canvas.drawPath(pTopLeft, paint);

    // Top Center Table / Display Bench
    final tableTop = Rect.fromCenter(
      center: Offset(w * 0.44, h * 0.16),
      width: w * 0.22,
      height: h * 0.020,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tableTop, const Radius.circular(2)),
      paint,
    );
    final pTableLegs = Path()
      ..moveTo(tableTop.left + 5, tableTop.bottom)
      ..lineTo(tableTop.left + 2, tableTop.bottom + h * 0.050)
      ..moveTo(tableTop.right - 5, tableTop.bottom)
      ..lineTo(tableTop.right - 2, tableTop.bottom + h * 0.050)
      ..moveTo(tableTop.left + 4, tableTop.bottom + h * 0.012)
      ..lineTo(tableTop.right - 4, tableTop.bottom + h * 0.012);
    canvas.drawPath(pTableLegs, paint);

    // Top-right flowing decorative waves framing title
    final pTopRightWave = Path()
      ..moveTo(w * 0.55, h * 0.06)
      ..cubicTo(w * 0.70, h * 0.02, w * 0.90, h * 0.12, w * 0.85, h * 0.24)
      ..cubicTo(w * 0.80, h * 0.32, w * 0.95, h * 0.36, w * 1.05, h * 0.30)
      ..moveTo(w * 0.65, h * 0.10)
      ..cubicTo(w * 0.78, h * 0.08, w * 0.92, h * 0.18, w * 0.90, h * 0.26);
    canvas.drawPath(pTopRightWave, paint);

    // ─────────────────────────────────────────────────────────────
    // 2. MID-SECTION INTERCONNECTING RIBBONS & ARCS (زخرفة وسطى)
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
    // 3. BOTTOM SECTION DECORATIVE CONTOURS & VIGNETTES (زخرفة سفلية)
    // ─────────────────────────────────────────────────────────────

    // Center Display Table (below buttons)
    final tableBottom = Rect.fromCenter(
      center: Offset(w * 0.48, h * 0.71),
      width: w * 0.18,
      height: h * 0.016,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tableBottom, const Radius.circular(2)),
      paint,
    );
    final pTableBtmLegs = Path()
      ..moveTo(tableBottom.left + 4, tableBottom.bottom)
      ..lineTo(tableBottom.left + 1, tableBottom.bottom + h * 0.040)
      ..moveTo(tableBottom.right - 4, tableBottom.bottom)
      ..lineTo(tableBottom.right - 1, tableBottom.bottom + h * 0.040)
      ..moveTo(tableBottom.left + 3, tableBottom.bottom + h * 0.010)
      ..lineTo(tableBottom.right - 3, tableBottom.bottom + h * 0.010);
    canvas.drawPath(pTableBtmLegs, paint);

    // Gift Box with ribbon beside the table
    final giftBoxBtm = Rect.fromLTWH(w * 0.66, h * 0.68, w * 0.12, h * 0.060);
    _drawGiftBox(canvas, paint, giftBoxBtm);

    // Multi-tier intertwining ornamental flourish curves at bottom
    final pBottomFlourish = Path()
      ..moveTo(-w * 0.10, h * 0.78)
      ..cubicTo(w * 0.18, h * 0.72, w * 0.38, h * 0.85, w * 0.50, h * 0.94)
      ..cubicTo(w * 0.62, h * 1.02, w * 0.82, h * 0.88, w * 1.10, h * 0.84)
      // Second nested flourish
      ..moveTo(-w * 0.06, h * 0.82)
      ..cubicTo(w * 0.22, h * 0.76, w * 0.40, h * 0.89, w * 0.52, h * 0.97)
      ..cubicTo(w * 0.64, h * 1.05, w * 0.85, h * 0.92, w * 1.08, h * 0.88)
      // Third ambient flourish loop
      ..moveTo(w * 0.30, h * 0.65)
      ..cubicTo(w * 0.45, h * 0.60, w * 0.70, h * 0.66, w * 0.95, h * 0.62)
      ..moveTo(w * 0.35, h * 0.86)
      ..cubicTo(w * 0.50, h * 0.80, w * 0.68, h * 0.84, w * 0.80, h * 0.76);
    canvas.drawPath(pBottomFlourish, paint);
  }

  void _drawGiftBox(Canvas canvas, Paint paint, Rect rect) {
    final lid = Rect.fromLTWH(
      rect.left - 2,
      rect.top,
      rect.width + 4,
      rect.height * 0.32,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lid, const Radius.circular(1.5)),
      paint,
    );

    final base = Rect.fromLTWH(
      rect.left,
      lid.bottom,
      rect.width,
      rect.height * 0.68,
    );
    canvas.drawRect(base, paint);

    final ribbonX = rect.left + rect.width * 0.5;
    canvas.drawPath(
      Path()
        ..moveTo(ribbonX, rect.top)
        ..lineTo(ribbonX, rect.bottom),
      paint,
    );
    final pBow = Path()
      ..moveTo(ribbonX, rect.top)
      ..quadraticBezierTo(
        ribbonX - 5,
        rect.top - 6,
        ribbonX - 2,
        rect.top - 2,
      )
      ..moveTo(ribbonX, rect.top)
      ..quadraticBezierTo(
        ribbonX + 5,
        rect.top - 6,
        ribbonX + 2,
        rect.top - 2,
      );
    canvas.drawPath(pBow, paint);
  }

  @override
  bool shouldRepaint(covariant BoutiqueBackgroundPainter oldDelegate) => false;
}
