import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_feedback.dart';
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
              // ── Summary card ─────────────────────────────────────────
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
                    if (sale.customerName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16,
                              color: isLight
                                  ? AppColors.skyBlue
                                  : AppColors.softBlue),
                          const SizedBox(width: 6),
                          Text(
                            sale.customerName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          label: '${sale.itemCount} units',
                          isLight: isLight,
                        ),
                        _MetaChip(
                          label: 'Paid ${formatDAAmount(sale.paidAmount)}',
                          isLight: isLight,
                        ),
                        if (sale.hasDebt)
                          _MetaChip(
                            label:
                                'Due ${formatDAAmount(sale.remainingAmount)}',
                            isLight: isLight,
                            warn: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Notes ────────────────────────────────────────────────
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? AppColors.warmLinen.withValues(alpha: 0.6)
                        : AppColors.gray800,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLight ? AppColors.border : AppColors.gray700,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_outlined,
                          size: 18,
                          color: isLight
                              ? AppColors.skyBlue
                              : AppColors.softBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sale.notes!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Debt payment banner ───────────────────────────────────
              if (sale.hasDebt) ...[
                const SizedBox(height: 16),
                _RecordPaymentBanner(sale: sale, ref: ref, isLight: isLight),
              ],

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

// ── Record payment banner ─────────────────────────────────────────────────────

class _RecordPaymentBanner extends StatefulWidget {
  const _RecordPaymentBanner({
    required this.sale,
    required this.ref,
    required this.isLight,
  });

  final dynamic sale;
  final WidgetRef ref;
  final bool isLight;

  @override
  State<_RecordPaymentBanner> createState() => _RecordPaymentBannerState();
}

class _RecordPaymentBannerState extends State<_RecordPaymentBanner> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context, WidgetRef ref, int saleId) async {
    final amount = int.tryParse(_ctrl.text.trim());
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, 'Enter a valid amount', kind: AppSnackKind.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(saleServiceProvider).recordPayment(saleId, amount);
      if (!context.mounted) return;
      ref.invalidate(saleByIdProvider(saleId));
      ref.read(salesListProvider.notifier).refresh();
      showAppSnackBar(context, 'Payment recorded',
          kind: AppSnackKind.success);
      _ctrl.clear();
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, 'Failed: $e', kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.debtRed.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.debtRed.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppColors.debtRed),
              SizedBox(width: 8),
              Text(
                'Outstanding debt',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.debtRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Payment amount (DA)',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    fillColor:
                        isLight ? AppColors.inputFill : AppColors.inputFillDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.debtRed.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.debtRed.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.debtRed),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.debtRed,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () => _submit(context, widget.ref, widget.sale.id),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Pay'),
                ),
              ),
            ],
          ),
        ],
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
            ? AppColors.debtRed.withValues(alpha: 0.12)
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
              ? AppColors.debtRed
              : (isLight ? AppColors.gray700 : AppColors.gray300),
        ),
      ),
    );
  }
}
