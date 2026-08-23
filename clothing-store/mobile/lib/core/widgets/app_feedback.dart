import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppSnackKind { info, success, error, warning }

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackKind kind = AppSnackKind.info,
}) {
  final theme = Theme.of(context);
  final isLight = theme.brightness == Brightness.light;

  final Color bg;
  final Color fg;
  switch (kind) {
    case AppSnackKind.success:
      bg = AppColors.success;
      fg = AppColors.onPrimary;
    case AppSnackKind.error:
      bg = AppColors.danger;
      fg = AppColors.onPrimary;
    case AppSnackKind.warning:
      bg = AppColors.warning;
      fg = AppColors.onPrimary;
    case AppSnackKind.info:
      bg = isLight ? AppColors.secondary : AppColors.accent;
      fg = isLight ? AppColors.onDark : AppColors.dark;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: fg,
          ),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.gray900,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight ? AppColors.gray200 : AppColors.gray800,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isLight ? AppColors.gray100 : AppColors.gray800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isLight ? AppColors.black : AppColors.white,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isLight ? AppColors.gray500 : AppColors.gray400,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class AppLoadingBlock extends StatelessWidget {
  const AppLoadingBlock({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(
            message!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
