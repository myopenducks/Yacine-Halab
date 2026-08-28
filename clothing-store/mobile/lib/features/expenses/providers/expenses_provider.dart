import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ExpenseService(dio);
});

class ExpenseFilters {
  const ExpenseFilters({
    this.category,
    this.search,
    this.from,
    this.to,
  });

  final String? category;
  final String? search;
  final DateTime? from;
  final DateTime? to;

  ExpenseFilters copyWith({
    String? category,
    String? search,
    DateTime? from,
    DateTime? to,
    bool clearCategory = false,
    bool clearSearch = false,
    bool clearDates = false,
  }) {
    return ExpenseFilters(
      category: clearCategory ? null : (category ?? this.category),
      search: clearSearch ? null : (search ?? this.search),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
    );
  }
}

final expenseFiltersProvider = StateProvider<ExpenseFilters>((ref) {
  return const ExpenseFilters();
});

final expensesListProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final filters = ref.watch(expenseFiltersProvider);
  final service = ref.watch(expenseServiceProvider);
  return service.list(
    category: filters.category,
    search: filters.search,
    from: filters.from,
    to: filters.to,
  );
});

final expenseSummaryProvider = FutureProvider.autoDispose<ExpenseSummary>((ref) async {
  final filters = ref.watch(expenseFiltersProvider);
  final service = ref.watch(expenseServiceProvider);
  return service.summary(
    from: filters.from,
    to: filters.to,
  );
});
