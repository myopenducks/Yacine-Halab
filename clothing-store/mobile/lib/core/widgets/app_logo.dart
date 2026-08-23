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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final txtColor = textColor ?? (isLight ? AppColors.dark : AppColors.surfaceLight);

    final iconWidget = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: isLight ? AppColors.card : AppColors.cardDark,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: isLight ? AppColors.border : AppColors.borderDark,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Image.asset(
        'assets/icon/app_icon.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.checkroom_rounded,
            size: size * 0.54,
            color: AppColors.primary,
          );
        },
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
