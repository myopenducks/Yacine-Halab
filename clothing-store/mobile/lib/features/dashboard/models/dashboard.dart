enum DashboardPeriod {
  today,
  week,
  month,
  custom;

  String get apiValue => name;

  String get label {
    switch (this) {
      case DashboardPeriod.today:
        return 'Today';
      case DashboardPeriod.week:
        return 'Week';
      case DashboardPeriod.month:
        return 'Month';
      case DashboardPeriod.custom:
        return 'Custom';
    }
  }
}

class CategoryQuantity {
  CategoryQuantity({
    required this.categoryId,
    required this.name,
    required this.quantity,
  });

  factory CategoryQuantity.fromJson(Map<String, dynamic> json) {
    return CategoryQuantity(
      categoryId: (json['categoryId'] as num).toInt(),
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  final int categoryId;
  final String name;
  final int quantity;
}

class DashboardSummary {
  DashboardSummary({
    required this.period,
    required this.from,
    required this.to,
    required this.salesCount,
    required this.itemsSold,
    required this.revenue,
    required this.profit,
    required this.lowStockCount,
    required this.categoryQuantities,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categoryQuantities'] as List<dynamic>? ?? const [];
    return DashboardSummary(
      period: json['period'] as String? ?? 'today',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      itemsSold: (json['itemsSold'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      profit: (json['profit'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      categoryQuantities: rawCats
          .map(
            (e) => CategoryQuantity.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  final String period;
  final String from;
  final String to;
  final int salesCount;
  final int itemsSold;
  final int revenue;
  final int profit;
  final int lowStockCount;
  final List<CategoryQuantity> categoryQuantities;
}

class SalesBucket {
  SalesBucket({
    required this.label,
    required this.revenue,
    required this.profit,
    required this.count,
  });

  factory SalesBucket.fromJson(Map<String, dynamic> json) {
    return SalesBucket(
      label: json['label']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      profit: (json['profit'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String label;
  final int revenue;
  final int profit;
  final int count;
}

class DashboardChart {
  DashboardChart({
    required this.period,
    required this.from,
    required this.to,
    required this.buckets,
  });

  factory DashboardChart.fromJson(Map<String, dynamic> json) {
    final raw = json['buckets'] as List<dynamic>? ?? const [];
    return DashboardChart(
      period: json['period'] as String? ?? 'today',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      buckets: raw
          .map(
            (e) => SalesBucket.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }

  final String period;
  final String from;
  final String to;
  final List<SalesBucket> buckets;

  int get maxRevenue {
    if (buckets.isEmpty) return 0;
    return buckets.map((b) => b.revenue).reduce((a, b) => a > b ? a : b);
  }
}
