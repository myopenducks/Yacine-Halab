import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Unobtrusive credit line for login / about areas.
class DevelopedByZiadFooter extends ConsumerWidget {
  const DevelopedByZiadFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    return Text(
      strings.isFrench ? 'Développé par Ziad' : 'Developed by Ziad',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );
  }
}
