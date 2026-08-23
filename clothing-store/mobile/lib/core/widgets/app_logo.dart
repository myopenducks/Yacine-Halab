import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final txtColor = textColor ?? (isLight ? AppColors.dark : AppColors.surfaceLight);

    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle glow circle behind icon
            Container(
              width: size * 0.65,
              height: size * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.25),
              ),
            ),
            Icon(
              Icons.checkroom_rounded,
              size: size * 0.54,
              color: AppColors.surfaceLight,
            ),
          ],
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
