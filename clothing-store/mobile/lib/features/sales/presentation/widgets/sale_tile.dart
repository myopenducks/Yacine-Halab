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
    this.onEdit,
    this.onMarkPaid,
  });

  final SaleHeader sale;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkPaid;

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
                  ? AppColors.debtRed.withValues(alpha: 0.35)
                  : (isLight ? AppColors.gray200 : AppColors.gray800),
              width: hasDebt ? 1.5 : 1.2,
            ),
            boxShadow: [
              if (hasDebt)
                BoxShadow(
                  color: AppColors.debtRed.withValues(alpha: 0.04),
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
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: hasDebt
                          ? AppColors.debtRed.withValues(alpha: 0.12)
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
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Sale #${sale.id}',
                              style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                            ),
                            if (sale.customerName != null && sale.customerName!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isLight ? AppColors.gray100 : AppColors.gray800,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sale.customerName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isLight ? AppColors.secondary : AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dateFmt.format(sale.createdAt.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isLight ? AppColors.gray500 : AppColors.gray400,
                          ),
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
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),

              // ── Notes snippet if present ──────────────────────────────
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLight
                        ? AppColors.warmLinen.withValues(alpha: 0.5)
                        : AppColors.gray800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLight ? AppColors.border : AppColors.gray700,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 14,
                        color: isLight ? AppColors.skyBlue : AppColors.softBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sale.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isLight ? AppColors.gray800 : AppColors.onDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),
              // ── Chips & Actions Row ──────────────────────────────────
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
                  const Spacer(),
                  if (hasDebt && onMarkPaid != null) ...[
                    InkWell(
                      onTap: onMarkPaid,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'Mark Paid',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (onEdit != null)
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: isLight ? AppColors.gray600 : AppColors.gray400,
                        ),
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
