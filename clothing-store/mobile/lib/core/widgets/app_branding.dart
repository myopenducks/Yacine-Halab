import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Unobtrusive credit line for login / about areas.
class DevelopedByZiadFooter extends StatelessWidget {
  const DevelopedByZiadFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Developed by Ziad',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );
  }
}
