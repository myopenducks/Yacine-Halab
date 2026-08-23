import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
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

  List<Product> _products = const [];
  bool _loadingProducts = false;
  String? _loadError;
  int? _selectedCategoryId;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _customerCtrl.dispose();
    _notesCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions({String? search, int? categoryId}) async {
    setState(() {
      _loadingProducts = true;
      _loadError = null;
    });
    try {
      final page = await ref.read(productServiceProvider).list(
            page: 1,
            limit: 40,
            search: search,
            categoryId: categoryId,
          );
      if (!mounted) return;
      setState(() {
        _products = page.items;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _loadError = 'Failed to load products';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      _loadSuggestions(
        search: value.trim().isEmpty ? null : value.trim(),
        categoryId: _selectedCategoryId,
      );
    });
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadSuggestions(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      categoryId: categoryId,
    );
  }

  void _add(Product p) {
    final err = ref.read(newSaleProvider.notifier).addProduct(p);
    if (err != null) {
      showAppSnackBar(context, err, kind: AppSnackKind.error);
      return;
    }
    HapticFeedback.selectionClick();
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
          ? 'Sale #${sale.id} – remaining: ${formatDAAmount(sale.remainingAmount)}'
          : 'Sale #${sale.id} confirmed',
      kind: sale.hasDebt ? AppSnackKind.warning : AppSnackKind.success,
    );
    setState(() => _showDetails = false);
    _customerCtrl.clear();
    _notesCtrl.clear();
    _paidCtrl.clear();
    _searchCtrl.clear();
    _loadSuggestions();
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
    final strings = ref.watch(appStringsProvider);
    final cart = ref.watch(newSaleProvider);
    final notifier = ref.read(newSaleProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    final int debtAmount = cart.paidAmount != null
        ? (cart.totalAmount - cart.paidAmount!).clamp(0, cart.totalAmount)
        : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(strings.newSale, style: theme.textTheme.headlineSmall),
        actions: [
          if (!cart.isEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Clear'),
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
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: strings.searchProducts,
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
                fillColor: isLight ? AppColors.white : AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight ? AppColors.border : AppColors.borderDark,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight ? AppColors.border : AppColors.borderDark,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── Category Chips Filter ──────────────────────────────────
          categoriesAsync.maybeWhen(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    ChoiceChip(
                      label: Text(strings.all),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) => _onCategorySelected(null),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: _selectedCategoryId == c.id,
                          onSelected: (selected) {
                            _onCategorySelected(selected ? c.id : null);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),

          // ── Main Content Area ──────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: [
                // ── Active Cart Section (if items in cart) ────────────
                if (!cart.isEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${strings.cartItems} (${cart.distinctCount})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${cart.unitCount} units',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...cart.lines.asMap().entries.map((entry) {
                    final line = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CartLineTile(
                        line: line,
                        onIncrement: () => notifier.increment(line.product.id),
                        onDecrement: () => notifier.decrement(line.product.id),
                        onRemove: () => notifier.remove(line.product.id),
                      ),
                    );
                  }),

                  // ── Customer & Payment details accordion ────────────
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _showDetails = !_showDetails),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isLight ? AppColors.white : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? AppColors.border : AppColors.borderDark,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 20,
                            color: isLight ? AppColors.secondary : AppColors.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cart.customerName != null
                                  ? '${strings.customerName}: ${cart.customerName}'
                                  : '${strings.customerName} & ${strings.notes}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: cart.customerName != null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (cart.hasDebt)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.debtRed.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${strings.due} ${formatDAAmount(debtAmount)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.debtRed,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Icon(
                            _showDetails ? Icons.expand_less : Icons.expand_more,
                            color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showDetails) ...[
                    const SizedBox(height: 10),
                    _DetailField(
                      controller: _customerCtrl,
                      hint: strings.customerName,
                      icon: Icons.person_outline,
                      isLight: isLight,
                      onChanged: _onCustomerChanged,
                    ),
                    const SizedBox(height: 8),
                    _DetailField(
                      controller: _notesCtrl,
                      hint: strings.notes,
                      icon: Icons.note_outlined,
                      isLight: isLight,
                      maxLines: 2,
                      onChanged: _onNotesChanged,
                    ),
                    const SizedBox(height: 8),
                    _DetailField(
                      controller: _paidCtrl,
                      hint: strings.amountPaid,
                      icon: Icons.payments_outlined,
                      isLight: isLight,
                      keyboardType: TextInputType.number,
                      onChanged: _onPaidChanged,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    if (cart.paidAmount != null && cart.paidAmount! < cart.totalAmount) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.debtRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.debtRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.debtRed),
                            const SizedBox(width: 8),
                            Text(
                              '${strings.outstandingDebt}: ${formatDAAmount(debtAmount)}',
                              style: const TextStyle(
                                color: AppColors.debtRed,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 14),
                ],

                // ── Available Products / Suggestions Section ─────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchCtrl.text.isNotEmpty
                          ? '${strings.searchProducts} (${_products.length})'
                          : '${strings.availableProducts} (${_products.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (_loadingProducts)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_loadError != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_loadError!)),
                        TextButton(
                          onPressed: _loadSuggestions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_products.isEmpty && !_loadingProducts)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.white : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isLight ? AppColors.border : AppColors.borderDark,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 36,
                          color: isLight ? AppColors.gray400 : AppColors.gray600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            color: isLight ? AppColors.gray600 : AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._products.map((product) {
                    final inCartQty = cart.lines
                        .firstWhere(
                          (l) => l.product.id == product.id,
                          orElse: () => CartLine(product: product, quantity: 0),
                        )
                        .quantity;

                    final isOutOfStock = product.isOutOfStock;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
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
                      child: Row(
                        children: [
                          // Product Thumbnail / Category Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.checkroom_rounded,
                                        color: isLight ? AppColors.secondary : AppColors.onDark,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.checkroom_rounded,
                                    color: isLight ? AppColors.secondary : AppColors.onDark,
                                  ),
                          ),
                          const SizedBox(width: 14),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isOutOfStock
                                        ? AppColors.textMuted
                                        : (isLight ? AppColors.dark : AppColors.onDark),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isLight ? AppColors.border : AppColors.borderDark,
                                          width: 0.6,
                                        ),
                                      ),
                                      child: Text(
                                        product.categoryName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isLight ? AppColors.secondary : AppColors.onDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isOutOfStock ? strings.outOfStock : '${strings.inStock}: ${product.quantity}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isOutOfStock
                                            ? AppColors.danger
                                            : (isLight ? AppColors.textMuted : AppColors.textMutedDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Price & Quick Add Button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatDAAmount(product.sellingPrice),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: isLight ? AppColors.dark : AppColors.onDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (inCartQty > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'x$inCartQty',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 34,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isOutOfStock
                                          ? AppColors.gray300
                                          : AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                    onPressed: isOutOfStock ? null : () => _add(product),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),

      // ── Sticky Floating Checkout Bar ──────────────────────────────
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.white : AppColors.cardDark,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isLight ? AppColors.border : AppColors.borderDark,
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
                            color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatDAAmount(cart.totalAmount),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: isLight ? AppColors.dark : AppColors.onDark,
                              ),
                            ),
                            if (cart.paidAmount != null && cart.paidAmount! < cart.totalAmount)
                              Text(
                                '${strings.paid} ${formatDAAmount(cart.paidAmount!)} · ${strings.due} ${formatDAAmount(debtAmount)}',
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
                                    ? '${strings.confirmSale} (${strings.outstandingDebt})'
                                    : '${strings.confirmSale} (${formatDAAmount(cart.totalAmount)})',
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
        color: isLight ? AppColors.dark : AppColors.onDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        fillColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLight ? AppColors.border : AppColors.borderDark,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLight ? AppColors.border : AppColors.borderDark,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
