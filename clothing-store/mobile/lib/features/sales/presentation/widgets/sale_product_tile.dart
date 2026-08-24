import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../products/models/product.dart';

class SaleProductTile extends StatelessWidget {
  const SaleProductTile({
    super.key,
    required this.product,
    required this.inCartQty,
    required this.isLight,
    required this.strings,
    required this.onAdd,
  });

  final Product product;
  final int inCartQty;
  final bool isLight;
  final AppStrings strings;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;
    final primaryTextColor = isOutOfStock
        ? AppColors.textMuted
        : (isLight ? AppColors.dark : AppColors.onDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isLight ? AppColors.white : AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: inCartQty > 0
                  ? AppColors.primary
                  : (isLight ? AppColors.border : AppColors.borderDark),
              width: inCartQty > 0 ? 1.6 : 1.2,
            ),
            boxShadow: [
              if (inCartQty > 0)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductIcon(product: product, isLight: isLight),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (product.categoryName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? AppColors.inputFill
                                      : AppColors.inputFillDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isLight
                                        ? AppColors.border
                                        : AppColors.borderDark,
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  product.categoryName,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: isLight
                                        ? AppColors.secondary
                                        : AppColors.onDark,
                                  ),
                                ),
                              ),
                            Text(
                              isOutOfStock
                                  ? strings.outOfStock
                                  : '${strings.inStock}: ${product.quantity}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: isOutOfStock
                                    ? AppColors.danger
                                    : (isLight
                                        ? AppColors.textMuted
                                        : AppColors.textMutedDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatDAAmount(product.sellingPrice),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isLight ? AppColors.dark : AppColors.onDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (inCartQty > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${strings.cartItems}: x$inCartQty',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isOutOfStock
                              ? AppColors.gray300
                              : AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          strings.isFrench ? 'Ajouter' : 'Add',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: onAdd,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductIcon extends StatelessWidget {
  const _ProductIcon({required this.product, required this.isLight});

  final Product product;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isLight ? AppColors.inputFill : AppColors.inputFillDark,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
          ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.checkroom_rounded,
                color: isLight ? AppColors.secondary : AppColors.onDark,
              ),
            )
          : Icon(
              Icons.checkroom_rounded,
              color: isLight ? AppColors.secondary : AppColors.onDark,
            ),
    );
  }
}
