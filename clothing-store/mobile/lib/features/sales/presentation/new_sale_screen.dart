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
import '../../products/presentation/widgets/category_dropdown_selector.dart';
import '../../products/providers/products_provider.dart';
import '../providers/new_sale_provider.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/sale_product_tile.dart';

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
  int? _selectedCategoryId;
  bool _showDetails = false;

  List<Product> _products = [];
  bool _loadingProducts = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
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

  Future<void> _loadProducts({String? search, int? categoryId}) async {
    setState(() {
      _loadingProducts = true;
      _loadError = null;
    });

    try {
      final res = await ref.read(productServiceProvider).list(
            page: 1,
            limit: 100,
            search: search,
            categoryId: categoryId,
          );
      if (!mounted) return;
      setState(() {
        _products = res.items;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingProducts = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadProducts(
        search: query.isEmpty ? null : query,
        categoryId: _selectedCategoryId,
      );
    });
  }

  void _onCategorySelected(int? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadProducts(
      search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      categoryId: categoryId,
    );
  }

  void _clearCart() {
    final strings = ref.read(appStringsProvider);
    ref.read(newSaleProvider.notifier).clear();
    _customerCtrl.clear();
    _notesCtrl.clear();
    _paidCtrl.clear();
    showAppSnackBar(context, strings.clearCart, kind: AppSnackKind.info);
  }

  void _reloadIfSaleTabActive() {
    _loadProducts(
      search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      categoryId: _selectedCategoryId,
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
    _loadProducts();
    context.push(AppRouteNames.saleDetailPath(sale.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(strings.newSale, style: theme.textTheme.headlineSmall),
        actions: [
          IconButton(
            tooltip: strings.sales,
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push(AppRouteNames.homeHistoryPath),
          ),
          if (ref.watch(newSaleProvider).lines.isNotEmpty)
            IconButton(
              tooltip: strings.clearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: ref.read(newSaleProvider).submitting ? null : _clearCart,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: categoriesAsync.maybeWhen(
              data: (categories) {
                if (categories.isEmpty) return const SizedBox.shrink();
                return CategoryDropdownSelector(
                  categories: categories,
                  selectedCategoryId: _selectedCategoryId,
                  allCategoriesLabel: strings.allCategories,
                  addCategoryLabel: strings.addCategory,
                  isLight: isLight,
                  onSelectCategory: _onCategorySelected,
                  onAddCategory: () {},
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _NewSaleCartSection(
                      showDetails: _showDetails,
                      customerCtrl: _customerCtrl,
                      notesCtrl: _notesCtrl,
                      paidCtrl: _paidCtrl,
                      onToggleDetails: () =>
                          setState(() => _showDetails = !_showDetails),
                      onCustomerChanged: (v) =>
                          ref.read(newSaleProvider.notifier).setCustomerName(v),
                      onNotesChanged: (v) =>
                          ref.read(newSaleProvider.notifier).setNotes(v),
                      onPaidChanged: (v) {
                        final parsed =
                            int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                        ref.read(newSaleProvider.notifier).setPaidAmount(parsed);
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Row(
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
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (_loadError != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_loadError!)),
                            TextButton(
                              onPressed: _reloadIfSaleTabActive,
                              child: Text(strings.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_products.isEmpty && !_loadingProducts)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
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
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = _products[index];
                          return _SaleProductTileWrapper(
                            key: ValueKey(product.id),
                            product: product,
                            isLight: isLight,
                            strings: strings,
                            onAdd: product.isOutOfStock ? null : () => _add(product),
                          );
                        },
                        childCount: _products.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _NewSaleCheckoutBar(onConfirm: _confirm),
    );
  }
}

class _NewSaleCartSection extends ConsumerWidget {
  const _NewSaleCartSection({
    required this.showDetails,
    required this.customerCtrl,
    required this.notesCtrl,
    required this.paidCtrl,
    required this.onToggleDetails,
    required this.onCustomerChanged,
    required this.onNotesChanged,
    required this.onPaidChanged,
  });

  final bool showDetails;
  final TextEditingController customerCtrl;
  final TextEditingController notesCtrl;
  final TextEditingController paidCtrl;
  final VoidCallback onToggleDetails;
  final void Function(String) onCustomerChanged;
  final void Function(String) onNotesChanged;
  final void Function(String) onPaidChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(newSaleProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final notifier = ref.read(newSaleProvider.notifier);
    final debtAmount = cart.paidAmount != null
        ? (cart.totalAmount - cart.paidAmount!).clamp(0, cart.totalAmount)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ...cart.lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CartLineTile(
              line: line,
              onIncrement: () => notifier.increment(line.product.id),
              onDecrement: () => notifier.decrement(line.product.id),
              onRemove: () => notifier.remove(line.product.id),
              onEditPrice: () => _showEditPriceDialog(context, ref, line),
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onToggleDetails,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  showDetails ? Icons.expand_less : Icons.expand_more,
                  color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                ),
              ],
            ),
          ),
        ),
        if (showDetails) ...[
          const SizedBox(height: 10),
          _DetailField(
            controller: customerCtrl,
            hint: strings.customerName,
            icon: Icons.person_outline,
            isLight: isLight,
            onChanged: onCustomerChanged,
          ),
          const SizedBox(height: 8),
          _DetailField(
            controller: notesCtrl,
            hint: strings.notes,
            icon: Icons.note_outlined,
            isLight: isLight,
            maxLines: 2,
            onChanged: onNotesChanged,
          ),
          const SizedBox(height: 8),
          _DetailField(
            controller: paidCtrl,
            hint: strings.amountPaid,
            icon: Icons.payments_outlined,
            isLight: isLight,
            keyboardType: TextInputType.number,
            onChanged: onPaidChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          if (cart.paidAmount != null &&
              cart.paidAmount! < cart.totalAmount) ...[
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
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.debtRed),
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
    );
  }

  void _showEditPriceDialog(BuildContext context, WidgetRef ref, CartLine line) {
    final strings = ref.read(appStringsProvider);
    final ctrl = TextEditingController(text: '${line.unitPrice}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.sell_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${line.product.name} - ${strings.editPrice}',
                style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${strings.sellingPrice}: ${formatDAAmount(line.product.sellingPrice)}',
              style: const TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: strings.unitPriceLabel,
                suffixText: 'DA',
              ),
            ),
          ],
        ),
        actions: [
          if (line.hasCustomPrice)
            TextButton(
              onPressed: () {
                ref.read(newSaleProvider.notifier).setUnitPrice(line.product.id, null);
                Navigator.of(ctx).pop();
              },
              child: Text(strings.cancel),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 0) {
                ref.read(newSaleProvider.notifier).setUnitPrice(line.product.id, val);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
  }
}

class _NewSaleCheckoutBar extends ConsumerWidget {
  const _NewSaleCheckoutBar({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(newSaleProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final debtAmount = cart.paidAmount != null
        ? (cart.totalAmount - cart.paidAmount!).clamp(0, cart.totalAmount)
        : 0;

    return SafeArea(
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
                    if (cart.paidAmount != null &&
                        cart.paidAmount! < cart.totalAmount)
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
                onPressed: cart.submitting ? null : onConfirm,
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

/// Thin wrapper so each tile watches only its own cart qty via a fine-grained
/// selector, preventing the entire product list from rebuilding on every add.
class _SaleProductTileWrapper extends ConsumerWidget {
  const _SaleProductTileWrapper({
    super.key,
    required this.product,
    required this.isLight,
    required this.strings,
    required this.onAdd,
  });

  final Product product;
  final bool isLight;
  final AppStrings strings;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCartQty = ref.watch(
      newSaleProvider.select((s) {
        final line = s.lines.where((l) => l.product.id == product.id);
        return line.isEmpty ? 0 : line.first.quantity;
      }),
    );
    return SaleProductTile(
      product: product,
      inCartQty: inCartQty,
      isLight: isLight,
      strings: strings,
      onAdd: onAdd,
    );
  }
}
