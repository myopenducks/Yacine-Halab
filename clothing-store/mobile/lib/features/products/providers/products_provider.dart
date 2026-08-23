import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/models.dart';
import '../../../core/network/providers.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(ref.watch(dioClientProvider));
});

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(dioClientProvider));
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoryServiceProvider).list();
});

class ProductFilters {
  const ProductFilters({
    this.search = '',
    this.categoryId,
    this.lowStockOnly = false,
  });

  final String search;
  final int? categoryId;
  final bool lowStockOnly;

  ProductFilters copyWith({
    String? search,
    int? categoryId,
    bool clearCategory = false,
    bool? lowStockOnly,
  }) {
    return ProductFilters(
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductFilters &&
        other.search == search &&
        other.categoryId == categoryId &&
        other.lowStockOnly == lowStockOnly;
  }

  @override
  int get hashCode => Object.hash(search, categoryId, lowStockOnly);
}

class ProductFiltersNotifier extends Notifier<ProductFilters> {
  Timer? _debounce;

  @override
  ProductFilters build() {
    ref.onDispose(() => _debounce?.cancel());
    return const ProductFilters();
  }

  /// Instant UI update for the search field, API query debounced ≤100ms.
  void setSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (state.search == value) return;
      state = state.copyWith(search: value);
    });
  }

  void setCategoryId(int? id) {
    if (id == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryId: id);
    }
  }

  void toggleLowStockOnly() {
    state = state.copyWith(lowStockOnly: !state.lowStockOnly);
  }

  void setLowStockOnly(bool value) {
    if (state.lowStockOnly == value) return;
    state = state.copyWith(lowStockOnly: value);
  }

  void clear() {
    _debounce?.cancel();
    state = const ProductFilters();
  }
}

final productFiltersProvider =
    NotifierProvider<ProductFiltersNotifier, ProductFilters>(
  ProductFiltersNotifier.new,
);

class ProductsListState {
  const ProductsListState({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.error,
  });

  factory ProductsListState.initial() => const ProductsListState(
        items: [],
        total: 0,
        page: 0,
        hasMore: true,
        isLoading: true,
        isLoadingMore: false,
      );

  final List<Product> items;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  ProductsListState copyWith({
    List<Product>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return ProductsListState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProductsListNotifier extends Notifier<ProductsListState> {
  static const int _pageSize = 20;

  @override
  ProductsListState build() {
    ref.listen<ProductFilters>(productFiltersProvider, (prev, next) {
      if (prev == next) return;
      unawaited(refresh());
    });
    Future.microtask(refresh);
    return ProductsListState.initial();
  }

  ProductService get _service => ref.read(productServiceProvider);
  ProductFilters get _filters => ref.read(productFiltersProvider);

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      final page = await _fetchPage(1);
      state = ProductsListState(
        items: page.items,
        total: page.total,
        page: page.page,
        hasMore: page.hasMore,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _messageOf(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _fetchPage(state.page + 1);
      state = ProductsListState(
        items: [...state.items, ...page.items],
        total: page.total,
        page: page.page,
        hasMore: page.hasMore,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: _messageOf(e),
      );
    }
  }

  Future<PaginatedProducts> _fetchPage(int page) {
    final f = _filters;
    return _service.list(
      page: page,
      limit: _pageSize,
      search: f.search,
      categoryId: f.categoryId,
      lowStock: f.lowStockOnly ? true : null,
    );
  }

  String _messageOf(Object e) {
    if (e is ApiException) return e.error.message;
    if (e is NetworkException) return e.message;
    return 'Something went wrong';
  }
}

final productsListProvider =
    NotifierProvider<ProductsListNotifier, ProductsListState>(
  ProductsListNotifier.new,
);

final productByIdProvider =
    FutureProvider.autoDispose.family<Product, int>((ref, id) {
  return ref.watch(productServiceProvider).getById(id);
});
