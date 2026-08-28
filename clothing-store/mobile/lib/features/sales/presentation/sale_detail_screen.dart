import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/app_refresh.dart';
import '../../../core/utils/date.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_feedback.dart';
import '../models/sale.dart';
import '../providers/sales_history_provider.dart';

// ─── Boutique palette constants ─────────────────────────────────────────────
const _kCream = Color(0xFFFBF8F1);
const _kEspresso = Color(0xFF2C1A11);
const _kEspressoLight = Color(0xFF6B5147);
const _kBorder = Color(0xFFE8DDD4);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardDark = Color(0xFF2A2319);
const _kBorderDark = Color(0xFF3D342A);
const _kSuccess = Color(0xFF2A9D8F);
const _kDebt = Color(0xFFD94F4F);
const _kCopper = Color(0xFF9E5240);

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
    final isLight = Theme.of(context).brightness == Brightness.light;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isLight ? _kCardBg : _kCardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: isLight ? _kBorder : _kBorderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.editCustomerNotes,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLight ? _kEspresso : Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _BoutiqueField(
                controller: nameCtrl,
                label: strings.customerName,
                hint: 'e.g. Yacine',
                icon: Icons.person_outline_rounded,
                isLight: isLight,
              ),
              const SizedBox(height: 14),
              _BoutiqueField(
                controller: notesCtrl,
                label: strings.notes,
                hint: 'e.g. Paid 1 000 DA, remaining 6 500 DA',
                icon: Icons.notes_rounded,
                isLight: isLight,
                maxLines: 4,
                minLines: 3,
                alignLabelWithHint: true,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _BoutiqueOutlineButton(
                      label: strings.cancel,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _BoutiqueFilledButton(
                      label: strings.saveChanges,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          showAppSnackBar(context, strings.isFrench ? 'Vente mise à jour ✓' : 'Sale updated ✓',
              kind: AppSnackKind.success);
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, 'Failed to update: $e', kind: AppSnackKind.error);
        }
      }
    }
  }

  Future<void> _quickMarkPaid(BuildContext context, WidgetRef ref, SaleDetail sale) async {
    final strings = ref.read(appStringsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          strings.isFrench
              ? 'Régler la dette #${sale.id} ?'
              : 'Settle Debt #${sale.id}?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Text(
          strings.isFrench
              ? 'Montant restant : ${formatDAAmount(sale.remainingAmount)}.\nMarquer comme entièrement réglé ?'
              : 'Remaining: ${formatDAAmount(sale.remainingAmount)}.\nMark as fully paid?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: _BoutiqueOutlineButton(
                  label: strings.cancel,
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _BoutiqueFilledButton(
                  label: strings.markFullyPaid,
                  onPressed: () => Navigator.pop(ctx, true),
                  color: _kSuccess,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(saleServiceProvider).recordPayment(
              sale.id,
              sale.remainingAmount,
              note: strings.isFrench ? 'Règlement total' : 'Full settlement',
            );
        ref.invalidate(saleByIdProvider(sale.id));
        refreshAfterInventoryChange(ref);
        if (context.mounted) {
          showAppSnackBar(context, '✓ ${strings.isFrench ? "Vente soldée !" : "Sale fully settled!"}',
              kind: AppSnackKind.success);
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, SaleDetail sale) async {
    final strings = ref.read(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isLight ? _kCardBg : _kCardDark,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kDebt.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _kDebt,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${strings.deleteSale} #${sale.id}',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isLight ? _kEspresso : Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.deleteSaleConfirm,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  color: isLight ? _kEspressoLight : Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: _BoutiqueOutlineButton(
                        label: strings.cancel,
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: _BoutiqueFilledButton(
                        label: strings.delete,
                        onPressed: () => Navigator.of(ctx).pop(true),
                        color: _kDebt,
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

    if (confirmed != true) return;

    try {
      await ref.read(saleServiceProvider).deleteSale(sale.id);
      refreshAfterInventoryChange(ref);
      if (context.mounted) {
        showAppSnackBar(context, strings.saleDeleted, kind: AppSnackKind.success);
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Failed to delete sale', kind: AppSnackKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(saleByIdProvider(saleId));
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final bg = isLight ? _kCream : const Color(0xFF1A1310);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isLight ? _kEspresso : Colors.white,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/cart');
            }
          },
        ),
        title: async.maybeWhen(
          data: (sale) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${strings.isFrench ? "Vente" : "Sale"} #$saleId',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLight ? _kEspresso : Colors.white,
                ),
              ),
              Text(
                appDateTimeFormat.format(sale.createdAt.toLocal()),
                style: TextStyle(
                  fontSize: 12,
                  color: isLight ? _kEspressoLight : Colors.white60,
                ),
              ),
            ],
          ),
          orElse: () => Text(
            '${strings.isFrench ? "Vente" : "Sale"} #$saleId',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isLight ? _kEspresso : Colors.white,
            ),
          ),
        ),
        actions: [
          async.maybeWhen(
            data: (sale) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: isLight ? _kEspressoLight : Colors.white70),
                  tooltip: strings.editCustomerNotes,
                  onPressed: () => _openEditDialog(context, ref, sale),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: _kDebt),
                  tooltip: strings.deleteSale,
                  onPressed: () => _confirmDelete(context, ref, sale),
                ),
                const SizedBox(width: 4),
              ],
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
                _BoutiqueFilledButton(
                  label: strings.retry,
                  onPressed: () => ref.invalidate(saleByIdProvider(saleId)),
                ),
              ],
            ),
          ),
        ),
        data: (sale) {
          final pctPaid = sale.totalAmount > 0
              ? (sale.paidAmount / sale.totalAmount).clamp(0.0, 1.0)
              : 1.0;
          final statusColor = sale.hasDebt ? _kDebt : _kSuccess;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
            children: [
              // ── Hero Amount Banner ───────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: BoxDecoration(
                  color: isLight ? _kCardBg : _kCardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isLight ? _kBorder : _kBorderDark),
                  boxShadow: [
                    BoxShadow(
                      color: _kEspresso.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    Text(
                      formatDAAmount(sale.totalAmount),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isLight ? _kEspresso : Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Customer name (if any)
                    if (sale.customerName != null && sale.customerName!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 14,
                              color: isLight ? _kEspressoLight : Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            sale.customerName!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isLight ? _kEspressoLight : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ] else
                      const SizedBox(height: 12),
                    // Meta chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatusPill(
                          label: '${sale.itemCount} ${strings.items}',
                          color: isLight ? _kEspressoLight : Colors.white54,
                          bg: (isLight ? _kEspresso : Colors.white).withValues(alpha: 0.07),
                        ),
                        _StatusPill(
                          label: '${strings.paid} ${formatDAAmount(sale.paidAmount)}',
                          color: _kSuccess,
                          bg: _kSuccess.withValues(alpha: 0.10),
                        ),
                        if (sale.hasDebt)
                          _StatusPill(
                            label: '${strings.due} ${formatDAAmount(sale.remainingAmount)}',
                            color: _kDebt,
                            bg: _kDebt.withValues(alpha: 0.10),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Payment Status Card ──────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isLight ? _kCardBg : _kCardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.30),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.07),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sale.hasDebt
                                ? Icons.pending_actions_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                            color: statusColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            sale.hasDebt ? strings.debtStatus : strings.paymentComplete,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${(pctPaid * 100).toInt()}% ${strings.paid}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: pctPaid,
                              minHeight: 6,
                              backgroundColor: (isLight ? _kEspresso : Colors.white)
                                  .withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Paid vs Remaining
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCell(
                                  label: strings.paid,
                                  value: formatDAAmount(sale.paidAmount),
                                  valueColor: _kSuccess,
                                  isLight: isLight,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricCell(
                                  label: strings.remaining,
                                  value: formatDAAmount(sale.remainingAmount),
                                  valueColor: sale.hasDebt
                                      ? _kDebt
                                      : (isLight ? _kEspressoLight : Colors.white60),
                                  isLight: isLight,
                                  highlight: sale.hasDebt,
                                ),
                              ),
                            ],
                          ),

                          if (sale.hasDebt) ...[
                            const SizedBox(height: 16),
                            // CTA buttons
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _BoutiqueFilledButton(
                                    label: strings.recordPayment,
                                    icon: Icons.payments_outlined,
                                    onPressed: () => _openPaymentSheet(context, ref, sale),
                                    color: _kCopper,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: _BoutiqueOutlineButton(
                                    label: strings.payFull,
                                    color: _kSuccess,
                                    onPressed: () => _quickMarkPaid(context, ref, sale),
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

              // ── Notes ────────────────────────────────────────────────
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _openEditDialog(context, ref, sale),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isLight ? _kCardBg : _kCardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isLight ? _kBorder : _kBorderDark),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 16, color: isLight ? _kEspressoLight : Colors.white60),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.notes,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isLight ? _kEspressoLight : Colors.white60,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sale.notes!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: isLight ? _kEspresso : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: isLight ? _kBorder : _kBorderDark),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Items Section ─────────────────────────────────────────
              const SizedBox(height: 28),
              Text(
                '${strings.items} (${sale.items.length})',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLight ? _kEspresso : Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...sale.items.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isLight ? _kCardBg : _kCardDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isLight ? _kBorder : _kBorderDark),
                    ),
                    child: Row(
                      children: [
                        // Index badge
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: (isLight ? _kEspresso : Colors.white).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isLight ? _kEspressoLight : Colors.white54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isLight ? _kEspresso : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.quantity} × ${formatDAAmount(item.unitPrice)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLight ? _kEspressoLight : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatDAAmount(item.lineTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isLight ? _kEspresso : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              _BoutiqueOutlineButton(
                label: strings.newSale,
                icon: Icons.add_shopping_cart_rounded,
                onPressed: () => context.go('/cart'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Payment Bottom Sheet ────────────────────────────────────────────────────

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({required this.sale, required this.parentRef});

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
      showAppSnackBar(context, 'Montant invalide', kind: AppSnackKind.error);
      return;
    }
    if (amount > widget.sale.remainingAmount) {
      showAppSnackBar(context,
          'Dépasse le montant dû : ${formatDAAmount(widget.sale.remainingAmount)}',
          kind: AppSnackKind.error);
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
      refreshAfterInventoryChange(widget.parentRef);
      Navigator.pop(context);
      showAppSnackBar(
        context,
        '✓ ${formatDAAmount(amount)} enregistré',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Échec : $e', kind: AppSnackKind.error);
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
        color: isLight ? AppColors.white : _kCardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 3.5,
              decoration: BoxDecoration(
                color: isLight ? _kBorder : _kBorderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.recordPayment,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLight ? _kEspresso : Colors.white,
                ),
              ),
              _StatusPill(
                label: '${strings.due} ${formatDAAmount(remaining)}',
                color: _kDebt,
                bg: _kDebt.withValues(alpha: 0.10),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quick Presets
          Wrap(
            spacing: 8,
            children: [
              if (remaining >= 500)
                _PresetChip(label: '+500 DA', onTap: () => _setPreset(500)),
              if (remaining >= 1000)
                _PresetChip(label: '+1 000 DA', onTap: () => _setPreset(1000)),
              if (remaining >= 2000)
                _PresetChip(label: '+2 000 DA', onTap: () => _setPreset(2000)),
              _PresetChip(
                label: strings.payFull,
                onTap: () => _setPreset(remaining),
                color: _kSuccess,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Amount field
          _BoutiqueField(
            controller: _amountCtrl,
            label: strings.amountPaid,
            hint: 'ex: 1000',
            icon: Icons.payments_outlined,
            suffix: 'DA',
            isLight: isLight,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
          ),
          const SizedBox(height: 12),

          // Optional note field
          _BoutiqueField(
            controller: _noteCtrl,
            label: '${strings.notes} (optionnel)',
            hint: 'ex: 2ème versement',
            icon: Icons.description_outlined,
            isLight: isLight,
          ),
          const SizedBox(height: 24),

          _BoutiqueFilledButton(
            label: strings.recordPayment,
            onPressed: _loading ? null : _submit,
            color: _kSuccess,
            loading: _loading,
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Boutique Components ────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isLight,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isLight;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? _kDebt.withValues(alpha: 0.06)
        : (isLight ? _kCream : Colors.white.withValues(alpha: 0.04));
    final border = highlight ? _kDebt.withValues(alpha: 0.25) : (isLight ? _kBorder : _kBorderDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isLight ? _kEspressoLight : Colors.white60,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap, this.color});
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _kEspressoLight;
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      backgroundColor: c.withValues(alpha: 0.08),
      side: BorderSide(color: c.withValues(alpha: 0.25)),
      onPressed: onTap,
    );
  }
}

class _BoutiqueField extends StatelessWidget {
  const _BoutiqueField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isLight,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    this.alignLabelWithHint = false,
    this.keyboardType,
    this.inputFormatters,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isLight;
  final String? suffix;
  final int maxLines;
  final int? minLines;
  final bool alignLabelWithHint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: isLight ? _kEspresso : Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _kCopper,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: alignLabelWithHint,
        suffixText: suffix,
        suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: _kEspressoLight),
        prefixIcon: Icon(icon, size: 18, color: isLight ? _kEspressoLight : Colors.white60),
        labelStyle: TextStyle(color: isLight ? _kEspressoLight : Colors.white60, fontSize: 14),
        filled: true,
        fillColor: isLight ? _kCream : Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kCopper, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _BoutiqueFilledButton extends StatelessWidget {
  const _BoutiqueFilledButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = _kEspresso,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
      ),
    );
  }
}

class _BoutiqueOutlineButton extends StatelessWidget {
  const _BoutiqueOutlineButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = _kEspresso,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isLight ? color : color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
