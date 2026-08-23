import 'package:flutter/material.dart';
import '../../../../core/utils/date.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../models/sale.dart';

class SaleTile extends StatelessWidget {
  const SaleTile({
    super.key,
    required this.sale,
    required this.onTap,
  });

  final SaleHeader sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final dateFmt = appDateTimeFormat;
    final hasDebt = sale.hasDebt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isLight ? AppColors.white : AppColors.gray900,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasDebt
                  ? AppColors.debtRed.withValues(alpha: 0.3)
                  : (isLight ? AppColors.gray200 : AppColors.gray800),
              width: hasDebt ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasDebt
                      ? AppColors.debtRed.withValues(alpha: 0.1)
                      : (isLight ? AppColors.gray100 : AppColors.gray800),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasDebt
                      ? Icons.money_off_csred_outlined
                      : Icons.receipt_long_outlined,
                  color: hasDebt
                      ? AppColors.debtRed
                      : (isLight ? AppColors.black : AppColors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sale #${sale.id}',
                          style: theme.textTheme.titleLarge,
                        ),
                        if (sale.customerName != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '· ${sale.customerName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isLight
                                    ? AppColors.skyBlue
                                    : AppColors.softBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFmt.format(sale.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLight ? AppColors.gray500 : AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(
                          label: '${sale.itemCount} items',
                          isLight: isLight,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: sale.remainingAmount == 0
                              ? 'Paid'
                              : 'Due ${formatDASimple(sale.remainingAmount)}',
                          isLight: isLight,
                          warn: hasDebt,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDAAmount(sale.totalAmount),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isLight ? AppColors.gray400 : AppColors.gray500,
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isLight,
    this.warn = false,
  });

  final String label;
  final bool isLight;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final color = warn ? AppColors.debtRed : AppColors.success;
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
