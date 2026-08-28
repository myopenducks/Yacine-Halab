import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../products/presentation/widgets/product_tile.dart';
import '../../../products/providers/products_provider.dart';

class ProductsTab extends ConsumerStatefulWidget {
  const ProductsTab({super.key});

  @override
  ConsumerState<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<ProductsTab> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(productsListProvider.notifier).loadMore();
    }
  }

  Future<void> _openForm({int? productId}) async {
    final path = productId == null
        ? AppRouteNames.productNewPath
        : AppRouteNames.productEditPath(productId);
    await context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final filters = ref.watch(productFiltersProvider);
    final list = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(strings.products, style: theme.textTheme.headlineSmall),
        actions: [
          if (list.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${list.total}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isLight ? AppColors.gray500 : AppColors.gray400,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) {
                      ref.read(productFiltersProvider.notifier).setSearch(v);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: strings.searchProducts,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: strings.cancel,
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(productFiltersProvider.notifier)
                                    .setSearch('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                      fillColor: isLight ? AppColors.white : AppColors.gray900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color:
                              isLight ? AppColors.gray200 : AppColors.gray800,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color:
                              isLight ? AppColors.gray200 : AppColors.gray800,
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
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: () => _openForm(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: categoriesAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (cats) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                      label: strings.all,
                      selected: filters.categoryId == null,
                      onTap: () => ref
                          .read(productFiltersProvider.notifier)
                          .setCategoryId(null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: strings.lowStock,
                      selected: filters.lowStockOnly,
                      icon: Icons.warning_amber_rounded,
                      onTap: () => ref
                          .read(productFiltersProvider.notifier)
                          .toggleLowStockOnly(),
                    ),
                    const SizedBox(width: 8),
                    ...cats.expand((c) sync* {
                      yield _FilterChip(
                        label: c.name,
                        selected: filters.categoryId == c.id,
                        onTap: () {
                          final notifier =
                              ref.read(productFiltersProvider.notifier);
                          if (filters.categoryId == c.id) {
                            notifier.setCategoryId(null);
                          } else {
                            notifier.setCategoryId(c.id);
                          }
                        },
                      );
                      yield const SizedBox(width: 8);
                    }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(productsListProvider.notifier).refresh(),
              child: _buildList(list, isLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ProductsListState list, bool isLight) {
    final strings = ref.watch(appStringsProvider);

    if (list.isLoading && list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (list.error != null && list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
        children: [
          AppEmptyState(
            icon: Icons.wifi_off_rounded,
            title: strings.noData,
            subtitle: list.error!,
            actionLabel: strings.cancel,
            onAction: () => ref.read(productsListProvider.notifier).refresh(),
          ),
        ],
      );
    }

    if (list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
        children: [
          AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: strings.noProductsFound,
            subtitle: strings.noData,
            actionLabel: strings.addProduct,
            onAction: () => _openForm(),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      itemCount: list.items.length + (list.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= list.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        }
        final product = list.items[index];
        return ProductTile(
          product: product,
          onTap: () => _openForm(productId: product.id),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isLight ? AppColors.black : AppColors.white)
                : (isLight ? AppColors.white : AppColors.gray900),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? (isLight ? AppColors.black : AppColors.white)
                  : (isLight ? AppColors.gray200 : AppColors.gray800),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? (isLight ? AppColors.white : AppColors.black)
                      : (isLight ? AppColors.gray600 : AppColors.gray400),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? (isLight ? AppColors.white : AppColors.black)
                      : (isLight ? AppColors.gray800 : AppColors.gray200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
