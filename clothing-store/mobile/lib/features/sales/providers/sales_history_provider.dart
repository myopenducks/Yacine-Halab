import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/models.dart';
import '../../../core/network/providers.dart';
import '../models/sale.dart';
import '../services/sale_service.dart';

final saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(ref.watch(dioClientProvider));
});

enum SalesDatePreset {
  all,
  today,
  week,
  month,
  custom,
}

class SalesFilters {
  const SalesFilters({
    this.preset = SalesDatePreset.all,
    this.customFrom,
    this.customTo,
    this.debtOnly = false,
  });

  final SalesDatePreset preset;
  final DateTime? customFrom;
  final DateTime? customTo;
  final bool debtOnly;

  ({DateTime? from, DateTime? to}) get range {
    final now = DateTime.now();
    switch (preset) {
      case SalesDatePreset.all:
        return (from: null, to: null);
      case SalesDatePreset.today:
        return (from: _startOfDay(now), to: _endOfDay(now));
      case SalesDatePreset.week:
        return (from: _startOfWeek(now), to: _endOfDay(now));
      case SalesDatePreset.month:
        return (from: _startOfMonth(now), to: _endOfDay(now));
      case SalesDatePreset.custom:
        if (customFrom == null && customTo == null) {
          return (from: null, to: null);
        }
        return (
          from: customFrom != null ? _startOfDay(customFrom!) : null,
          to: customTo != null ? _endOfDay(customTo!) : null,
        );
    }
  }

  String get label {
    switch (preset) {
      case SalesDatePreset.all:
        return 'All';
      case SalesDatePreset.today:
        return 'Today';
      case SalesDatePreset.week:
        return 'Week';
      case SalesDatePreset.month:
        return 'Month';
      case SalesDatePreset.custom:
        return 'Range';
    }
  }

  SalesFilters copyWith({
    SalesDatePreset? preset,
    DateTime? customFrom,
    DateTime? customTo,
    bool clearCustom = false,
    bool? debtOnly,
  }) {
    return SalesFilters(
      preset: preset ?? this.preset,
      customFrom: clearCustom ? null : (customFrom ?? this.customFrom),
      customTo: clearCustom ? null : (customTo ?? this.customTo),
      debtOnly: debtOnly ?? this.debtOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SalesFilters &&
        other.preset == preset &&
        other.debtOnly == debtOnly &&
        _sameDay(other.customFrom, customFrom) &&
        _sameDay(other.customTo, customTo);
  }

  @override
  int get hashCode => Object.hash(preset, customFrom, customTo, debtOnly);

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static DateTime _startOfWeek(DateTime d) {
    final day = d.weekday;
    return _startOfDay(d.subtract(Duration(days: day - 1)));
  }

  static DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
}

class SalesFiltersNotifier extends Notifier<SalesFilters> {
  @override
  SalesFilters build() => const SalesFilters();

  void setPreset(SalesDatePreset preset) {
    if (preset == SalesDatePreset.custom) {
      final now = DateTime.now();
      state = SalesFilters(
        preset: SalesDatePreset.custom,
        customFrom: now.subtract(const Duration(days: 7)),
        customTo: now,
      );
      return;
    }
    state = SalesFilters(preset: preset);
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = SalesFilters(
      preset: SalesDatePreset.custom,
      customFrom: from,
      customTo: to,
    );
  }

  void toggleDebtOnly() {
    state = state.copyWith(debtOnly: !state.debtOnly);
  }

  void clear() {
    state = const SalesFilters();
  }
}

final salesFiltersProvider =
    NotifierProvider<SalesFiltersNotifier, SalesFilters>(
  SalesFiltersNotifier.new,
);

class SalesListState {
  const SalesListState({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.error,
  });

  factory SalesListState.initial() => const SalesListState(
        items: [],
        total: 0,
        page: 0,
        hasMore: true,
        isLoading: true,
        isLoadingMore: false,
      );

  final List<SaleHeader> items;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  SalesListState copyWith({
    List<SaleHeader>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return SalesListState(
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

class SalesListNotifier extends Notifier<SalesListState> {
  static const int _pageSize = 20;

  @override
  SalesListState build() {
    ref.listen<SalesFilters>(salesFiltersProvider, (prev, next) {
      if (prev == next) return;
      unawaited(refresh());
    });
    Future.microtask(refresh);
    return SalesListState.initial();
  }

  SaleService get _service => ref.read(saleServiceProvider);
  SalesFilters get _filters => ref.read(salesFiltersProvider);

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      final page = await _fetchPage(1);
      state = SalesListState(
        items: page.items,
        total: page.total,
        page: page.page,
        hasMore: page.hasMore,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _messageOf(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _fetchPage(state.page + 1);
      state = SalesListState(
        items: [...state.items, ...page.items],
        total: page.total,
        page: page.page,
        hasMore: page.hasMore,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: _messageOf(e));
    }
  }

  Future<PaginatedSales> _fetchPage(int page) {
    final range = _filters.range;
    return _service.list(
      page: page,
      limit: _pageSize,
      from: range.from,
      to: range.to,
      debtOnly: _filters.debtOnly ? true : null,
    );
  }

  Future<bool> deleteSale(int id) async {
    try {
      await _service.deleteSale(id);
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: _messageOf(e));
      return false;
    }
  }

  Future<bool> clearHistory({bool restock = true}) async {
    try {
      await _service.clearHistory(restock: restock);
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: _messageOf(e));
      return false;
    }
  }

  String _messageOf(Object e) {
    if (e is ApiException) return e.error.message;
    if (e is NetworkException) return e.message;
    return 'Something went wrong';
  }
}

final salesListProvider = NotifierProvider<SalesListNotifier, SalesListState>(
  SalesListNotifier.new,
);

final saleByIdProvider =
    FutureProvider.autoDispose.family<SaleDetail, int>((ref, id) {
  return ref.watch(saleServiceProvider).getById(id);
});

void refreshSalesHistory(WidgetRef ref) {
  ref.read(salesListProvider.notifier).refresh();
}

/// Provider that fetches just one page to count how many debt sales exist.
/// Used to show a red badge on the History tab.
final debtBadgeCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.watch(saleServiceProvider);
  final page = await service.list(page: 1, limit: 1, debtOnly: true);
  return page.total;
});

