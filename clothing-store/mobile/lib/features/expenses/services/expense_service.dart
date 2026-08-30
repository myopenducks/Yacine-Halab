import '../../../core/network/dio_client.dart';
import '../models/expense.dart';

class ExpenseService {
  ExpenseService(this._dio);

  final DioClient _dio;

  Future<List<Expense>> list({
    String? category,
    String? search,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': '$page',
      'limit': '$limit',
    };
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();

    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/expenses',
      queryParameters: query,
      dataFromJson: (json) => json,
    );

    // Backend wraps in ok() → DioClient unwraps 'data', so res IS {items, total, ...}
    final rawItems = res['items'] as List<dynamic>? ?? [];
    return rawItems
        .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ExpenseSummary> summary({DateTime? from, DateTime? to}) async {
    final query = <String, dynamic>{};
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();

    return _dio.get<ExpenseSummary>(
      '/api/v1/expenses/summary',
      queryParameters: query,
      dataFromJson: ExpenseSummary.fromJson,
    );
  }

  Future<Expense> create({
    required String title,
    String? recipientName,
    required String category,
    required int amount,
    String? notes,
    DateTime? expenseDate,
  }) async {
    return _dio.post<Expense>(
      '/api/v1/expenses',
      body: {
        'title': title,
        if (recipientName != null && recipientName.trim().isNotEmpty)
          'recipientName': recipientName.trim(),
        'category': category,
        'amount': amount,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (expenseDate != null)
          'expenseDate': expenseDate.toUtc().toIso8601String(),
      },
      dataFromJson: Expense.fromJson,
    );
  }

  Future<Expense> update(
    int id, {
    String? title,
    String? recipientName,
    String? category,
    int? amount,
    String? notes,
    DateTime? expenseDate,
  }) async {
    return _dio.patch<Expense>(
      '/api/v1/expenses/$id',
      body: {
        if (title != null) 'title': title,
        if (recipientName != null)
          'recipientName':
              recipientName.trim().isEmpty ? null : recipientName.trim(),
        if (category != null) 'category': category,
        if (amount != null) 'amount': amount,
        if (notes != null)
          'notes': notes.trim().isEmpty ? null : notes.trim(),
        if (expenseDate != null)
          'expenseDate': expenseDate.toUtc().toIso8601String(),
      },
      dataFromJson: Expense.fromJson,
    );
  }

  Future<void> delete(int id) async {
    await _dio.deleteVoid('/api/v1/expenses/$id');
  }
}
