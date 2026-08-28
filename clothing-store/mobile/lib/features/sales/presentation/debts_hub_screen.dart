import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/app_refresh.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_feedback.dart';
import '../models/sale.dart';
import '../providers/sales_history_provider.dart';

const _kCream = Color(0xFFFBF8F1);
const _kEspresso = Color(0xFF2C1A11);
const _kEspressoLight = Color(0xFF6B5147);
const _kBorder = Color(0xFFE8DDD4);
const _kBorderDark = Color(0xFF3D342A);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardDark = Color(0xFF2A2319);
const _kSuccess = Color(0xFF2A9D8F);
const _kDebt = Color(0xFFD94F4F);
const _kCopper = Color(0xFF9E5240);

class DebtsHubScreen extends ConsumerStatefulWidget {
  const DebtsHubScreen({super.key});

  @override
  ConsumerState<DebtsHubScreen> createState() => _DebtsHubScreenState();
}

class _DebtsHubScreenState extends ConsumerState<DebtsHubScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openPaymentSheet(SaleHeader sale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DebtInstallmentSheet(sale: sale, parentRef: ref),
    );
  }

  Future<void> _quickMarkPaid(SaleHeader sale) async {
    final strings = ref.read(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isLight ? AppColors.white : AppColors.cardDark,
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
                  color: _kSuccess.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: _kSuccess, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                '${strings.fullySettled} #${sale.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.isFrench
                    ? 'Le montant restant dû est de ${formatDAAmount(sale.remainingAmount)}.\nConfirmer le règlement total de cette dette ?'
                    : 'Remaining due is ${formatDAAmount(sale.remainingAmount)}.\nConfirm full payment for this debt?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isLight ? AppColors.border : AppColors.borderDark, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          foregroundColor: isLight ? AppColors.dark : AppColors.onDark,
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(strings.cancel, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _kSuccess,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(strings.markFullyPaid, style: const TextStyle(fontWeight: FontWeight.w700)),
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

    if (confirm == true && mounted) {
      try {
        await ref.read(saleServiceProvider).recordPayment(
              sale.id,
              sale.remainingAmount,
              note: strings.isFrench ? 'Règlement total' : 'Full settlement',
            );
        ref.read(salesListProvider.notifier).refresh();
        refreshAfterInventoryChange(ref);
        if (mounted) {
          showAppSnackBar(
            context,
            '✓ ${strings.isFrench ? "Dette soldée avec succès" : "Debt fully settled"}',
            kind: AppSnackKind.success,
          );
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(context, 'Failed: $e', kind: AppSnackKind.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final salesState = ref.watch(salesListProvider);

    final bg = isLight ? _kCream : const Color(0xFF1A1310);

    // Filter only sales with remaining debt
    final debtSales = salesState.items.where((s) => s.hasDebt).toList();

    // Filter by customer search query
    final filteredDebts = _searchQuery.isEmpty
        ? debtSales
        : debtSales.where((s) {
            final name = (s.customerName ?? '').toLowerCase();
            final idStr = s.id.toString();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || idStr.contains(query);
          }).toList();

    final totalDebtAmount = debtSales.fold<int>(0, (sum, s) => sum + s.remainingAmount);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isLight ? _kEspresso : Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          strings.customerDebts,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isLight ? _kEspresso : Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(salesListProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
          children: [
            // ── Total Debt Summary Card ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isLight ? _kCardBg : _kCardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kDebt.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: _kDebt.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_actions_rounded, size: 16, color: _kDebt),
                      const SizedBox(width: 8),
                      Text(
                        strings.totalDueDebts,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kDebt,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kDebt.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${debtSales.length} ${strings.isFrench ? "clients débiteurs" : "pending"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kDebt,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatDAAmount(totalDebtAmount),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: _kDebt,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.isFrench
                        ? 'Enregistrez des versements partiels ou réglez la totalité'
                        : 'Record partial installments or settle the entire debt',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLight ? _kEspressoLight : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Live Customer Search Bar ──────────────────────────────
            TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: strings.searchCustomer,
                prefixIcon: const Icon(Icons.person_search_outlined),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isLight ? _kCardBg : _kCardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCopper, width: 1.6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 18),

            // ── Debts List ────────────────────────────────────────────
            if (filteredDebts.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLight ? _kCardBg : _kCardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isLight ? _kBorder : _kBorderDark),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.sentiment_satisfied_alt_outlined, size: 48, color: _kSuccess),
                    const SizedBox(height: 12),
                    Text(
                      strings.noDebtsFound,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isLight ? _kEspresso : Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredDebts.map((sale) {
                final pctPaid = sale.totalAmount > 0
                    ? (sale.paidAmount / sale.totalAmount).clamp(0.0, 1.0)
                    : 1.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isLight ? _kCardBg : _kCardDark,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: isLight ? _kBorder : _kBorderDark),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => context.push(AppRouteNames.saleDetailPath(sale.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Customer Name + Date
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (isLight ? _kEspresso : Colors.white).withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person_outline_rounded, color: isLight ? _kEspresso : Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sale.customerName?.isNotEmpty == true
                                          ? sale.customerName!
                                          : '${strings.sales} #${sale.id}',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: isLight ? _kEspresso : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      appDateFormat.format(sale.createdAt.toLocal()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isLight ? _kEspressoLight : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Remaining Due Badge
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    strings.remaining,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isLight ? _kEspressoLight : Colors.white54,
                                    ),
                                  ),
                                  Text(
                                    formatDAAmount(sale.remainingAmount),
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: _kDebt,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: pctPaid,
                              minHeight: 6,
                              backgroundColor: (isLight ? _kEspresso : Colors.white).withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(_kCopper),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Metrics: Total vs Paid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${strings.paid}: ${formatDAAmount(sale.paidAmount)} / ${formatDAAmount(sale.totalAmount)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isLight ? _kEspressoLight : Colors.white70,
                                ),
                              ),
                              Text(
                                '${(pctPaid * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kCopper,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Action Buttons: Partial Installment vs Settle Full
                          Row(
                            children: [
                              // Installment Button
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 44,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _kCopper,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.payments_outlined, size: 16),
                                    label: Text(
                                      strings.recordInstallment,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    onPressed: () => _openPaymentSheet(sale),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Full Settle Button
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _kSuccess,
                                      side: const BorderSide(color: _kSuccess, width: 1.4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => _quickMarkPaid(sale),
                                    child: Text(
                                      strings.payFull,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
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
              }),
          ],
        ),
      ),
    );
  }
}

// ─── Installment Payment Bottom Sheet ────────────────────────────────────────

class _DebtInstallmentSheet extends StatefulWidget {
  const _DebtInstallmentSheet({required this.sale, required this.parentRef});

  final SaleHeader sale;
  final WidgetRef parentRef;

  @override
  State<_DebtInstallmentSheet> createState() => _DebtInstallmentSheetState();
}

class _DebtInstallmentSheetState extends State<_DebtInstallmentSheet> {
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
    final strings = widget.parentRef.read(appStringsProvider);
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, strings.isFrench ? 'Montant invalide' : 'Invalid amount', kind: AppSnackKind.error);
      return;
    }
    if (amount > widget.sale.remainingAmount) {
      showAppSnackBar(
        context,
        '${strings.isFrench ? "Dépasse le montant dû :" : "Exceeds remaining due:"} ${formatDAAmount(widget.sale.remainingAmount)}',
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
      widget.parentRef.read(salesListProvider.notifier).refresh();
      refreshAfterInventoryChange(widget.parentRef);
      Navigator.pop(context);
      showAppSnackBar(
        context,
        '✓ ${formatDAAmount(amount)} ${strings.isFrench ? "enregistré avec succès" : "recorded"}',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error: $e', kind: AppSnackKind.error);
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
        top: 14,
        left: 22,
        right: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isLight ? _kBorder : _kBorderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.recordInstallment,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLight ? _kEspresso : Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kDebt.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${strings.due} ${formatDAAmount(remaining)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kDebt,
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
                backgroundColor: _kSuccess.withValues(alpha: 0.15),
                label: Text(strings.payFull, style: const TextStyle(color: _kSuccess, fontWeight: FontWeight.w700)),
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kCopper,
            ),
            decoration: InputDecoration(
              labelText: strings.amountPaid,
              hintText: 'ex: 1000',
              prefixIcon: const Icon(Icons.payments_outlined, color: _kCopper),
              suffixText: 'DA',
              suffixStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _kCopper),
              filled: true,
              fillColor: isLight ? _kCream : Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCopper, width: 1.6)),
            ),
          ),
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: '${strings.notes} (${strings.isFrench ? "Optionnel" : "Optional"})',
              hintText: 'ex: 1er versement en espèces',
              prefixIcon: const Icon(Icons.description_outlined),
              filled: true,
              fillColor: isLight ? _kCream : Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCopper, width: 1.6)),
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kCopper,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(strings.recordInstallment, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
