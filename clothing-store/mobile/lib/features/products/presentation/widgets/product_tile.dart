import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../models/product.dart';

class ProductTile extends ConsumerWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
    this.isSelected,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool? isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final stockColor = product.isOutOfStock
        ? AppColors.danger
        : product.isLowStock
            ? AppColors.warning
            : AppColors.success;

    final stockLabel = product.isOutOfStock
        ? strings.outOfStock
        : product.isLowStock
            ? '${strings.lowStock} (${product.quantity})'
            : (strings.isFrench ? 'Qté ${product.quantity}' : 'Qty ${product.quantity}');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected == true 
                ? (isLight ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.2))
                : (isLight ? AppColors.white : AppColors.gray900),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected == true
                  ? AppColors.primary
                  : (isLight ? AppColors.gray200 : AppColors.gray800),
              width: isSelected == true ? 2.0 : 1.2,
            ),
          ),
          child: Row(
            children: [
              if (isSelected != null) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
              ] else ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.gray100 : AppColors.gray800,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.checkroom_outlined,
                    color: isLight ? AppColors.black : AppColors.white,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.categoryName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLight ? AppColors.gray500 : AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          formatDAAmount(product.sellingPrice),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StockChip(
                          label: stockLabel,
                          color: stockColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isLight ? AppColors.gray400 : AppColors.gray500,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
