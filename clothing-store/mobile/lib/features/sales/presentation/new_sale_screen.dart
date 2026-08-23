import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';
import '../providers/new_sale_provider.dart';
import 'widgets/cart_line_tile.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _searchCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  Timer? _debounce;
  List<Product> _hits = const [];
  bool _searching = false;
  String? _searchError;
  bool _pickerOpen = false;
  bool _showDetails = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _customerCtrl.dispose();
    _notesCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() => _pickerOpen = value.trim().isNotEmpty);
    if (value.trim().isEmpty) {
      setState(() {
        _hits = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 100), () {
      _runSearch(value.trim());
    });
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final page = await ref.read(productServiceProvider).list(
            page: 1,
            limit: 12,
            search: q,
          );
      if (!mounted) return;
      setState(() {
        _hits = page.items;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = 'Search failed';
        _hits = const [];
      });
    }
  }

  void _add(Product p) {
    final err = ref.read(newSaleProvider.notifier).addProduct(p);
    if (err != null) {
      showAppSnackBar(context, err, kind: AppSnackKind.error);
      return;
    }
    HapticFeedback.selectionClick();
    _searchCtrl.clear();
    setState(() {
      _pickerOpen = false;
      _hits = const [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _confirm() async {
    final sale = await ref.read(newSaleProvider.notifier).submit();
    if (!mounted) return;
    if (sale == null) {
      final err = ref.read(newSaleProvider).error;
      if (err != null) {
        showAppSnackBar(context, err, kind: AppSnackKind.error);
      }
      return;
    }
    HapticFeedback.mediumImpact();
    showAppSnackBar(
      context,
      sale.hasDebt
          ? 'Sale #${sale.id} – debt: ${formatDAAmount(sale.remainingAmount)}'
          : 'Sale #${sale.id} confirmed',
      kind: sale.hasDebt ? AppSnackKind.warning : AppSnackKind.success,
    );
    // Reset local field controllers
    setState(() => _showDetails = false);
    _customerCtrl.clear();
    _notesCtrl.clear();
    _paidCtrl.clear();
    context.push(AppRouteNames.saleDetailPath(sale.id));
  }

  void _onCustomerChanged(String v) {
    ref.read(newSaleProvider.notifier).setCustomerName(v);
  }

  void _onNotesChanged(String v) {
    ref.read(newSaleProvider.notifier).setNotes(v);
  }

  void _onPaidChanged(String v) {
    final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
    ref.read(newSaleProvider.notifier).setPaidAmount(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final cart = ref.watch(newSaleProvider);
    final notifier = ref.read(newSaleProvider.notifier);

    final int debtAmount = cart.paidAmount != null
        ? (cart.totalAmount - cart.paidAmount!).clamp(0, cart.totalAmount)
        : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('New sale', style: theme.textTheme.headlineSmall),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: cart.submitting
                  ? null
                  : () {
                      notifier.clear();
                      setState(() {
                        _showDetails = false;
                        _customerCtrl.clear();
                        _notesCtrl.clear();
                        _paidCtrl.clear();
                      });
                    },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products to add…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                fillColor: isLight ? AppColors.white : AppColors.gray900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight ? AppColors.gray200 : AppColors.gray800,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight ? AppColors.gray200 : AppColors.gray800,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight ? AppColors.black : AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          if (_pickerOpen) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: _SearchHits(
                searching: _searching,
                error: _searchError,
                hits: _hits,
                onAdd: _add,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: cart.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isLight ? AppColors.white : AppColors.gray900,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                isLight ? AppColors.gray200 : AppColors.gray800,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.point_of_sale_outlined,
                              size: 40,
                              color:
                                  isLight ? AppColors.black : AppColors.white,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Cart is empty',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Search above and tap a product to start a sale.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isLight
                                    ? AppColors.gray500
                                    : AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    children: [
                      ...cart.lines.asMap().entries.map((entry) {
                        final line = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CartLineTile(
                            line: line,
                            onIncrement: () =>
                                notifier.increment(line.product.id),
                            onDecrement: () =>
                                notifier.decrement(line.product.id),
                            onRemove: () => notifier.remove(line.product.id),
                          ),
                        );
                      }),

                      // ── Customer & payment details toggle ───────────────
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () =>
                            setState(() => _showDetails = !_showDetails),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isLight
                                ? AppColors.warmLinen.withValues(alpha: 0.5)
                                : AppColors.gray800,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isLight ? AppColors.border : AppColors.gray700,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 20,
                                color: isLight
                                    ? AppColors.skyBlue
                                    : AppColors.softBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cart.customerName != null
                                      ? cart.customerName!
                                      : 'Add customer & payment info',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: cart.customerName != null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: cart.customerName != null
                                        ? (isLight
                                            ? AppColors.gray900
                                            : AppColors.onDark)
                                        : (isLight
                                            ? AppColors.gray500
                                            : AppColors.gray400),
                                  ),
                                ),
                              ),
                              if (cart.hasDebt)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.debtRed
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    'Debt ${formatDAAmount(debtAmount)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.debtRed,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Icon(
                                _showDetails
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color:
                                    isLight ? AppColors.gray500 : AppColors.gray400,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_showDetails) ...[
                        const SizedBox(height: 10),
                        _DetailField(
                          controller: _customerCtrl,
                          hint: 'Customer name',
                          icon: Icons.person_outline,
                          isLight: isLight,
                          onChanged: _onCustomerChanged,
                        ),
                        const SizedBox(height: 8),
                        _DetailField(
                          controller: _notesCtrl,
                          hint: 'Note (e.g. paid 1000, owes 550 DA)',
                          icon: Icons.note_outlined,
                          isLight: isLight,
                          maxLines: 2,
                          onChanged: _onNotesChanged,
                        ),
                        const SizedBox(height: 8),
                        _DetailField(
                          controller: _paidCtrl,
                          hint: 'Amount paid (DA) — leave empty if full',
                          icon: Icons.payments_outlined,
                          isLight: isLight,
                          keyboardType: TextInputType.number,
                          onChanged: _onPaidChanged,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        if (cart.paidAmount != null &&
                            cart.paidAmount! < cart.totalAmount) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.debtRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.debtRed.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 18, color: AppColors.debtRed),
                                const SizedBox(width: 8),
                                Text(
                                  'Outstanding debt: ${formatDAAmount(debtAmount)}',
                                  style: const TextStyle(
                                    color: AppColors.debtRed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.white : AppColors.gray900,
                  border: Border(
                    top: BorderSide(
                      color: isLight ? AppColors.gray200 : AppColors.gray800,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cart.error != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          cart.error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Text(
                          '${cart.unitCount} item${cart.unitCount == 1 ? '' : 's'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                isLight ? AppColors.gray500 : AppColors.gray400,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatDAAmount(cart.totalAmount),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                            if (cart.paidAmount != null &&
                                cart.paidAmount! < cart.totalAmount)
                              Text(
                                'Paid ${formatDAAmount(cart.paidAmount!)}',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.debtRed,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: cart.submitting ? null : _confirm,
                        child: cart.submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                cart.hasDebt
                                    ? 'Confirm (partial payment)'
                                    : 'Confirm sale',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isLight,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isLight;
  final void Function(String) onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14,
        color: isLight ? AppColors.gray900 : AppColors.onDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        fillColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLight ? AppColors.gray200 : AppColors.gray800,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLight ? AppColors.border : AppColors.gray800,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLight ? AppColors.skyBlue : AppColors.softBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _SearchHits extends StatelessWidget {
  const _SearchHits({
    required this.searching,
    required this.error,
    required this.hits,
    required this.onAdd,
  });

  final bool searching;
  final String? error;
  final List<Product> hits;
  final void Function(Product) onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (searching) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(error!, style: const TextStyle(color: AppColors.danger)),
      );
    }
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          'No products match',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isLight ? AppColors.gray500 : AppColors.gray400,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: hits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final p = hits[i];
        final disabled = p.isOutOfStock;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : () => onAdd(p),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isLight ? AppColors.white : AppColors.gray900,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLight ? AppColors.gray200 : AppColors.gray800,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: disabled
                                ? (isLight
                                    ? AppColors.gray400
                                    : AppColors.gray500)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.categoryName} · qty ${p.quantity}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isLight ? AppColors.gray500 : AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatDAAmount(p.sellingPrice),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: disabled ? AppColors.gray400 : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    disabled ? Icons.block : Icons.add_circle_outline,
                    size: 22,
                    color: disabled
                        ? AppColors.gray400
                        : (isLight ? AppColors.black : AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
