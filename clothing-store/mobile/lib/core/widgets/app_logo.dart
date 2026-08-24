import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.showText = false,
    this.textColor,
  });

  final double size;
  final bool showText;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final txtColor =
        textColor ?? (isLight ? AppColors.dark : AppColors.surfaceLight);

    // The SVG is 300×200 so we clip it to a square by centering on the wide axis
    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: SizedBox(
            // Scale the 300×200 SVG so its height fills our square
            width: size * 1.5,
            height: size,
            child: SvgPicture.asset(
              'assets/icon/Group.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );

    if (!showText) return iconWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        SizedBox(height: size * 0.18),
        Text(
          'BOUTIQUE STORE',
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: txtColor,
          ),
        ),
        SizedBox(height: size * 0.04),
        Text(
          'Gestion & Vente de Vêtements',
          style: TextStyle(
            fontSize: size * 0.16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: isLight ? AppColors.gray600 : AppColors.gray400,
          ),
        ),
      ],
    );
  }
}
