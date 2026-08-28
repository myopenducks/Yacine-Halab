class Expense {
  const Expense({
    required this.id,
    required this.title,
    this.recipientName,
    required this.category,
    required this.amount,
    this.notes,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? recipientName;
  final String category;
  final int amount;
  final String? notes;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      title: json['title'] as String,
      recipientName: json['recipientName'] as String?,
      category: (json['category'] as String?) ?? 'other',
      amount: (json['amount'] as num).toInt(),
      notes: json['notes'] as String?,
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'recipientName': recipientName,
        'category': category,
        'amount': amount,
        'notes': notes,
        'expenseDate': expenseDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class ExpenseSummary {
  const ExpenseSummary({
    required this.totalExpensesDA,
    required this.count,
    required this.byCategory,
  });

  final int totalExpensesDA;
  final int count;
  final List<ExpenseCategoryBreakdown> byCategory;

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      totalExpensesDA: (json['totalExpensesDA'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      byCategory: ((json['byCategory'] as List<dynamic>?) ?? [])
          .map((e) => ExpenseCategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExpenseCategoryBreakdown {
  const ExpenseCategoryBreakdown({
    required this.category,
    required this.totalDA,
    required this.count,
  });

  final String category;
  final int totalDA;
  final int count;

  factory ExpenseCategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryBreakdown(
      category: (json['category'] as String?) ?? 'other',
      totalDA: (json['totalDA'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
