import 'package:flutter/material.dart';

/// CustomPainter drawing the high-end boutique line-art retail elements
/// (hangers, tables, shirts, trousers, gift boxes, socks, and contour flourishes).
class BoutiqueBackgroundPainter extends CustomPainter {
  const BoutiqueBackgroundPainter({
    this.strokeColor = const Color(0xFF2C1A11),
    this.opacity = 0.13,
  });

  final Color strokeColor;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // ─────────────────────────────────────────────────────────────
    // TOP SECTION ILLUSTRATIONS
    // ─────────────────────────────────────────────────────────────

    // Top Left: Partial hanger / rack arc
    final pRack = Path()
      ..moveTo(0, h * 0.14)
      ..lineTo(w * 0.10, h * 0.16)
      ..lineTo(w * 0.04, h * 0.22);
    canvas.drawPath(pRack, paint);

    // Top Center: Display Table / Bench
    final tableTop = Rect.fromCenter(
      center: Offset(w * 0.45, h * 0.17),
      width: w * 0.23,
      height: h * 0.022,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tableTop, const Radius.circular(2)),
      paint,
    );
    // Table legs
    final pTableLegs = Path()
      ..moveTo(tableTop.left + 5, tableTop.bottom)
      ..lineTo(tableTop.left + 2, tableTop.bottom + h * 0.055)
      ..moveTo(tableTop.right - 5, tableTop.bottom)
      ..lineTo(tableTop.right - 2, tableTop.bottom + h * 0.055)
      ..moveTo(tableTop.left + 4, tableTop.bottom + h * 0.014)
      ..lineTo(tableTop.right - 4, tableTop.bottom + h * 0.014);
    canvas.drawPath(pTableLegs, paint);

    // Top Right: Hanger with hanging price tag
    final hangerCenter = Offset(w * 0.72, h * 0.15);
    _drawHanger(canvas, paint, hangerCenter, w * 0.16, withTag: true);

    // Top Far Right: Folded T-Shirt outline
    final shirtPath = Path()
      ..moveTo(w * 0.84, h * 0.20)
      ..lineTo(w * 0.90, h * 0.17)
      ..quadraticBezierTo(w * 0.94, h * 0.19, w * 0.98, h * 0.17)
      ..lineTo(w * 1.02, h * 0.20)
      ..lineTo(w * 0.98, h * 0.28)
      ..lineTo(w * 0.95, h * 0.27)
      ..lineTo(w * 0.95, h * 0.35)
      ..lineTo(w * 0.86, h * 0.35)
      ..lineTo(w * 0.86, h * 0.27)
      ..lineTo(w * 0.82, h * 0.28)
      ..close();
    canvas.drawPath(shirtPath, paint);

    // Top Right: Gift Box (peeking from side)
    final giftBoxTop = Rect.fromLTWH(w * 0.92, h * 0.33, w * 0.12, h * 0.085);
    _drawGiftBox(canvas, paint, giftBoxTop);

    // ─────────────────────────────────────────────────────────────
    // BOTTOM SECTION ILLUSTRATIONS
    // ─────────────────────────────────────────────────────────────

    // Ambient curved background contours connecting lower elements
    final pContour = Path()
      ..moveTo(0, h * 0.82)
      ..cubicTo(w * 0.25, h * 0.76, w * 0.45, h * 0.88, w * 0.5, h * 0.98)
      ..moveTo(w * 0.5, h * 0.78)
      ..cubicTo(w * 0.7, h * 0.70, w * 0.9, h * 0.82, w * 1.05, h * 0.75)
      ..moveTo(w * 0.45, h * 0.68)
      ..cubicTo(w * 0.55, h * 0.64, w * 0.75, h * 0.68, w * 0.9, h * 0.64);
    canvas.drawPath(pContour, paint);

    // Bottom Left: Trousers / Jeans
    final pPants = Path()
      ..moveTo(w * 0.08, h * 0.70)
      ..lineTo(w * 0.21, h * 0.70)
      ..lineTo(w * 0.19, h * 0.84)
      ..lineTo(w * 0.15, h * 0.84)
      ..lineTo(w * 0.14, h * 0.75)
      ..lineTo(w * 0.13, h * 0.84)
      ..lineTo(w * 0.08, h * 0.84)
      ..close();
    pPants
      ..moveTo(w * 0.08, h * 0.72)
      ..lineTo(w * 0.21, h * 0.72)
      ..moveTo(w * 0.10, h * 0.72)
      ..quadraticBezierTo(w * 0.12, h * 0.74, w * 0.14, h * 0.72);
    canvas.drawPath(pPants, paint);

    // Bottom Center-Top: Display Table (below buttons)
    final tableBottom = Rect.fromCenter(
      center: Offset(w * 0.48, h * 0.72),
      width: w * 0.19,
      height: h * 0.018,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tableBottom, const Radius.circular(2)),
      paint,
    );
    final pTableBtmLegs = Path()
      ..moveTo(tableBottom.left + 4, tableBottom.bottom)
      ..lineTo(tableBottom.left + 1, tableBottom.bottom + h * 0.045)
      ..moveTo(tableBottom.right - 4, tableBottom.bottom)
      ..lineTo(tableBottom.right - 1, tableBottom.bottom + h * 0.045)
      ..moveTo(tableBottom.left + 3, tableBottom.bottom + h * 0.012)
      ..lineTo(tableBottom.right - 3, tableBottom.bottom + h * 0.012);
    canvas.drawPath(pTableBtmLegs, paint);

    // Bottom Center-Right: Gift Box with ribbon
    final giftBoxBtm = Rect.fromLTWH(w * 0.69, h * 0.69, w * 0.13, h * 0.065);
    _drawGiftBox(canvas, paint, giftBoxBtm);

    // Bottom Center-Left: Clothes Hanger with Tag
    final hangerBtm = Offset(w * 0.44, h * 0.83);
    _drawHanger(canvas, paint, hangerBtm, w * 0.15, withTag: true);

    // Bottom Center: Folded Buttoned Shirt with Collar
    final pCollaredShirt = Path()
      ..moveTo(w * 0.52, h * 0.80)
      ..lineTo(w * 0.57, h * 0.83)
      ..lineTo(w * 0.62, h * 0.80)
      ..moveTo(w * 0.57, h * 0.83)
      ..lineTo(w * 0.57, h * 0.88)
      ..moveTo(w * 0.50, h * 0.80)
      ..lineTo(w * 0.64, h * 0.80)
      ..lineTo(w * 0.64, h * 0.88)
      ..lineTo(w * 0.50, h * 0.88)
      ..close();
    canvas.drawCircle(Offset(w * 0.57, h * 0.845), 1.2, paint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.865), 1.2, paint);
    canvas.drawPath(pCollaredShirt, paint);

    // Bottom Right: Boutique Sock Outline
    final pSock = Path()
      ..moveTo(w * 0.88, h * 0.80)
      ..lineTo(w * 0.93, h * 0.80)
      ..lineTo(w * 0.93, h * 0.85)
      ..quadraticBezierTo(w * 0.93, h * 0.89, w * 0.88, h * 0.89)
      ..lineTo(w * 0.84, h * 0.87)
      ..quadraticBezierTo(w * 0.83, h * 0.85, w * 0.88, h * 0.85)
      ..lineTo(w * 0.88, h * 0.80)
      ..moveTo(w * 0.88, h * 0.81)
      ..lineTo(w * 0.93, h * 0.81);
    canvas.drawPath(pSock, paint);
  }

  void _drawHanger(
    Canvas canvas,
    Paint paint,
    Offset center,
    double width, {
    bool withTag = false,
  }) {
    final hookCenter = Offset(center.dx, center.dy - 12);
    final pHook = Path()
      ..moveTo(hookCenter.dx, hookCenter.dy + 8)
      ..lineTo(hookCenter.dx, hookCenter.dy)
      ..arcToPoint(
        Offset(hookCenter.dx + 6, hookCenter.dy - 6),
        radius: const Radius.circular(5),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(hookCenter.dx, hookCenter.dy - 12),
        radius: const Radius.circular(5),
        clockwise: false,
      );
    canvas.drawPath(pHook, paint);

    final pHanger = Path()
      ..moveTo(center.dx - width / 2, center.dy + 6)
      ..lineTo(center.dx, center.dy - 4)
      ..lineTo(center.dx + width / 2, center.dy + 6)
      ..close();
    canvas.drawPath(pHanger, paint);

    if (withTag) {
      final tagStart = Offset(center.dx + width * 0.22, center.dy + 6);
      final pTag = Path()
        ..moveTo(tagStart.dx, tagStart.dy)
        ..lineTo(tagStart.dx + 4, tagStart.dy + 8)
        ..lineTo(tagStart.dx + 10, tagStart.dy + 18)
        ..lineTo(tagStart.dx + 5, tagStart.dy + 21)
        ..lineTo(tagStart.dx - 1, tagStart.dy + 11)
        ..close();
      canvas.drawPath(pTag, paint);
    }
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
    final pRibbon = Path()
      ..moveTo(ribbonX, rect.top)
      ..lineTo(ribbonX, rect.bottom);
    canvas.drawPath(pRibbon, paint);

    final pBow = Path()
      ..moveTo(ribbonX, rect.top)
      ..quadraticBezierTo(
        ribbonX - 6,
        rect.top - 8,
        ribbonX - 2,
        rect.top - 2,
      )
      ..moveTo(ribbonX, rect.top)
      ..quadraticBezierTo(
        ribbonX + 6,
        rect.top - 8,
        ribbonX + 2,
        rect.top - 2,
      );
    canvas.drawPath(pBow, paint);
  }

  @override
  bool shouldRepaint(covariant BoutiqueBackgroundPainter oldDelegate) => false;
}
