import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

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

    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLight ? AppColors.primary : AppColors.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: (isLight ? AppColors.primary : AppColors.accent)
                .withValues(alpha: 0.25),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.checkroom_rounded,
        size: size * 0.52,
        color: isLight ? AppColors.onPrimary : AppColors.dark,
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
            fontFamily: AppTheme.fontFamily,
            fontSize: size * 0.24,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: txtColor,
          ),
        ),
        SizedBox(height: size * 0.04),
        Text(
          'Gestion & Vente de Vêtements',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: size * 0.15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: isLight ? AppColors.gray600 : AppColors.gray400,
          ),
        ),
      ],
    );
  }
}

