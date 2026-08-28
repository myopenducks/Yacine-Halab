import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.gray900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? AppColors.warning.withValues(alpha: 0.5)
              : (isLight ? AppColors.gray200 : AppColors.gray800),
          width: highlight ? 1.6 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : (isLight ? AppColors.gray100 : AppColors.gray800),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: highlight
                  ? AppColors.warning
                  : (isLight ? AppColors.black : AppColors.white),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLight ? AppColors.gray500 : AppColors.gray400,
            ),
          ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
