import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../providers/new_sale_provider.dart';

class CartLineTile extends ConsumerWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.onEditPrice,
  });

  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback? onEditPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final atMax = line.quantity >= line.maxQty;
    final strings = ref.watch(appStringsProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.gray900,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: line.hasCustomPrice
              ? AppColors.primary.withValues(alpha: 0.6)
              : (isLight ? AppColors.gray200 : AppColors.gray800),
          width: line.hasCustomPrice ? 1.5 : 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLight ? AppColors.gray100 : AppColors.gray800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.checkroom_outlined,
              color: isLight ? AppColors.black : AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),

                // ── Price & Stock with Tap to Edit Price ──
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    InkWell(
                      onTap: onEditPrice,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: line.hasCustomPrice
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : (isLight ? AppColors.gray100 : AppColors.gray800),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: line.hasCustomPrice
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : (isLight ? AppColors.gray300 : AppColors.gray700),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatDAAmount(line.unitPrice),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: line.hasCustomPrice
                                    ? AppColors.primary
                                    : (isLight ? AppColors.gray800 : AppColors.onDark),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: line.hasCustomPrice ? AppColors.primary : AppColors.gray400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '· stock ${line.maxQty}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLight ? AppColors.gray500 : AppColors.gray400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    _QtyBtn(
                      icon: Icons.remove,
                      onTap: onDecrement,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${line.quantity}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _QtyBtn(
                      icon: Icons.add,
                      onTap: atMax ? null : onIncrement,
                    ),
                    const Spacer(),
                    Text(
                      formatDAAmount(line.lineTotal),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: strings.cancel,
            onPressed: onRemove,
            icon: Icon(
              Icons.close,
              size: 18,
              color: isLight ? AppColors.gray400 : AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isLight ? AppColors.gray100 : AppColors.gray800,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLight ? AppColors.gray200 : AppColors.gray700,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? (isLight ? AppColors.black : AppColors.white)
                : (isLight ? AppColors.gray300 : AppColors.gray500),
          ),
        ),
      ),
    );
  }
}
