import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/date.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_feedback.dart';
import '../models/sale.dart';
import '../providers/sales_history_provider.dart';

class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final int saleId;

  Future<void> _openEditDialog(
    BuildContext context,
    WidgetRef ref,
    SaleDetail sale,
  ) async {
    final strings = ref.read(appStringsProvider);
    final nameCtrl = TextEditingController(text: sale.customerName ?? '');
    final notesCtrl = TextEditingController(text: sale.notes ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        return Container(
          decoration: BoxDecoration(
            color: isLight ? AppColors.white : AppColors.cardDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.border : AppColors.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 24, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      strings.editCustomerNotes,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: strings.customerName,
                    hintText: 'e.g. Yacine',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesCtrl,
                  maxLines: 4,
                  minLines: 3,
                  decoration: InputDecoration(
                    labelText: strings.notes,
                    hintText: 'e.g. Paid 1000 DA, remaining 6520 DA',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(strings.cancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(strings.saveChanges),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true && context.mounted) {
      try {
        await ref.read(saleServiceProvider).updateSale(
              sale.id,
              customerName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            );
        ref.invalidate(saleByIdProvider(sale.id));
        ref.read(salesListProvider.notifier).refresh();
        if (context.mounted) {
          showAppSnackBar(context, 'Sale updated successfully', kind: AppSnackKind.success);
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, 'Failed to update: $e', kind: AppSnackKind.error);
        }
      }
    }
  }

  Future<void> _quickMarkPaid(BuildContext context, WidgetRef ref, SaleDetail sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Settle Entire Debt for Sale #${sale.id}?'),
          content: Text(
            'Remaining due is ${formatDAAmount(sale.remainingAmount)}.\nMark this sale as fully paid?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark Fully Paid'),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(saleServiceProvider).recordPayment(
              sale.id,
              sale.remainingAmount,
              note: 'Full settlement',
            );
        ref.invalidate(saleByIdProvider(sale.id));
        ref.read(salesListProvider.notifier).refresh();
        ref.invalidate(debtBadgeCountProvider);
        if (context.mounted) {
          showAppSnackBar(
            context,
            'Sale #${sale.id} settled and marked as fully paid! 🎉',
            kind: AppSnackKind.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, 'Failed: $e', kind: AppSnackKind.error);
        }
      }
    }
  }

  void _openPaymentSheet(BuildContext context, WidgetRef ref, SaleDetail sale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecordPaymentSheet(sale: sale, parentRef: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final async = ref.watch(saleByIdProvider(saleId));
    final dateFmt = appDateTimeFormat;

    return Scaffold(
      backgroundColor: isLight ? AppColors.surfaceLight : AppColors.dark,
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
        actions: [
          async.maybeWhen(
            data: (sale) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit details',
              onPressed: () => _openEditDialog(context, ref, sale),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
          final pctPaid = sale.totalAmount > 0
              ? (sale.paidAmount / sale.totalAmount).clamp(0.0, 1.0)
              : 1.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // ── Main Summary Card ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.white : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isLight ? AppColors.border : AppColors.borderDark,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDAAmount(sale.totalAmount),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  color: isLight ? AppColors.dark : AppColors.onDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFmt.format(sale.createdAt.toLocal()),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (sale.customerName != null && sale.customerName!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLight ? AppColors.border : AppColors.borderDark,
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sale.customerName!,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isLight ? AppColors.dark : AppColors.onDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          label: '${sale.itemCount} ${strings.items}',
                          isLight: isLight,
                        ),
                        _MetaChip(
                          label: '${strings.paid} ${formatDAAmount(sale.paidAmount)}',
                          isLight: isLight,
                          color: AppColors.success,
                        ),
                        if (sale.hasDebt)
                          _MetaChip(
                            label: '${strings.due} ${formatDAAmount(sale.remainingAmount)}',
                            isLight: isLight,
                            warn: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Debt & Payment Breakdown Card ────────
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isLight ? AppColors.white : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: sale.hasDebt
                        ? AppColors.debtRed.withValues(alpha: 0.35)
                        : AppColors.success.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (sale.hasDebt ? AppColors.debtRed : AppColors.success)
                          .withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: sale.hasDebt
                            ? (isLight ? const Color(0xFFFFF1F1) : const Color(0xFF331A1A))
                            : (isLight ? const Color(0xFFF0FDF4) : const Color(0xFF16291C)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sale.hasDebt
                                ? Icons.pending_actions_rounded
                                : Icons.check_circle_rounded,
                            size: 20,
                            color: sale.hasDebt ? AppColors.debtRed : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sale.hasDebt ? strings.debtStatus : strings.paymentComplete,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: sale.hasDebt ? AppColors.debtRed : AppColors.success,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (sale.hasDebt ? AppColors.debtRed : AppColors.success)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(pctPaid * 100).toInt()}% ${strings.paid}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: sale.hasDebt ? AppColors.debtRed : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card Body
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: pctPaid,
                              minHeight: 8,
                              backgroundColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                sale.hasDebt ? AppColors.primary : AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2-Column Metrics (Paid vs Remaining)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isLight ? AppColors.border : AppColors.borderDark,
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.paid,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatDAAmount(sale.paidAmount),
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: sale.hasDebt
                                        ? (isLight ? const Color(0xFFFFECEC) : const Color(0xFF381C1C))
                                        : (isLight ? AppColors.inputFill : AppColors.inputFillDark),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: sale.hasDebt
                                          ? AppColors.debtRed.withValues(alpha: 0.4)
                                          : (isLight ? AppColors.border : AppColors.borderDark),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.remaining,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: sale.hasDebt
                                              ? AppColors.debtRed
                                              : (isLight ? AppColors.textMuted : AppColors.textMutedDark),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatDAAmount(sale.remainingAmount),
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: sale.hasDebt
                                              ? AppColors.debtRed
                                              : (isLight ? AppColors.dark : AppColors.onDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (sale.hasDebt) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Record Payment
                                Expanded(
                                  flex: 3,
                                  child: SizedBox(
                                    height: 48,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      icon: const Icon(Icons.payments_outlined, size: 18),
                                      label: Text(
                                        strings.recordPayment,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      onPressed: () => _openPaymentSheet(context, ref, sale),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Pay Full
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.success, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () => _quickMarkPaid(context, ref, sale),
                                      child: Text(
                                        strings.payFull,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Notes Card ───────────────────────────────
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openEditDialog(context, ref, sale),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLight ? AppColors.white : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isLight ? AppColors.border : AppColors.borderDark,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.note_alt_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                strings.notes,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isLight ? AppColors.dark : AppColors.onDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sale.notes!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              height: 1.4,
                              color: isLight ? AppColors.dark : AppColors.onDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Text(
                '${strings.items} (${sale.items.length})',
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              ...sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.white : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight ? AppColors.border : AppColors.borderDark,
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isLight ? AppColors.dark : AppColors.onDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantity} × ${formatDAAmount(item.unitPrice)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatDAAmount(item.lineTotal),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isLight ? AppColors.dark : AppColors.onDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(strings.newSale),
                  onPressed: () => context.go('/cart'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Payment Bottom Sheet ──────────────────────────────────────

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({
    required this.sale,
    required this.parentRef,
  });

  final SaleDetail sale;
  final WidgetRef parentRef;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _setPreset(int amount) {
    final capped = amount.clamp(1, widget.sale.remainingAmount);
    _amountCtrl.text = '$capped';
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, 'Please enter a valid amount', kind: AppSnackKind.error);
      return;
    }
    if (amount > widget.sale.remainingAmount) {
      showAppSnackBar(
        context,
        'Amount exceeds remaining debt of ${formatDAAmount(widget.sale.remainingAmount)}',
        kind: AppSnackKind.error,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.parentRef.read(saleServiceProvider).recordPayment(
            widget.sale.id,
            amount,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (!mounted) return;
      widget.parentRef.invalidate(saleByIdProvider(widget.sale.id));
      widget.parentRef.read(salesListProvider.notifier).refresh();
      Navigator.pop(context);
      showAppSnackBar(
        context,
        'Payment of ${formatDAAmount(amount)} recorded successfully!',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Payment failed: $e', kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final strings = widget.parentRef.watch(appStringsProvider);
    final remaining = widget.sale.remainingAmount;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isLight ? AppColors.border : AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.recordPayment,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.debtRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${strings.due} ${formatDAAmount(remaining)}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.debtRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Presets
          Wrap(
            spacing: 8,
            children: [
              if (remaining >= 500)
                ActionChip(
                  label: const Text('+500 DA'),
                  onPressed: () => _setPreset(500),
                ),
              if (remaining >= 1000)
                ActionChip(
                  label: const Text('+1 000 DA'),
                  onPressed: () => _setPreset(1000),
                ),
              if (remaining >= 2000)
                ActionChip(
                  label: const Text('+2 000 DA'),
                  onPressed: () => _setPreset(2000),
                ),
              ActionChip(
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                label: Text(
                  strings.payFull,
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _setPreset(remaining),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Input
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: strings.amountPaid,
              hintText: 'e.g. 1000',
              prefixIcon: const Icon(Icons.payments_outlined),
              suffixText: 'DA',
              suffixStyle: const TextStyle(fontWeight: FontWeight.w700),
              filled: true,
              fillColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
            ),
          ),
          const SizedBox(height: 12),

          // Optional Note
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: '${strings.notes} (Optional)',
              hintText: 'e.g. Second installment',
              prefixIcon: const Icon(Icons.description_outlined),
              filled: true,
              fillColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
            ),
          ),
          const SizedBox(height: 20),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(
                      strings.recordPayment,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
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
    this.color,
  });

  final String label;
  final bool isLight;
  final bool warn;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? (warn ? AppColors.debtRed : AppColors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}
