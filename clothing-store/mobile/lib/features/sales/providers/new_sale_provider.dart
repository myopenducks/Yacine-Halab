import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/models.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';
import '../models/sale.dart';
import 'sales_history_provider.dart';

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  int get lineTotal => product.sellingPrice * quantity;
  int get maxQty => product.quantity;

  CartLine copyWith({Product? product, int? quantity}) {
    return CartLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class NewSaleState {
  const NewSaleState({
    this.lines = const [],
    this.submitting = false,
    this.error,
  });

  final List<CartLine> lines;
  final bool submitting;
  final String? error;

  bool get isEmpty => lines.isEmpty;
  int get distinctCount => lines.length;
  int get unitCount => lines.fold(0, (s, l) => s + l.quantity);
  int get totalAmount => lines.fold(0, (s, l) => s + l.lineTotal);

  NewSaleState copyWith({
    List<CartLine>? lines,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) {
    return NewSaleState(
      lines: lines ?? this.lines,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NewSaleNotifier extends Notifier<NewSaleState> {
  @override
  NewSaleState build() => const NewSaleState();

  /// Returns null on success path message; returns error string if blocked.
  String? addProduct(Product product) {
    if (product.quantity <= 0) {
      return '“${product.name}” is out of stock';
    }

    final idx = state.lines.indexWhere((l) => l.product.id == product.id);
    if (idx >= 0) {
      final current = state.lines[idx];
      if (current.quantity >= product.quantity) {
        return 'Only ${product.quantity} in stock for “${product.name}”';
      }
      final next = [...state.lines];
      next[idx] = current.copyWith(
        product: product,
        quantity: current.quantity + 1,
      );
      state = state.copyWith(lines: next, clearError: true);
      return null;
    }

    state = state.copyWith(
      lines: [
        ...state.lines,
        CartLine(product: product, quantity: 1),
      ],
      clearError: true,
    );
    return null;
  }

  void setQuantity(int productId, int quantity) {
    final idx = state.lines.indexWhere((l) => l.product.id == productId);
    if (idx < 0) return;
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final line = state.lines[idx];
    final capped = quantity > line.maxQty ? line.maxQty : quantity;
    final next = [...state.lines];
    next[idx] = line.copyWith(quantity: capped);
    state = state.copyWith(lines: next, clearError: true);
  }

  void increment(int productId) {
    final idx = state.lines.indexWhere((l) => l.product.id == productId);
    if (idx < 0) return;
    final line = state.lines[idx];
    if (line.quantity >= line.maxQty) {
      state = state.copyWith(
        error: 'Only ${line.maxQty} in stock for “${line.product.name}”',
      );
      return;
    }
    setQuantity(productId, line.quantity + 1);
  }

  void decrement(int productId) {
    final idx = state.lines.indexWhere((l) => l.product.id == productId);
    if (idx < 0) return;
    setQuantity(productId, state.lines[idx].quantity - 1);
  }

  void remove(int productId) {
    state = state.copyWith(
      lines: state.lines.where((l) => l.product.id != productId).toList(),
      clearError: true,
    );
  }

  void clear() {
    state = const NewSaleState();
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<SaleDetail?> submit() async {
    if (state.lines.isEmpty) {
      state = state.copyWith(error: 'Add at least one product');
      return null;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final sale = await ref.read(saleServiceProvider).create(
            items: state.lines
                .map((l) => (productId: l.product.id, quantity: l.quantity))
                .toList(growable: false),
          );
      state = const NewSaleState();
      ref.read(productsListProvider.notifier).refresh();
      ref.read(salesListProvider.notifier).refresh();
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(dashboardChartProvider);
      return sale;
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        error: _messageOf(e),
      );
      return null;
    }
  }

  String _messageOf(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).error.message;
    }
    if (e is ApiException) return e.error.message;
    if (e is NetworkException) return e.message;
    return 'Sale failed';
  }
}

final newSaleProvider = NotifierProvider<NewSaleNotifier, NewSaleState>(
  NewSaleNotifier.new,
);
