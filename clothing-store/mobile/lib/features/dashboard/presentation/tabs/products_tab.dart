import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/providers/app_refresh.dart';
import '../../../products/models/product.dart';
import '../../../products/presentation/widgets/category_dropdown_selector.dart';
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
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

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

  void _toggleSelectionMode(int? initialProductId) {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIds.clear();
      } else if (initialProductId != null) {
        _selectedIds.add(initialProductId);
      }
    });
  }

  void _toggleSelection(int productId) {
    setState(() {
      if (_selectedIds.contains(productId)) {
        _selectedIds.remove(productId);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(productId);
      }
    });
  }

  Future<void> _showCategoryPicker(List<Category> categories) async {
    final strings = ref.read(appStringsProvider);
    final selectedId = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(strings.changeCategory),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  title: Text(cat.name),
                  onTap: () => Navigator.pop(ctx, cat.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(strings.cancel),
            ),
          ],
        );
      },
    );

    if (selectedId != null && mounted) {
       try {
         await ref.read(productServiceProvider).bulkUpdateCategory(
           productIds: _selectedIds.toList(),
           categoryId: selectedId,
         );
         if (mounted) {
           _toggleSelectionMode(null);
           refreshAfterInventoryChange(ref);
           showAppSnackBar(
             context,
             strings.isFrench
                 ? 'Produits mis à jour avec succès'
                 : 'Products updated successfully',
             kind: AppSnackKind.success,
           );
         }
       } catch (e) {
         if (mounted) {
           showAppSnackBar(
             context,
             strings.isFrench
                 ? 'Échec de la mise à jour des produits'
                 : 'Failed to update products',
             kind: AppSnackKind.error,
           );
         }
       }
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final strings = ref.read(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final ctrl = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isLight ? AppColors.white : AppColors.cardDark,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      strings.addCategory,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: strings.categoryName,
                  hintText: strings.isFrench ? 'ex: Chemises' : 'ex: Shirts',
                  filled: true,
                  fillColor: isLight ? AppColors.gray100 : AppColors.gray900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
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
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                        child: Text(strings.confirm, style: const TextStyle(fontWeight: FontWeight.w700)),
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

    if (created != null && created.isNotEmpty && mounted) {
      try {
        await ref.read(categoryServiceProvider).create(created);
        ref.invalidate(categoriesProvider);
        refreshAfterInventoryChange(ref);
        if (mounted) {
          showAppSnackBar(context, strings.categoryCreated, kind: AppSnackKind.success);
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(context, 'Erreur lors de la création de la catégorie', kind: AppSnackKind.error);
        }
      }
    }
  }

  Future<void> _showManageCategoriesSheet(List<Category> categories) async {
    final strings = ref.read(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isLight ? AppColors.white : AppColors.cardDark,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 520),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          strings.manageCategories,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final c = categories[idx];
                      final isFallback = c.name.toLowerCase() == 'autre' || c.name.toLowerCase() == 'other';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isLight ? AppColors.gray100 : AppColors.gray800),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder_outlined, size: 20),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: isFallback
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (cctx) => Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      backgroundColor: isLight ? AppColors.white : AppColors.cardDark,
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(strings.deleteCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 10),
                                            Text(strings.deleteCategoryConfirm, textAlign: TextAlign.center),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () => Navigator.pop(cctx, false),
                                                    child: Text(strings.cancel),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: FilledButton(
                                                    style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                                                    onPressed: () => Navigator.pop(cctx, true),
                                                    child: Text(strings.delete),
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
                                      await ref.read(categoryServiceProvider).delete(c.id);
                                      ref.invalidate(categoriesProvider);
                                      refreshAfterInventoryChange(ref);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        showAppSnackBar(context, strings.categoryDeleted, kind: AppSnackKind.success);
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        showAppSnackBar(context, 'Erreur lors de la suppression', kind: AppSnackKind.error);
                                      }
                                    }
                                  }
                                },
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final filters = ref.watch(productFiltersProvider);
    final list = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final strings = ref.watch(appStringsProvider);

    final selectionTitle = strings.isFrench
        ? '${_selectedIds.length} sélectionné(s)'
        : '${_selectedIds.length} selected';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _selectionMode ? selectionTitle : strings.products,
          style: theme.textTheme.headlineSmall,
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _toggleSelectionMode(null),
            )
          else if (list.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isLight ? AppColors.gray200 : AppColors.gray800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${list.total}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isLight ? AppColors.gray700 : AppColors.gray300,
                      fontWeight: FontWeight.bold,
                    ),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: categoriesAsync.when(
              loading: () => const SizedBox(
                height: 44,
                child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (cats) {
                return Row(
                  children: [
                    // Smooth Category Dropdown Selector
                    Expanded(
                      child: CategoryDropdownSelector(
                        categories: cats,
                        selectedCategoryId: filters.categoryId,
                        allCategoriesLabel: strings.allCategories,
                        addCategoryLabel: strings.addCategory,
                        manageCategoriesLabel: strings.manageCategories,
                        isLight: isLight,
                        onSelectCategory: (catId) {
                          ref.read(productFiltersProvider.notifier).setCategoryId(catId);
                        },
                        onAddCategory: _showCreateCategoryDialog,
                        onManageCategories: () => _showManageCategoriesSheet(cats),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Low stock chip
                    _FilterChip(
                      label: strings.lowStock,
                      selected: filters.lowStockOnly,
                      icon: Icons.warning_amber_rounded,
                      onTap: () => ref.read(productFiltersProvider.notifier).toggleLowStockOnly(),
                    ),
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
          if (_selectionMode && _selectedIds.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.category_outlined),
                    label: Text(strings.changeCategory),
                    onPressed: () {
                      final cats = ref.read(categoriesProvider).valueOrNull;
                      if (cats != null) {
                        _showCategoryPicker(cats);
                      } else {
                        showAppSnackBar(
                          context,
                          strings.isFrench
                              ? 'Catégories non chargées'
                              : 'Categories not loaded',
                          kind: AppSnackKind.error,
                        );
                      }
                    },
                  ),
                ),
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
          Center(
            child: AppLoading(size: 64),
          ),
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
          isSelected: _selectionMode ? _selectedIds.contains(product.id) : null,
          onLongPress: () {
            if (!_selectionMode) _toggleSelectionMode(product.id);
          },
          onTap: () {
            if (_selectionMode) {
              _toggleSelection(product.id);
            } else {
              _openForm(productId: product.id);
            }
          },
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
