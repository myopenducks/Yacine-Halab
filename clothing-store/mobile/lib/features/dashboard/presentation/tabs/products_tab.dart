import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Products', style: theme.textTheme.headlineSmall),
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
                      hintText: 'Search inventory...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
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
                      label: 'All',
                      selected: filters.categoryId == null,
                      onTap: () => ref
                          .read(productFiltersProvider.notifier)
                          .setCategoryId(null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Low stock',
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
          PlaceholderNotice(
            icon: Icons.wifi_off_rounded,
            title: 'Could not load products',
            subtitle: list.error!,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(productsListProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
        children: [
          const PlaceholderNotice(
            icon: Icons.inventory_2_outlined,
            title: 'No products yet',
            subtitle: 'Tap + to add your first item to inventory.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _openForm(),
            child: const Text('Add product'),
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
    final brightness = Theme.of(context).brightness;
    final bg = selected
        ? AppColors.chipSelectedBg(brightness)
        : AppColors.chipUnselectedBg(brightness);
    final fg = selected
        ? AppColors.chipSelectedFg(brightness)
        : AppColors.chipUnselectedFg(brightness);
    final border = AppColors.chipBorder(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : border,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderNotice extends StatelessWidget {
  const PlaceholderNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.gray900,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight ? AppColors.gray200 : AppColors.gray800,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isLight ? AppColors.gray100 : AppColors.gray800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isLight ? AppColors.black : AppColors.white,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isLight ? AppColors.gray500 : AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}
