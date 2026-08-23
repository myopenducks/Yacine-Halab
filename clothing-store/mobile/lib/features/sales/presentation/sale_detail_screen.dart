import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../providers/sales_history_provider.dart';

class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final int saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final async = ref.watch(saleByIdProvider(saleId));
    final dateFmt = appDateTimeFormat;

    return Scaffold(
      backgroundColor: isLight ? AppColors.gray050 : AppColors.black,
      appBar: AppBar(
        title: Text('Sale #$saleId'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/cart');
            }
          },
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(saleByIdProvider(saleId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (sale) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.white : AppColors.gray900,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLight ? AppColors.gray200 : AppColors.gray800,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDAAmount(sale.totalAmount),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFmt.format(sale.createdAt.toLocal()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLight ? AppColors.gray500 : AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MetaChip(
                          label: '${sale.itemCount} units',
                          isLight: isLight,
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          label: 'Paid ${formatDAAmount(sale.paidAmount)}',
                          isLight: isLight,
                        ),
                        if (sale.remainingAmount > 0) ...[
                          const SizedBox(width: 8),
                          _MetaChip(
                            label:
                                'Due ${formatDAAmount(sale.remainingAmount)}',
                            isLight: isLight,
                            warn: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Items', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              ...sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.white : AppColors.gray900,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight ? AppColors.gray200 : AppColors.gray800,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantity} × ${formatDAAmount(item.unitPrice)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isLight
                                      ? AppColors.gray500
                                      : AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatDAAmount(item.lineTotal),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () => context.go('/cart'),
                  child: const Text('New sale'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.isLight,
    this.warn = false,
  });

  final String label;
  final bool isLight;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: warn
            ? AppColors.warning.withValues(alpha: 0.15)
            : (isLight ? AppColors.gray100 : AppColors.gray800),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: warn
              ? AppColors.warning
              : (isLight ? AppColors.gray700 : AppColors.gray300),
        ),
      ),
    );
  }
}
