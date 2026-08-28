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
    this.expenses = 0,
    int? netRevenue,
    int? netProfit,
    required this.lowStockCount,
    this.unpaidDebtCount = 0,
    this.totalUnpaidDebtDA = 0,
    required this.categoryQuantities,
  })  : netRevenue = netRevenue ?? revenue,
        netProfit = netProfit ?? profit;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categoryQuantities'] as List<dynamic>? ?? const [];
    final revenue = (json['revenue'] as num?)?.toInt() ?? 0;
    final profit = (json['profit'] as num?)?.toInt() ?? 0;
    final expenses = (json['expenses'] as num?)?.toInt() ?? 0;

    return DashboardSummary(
      period: json['period'] as String? ?? 'today',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      itemsSold: (json['itemsSold'] as num?)?.toInt() ?? 0,
      revenue: revenue,
      profit: profit,
      expenses: expenses,
      netRevenue: (json['netRevenue'] as num?)?.toInt() ?? (revenue - expenses),
      netProfit: (json['netProfit'] as num?)?.toInt() ?? (profit - expenses),
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      unpaidDebtCount: (json['unpaidDebtCount'] as num?)?.toInt() ?? 0,
      totalUnpaidDebtDA: (json['totalUnpaidDebtDA'] as num?)?.toInt() ?? 0,
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
  final int expenses;
  final int netRevenue;
  final int netProfit;
  final int lowStockCount;
  final int unpaidDebtCount;
  final int totalUnpaidDebtDA;
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

class SoldItemDetail {
  SoldItemDetail({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.averagePrice,
  });

  factory SoldItemDetail.fromJson(Map<String, dynamic> json) {
    return SoldItemDetail(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? 'Product',
      categoryName: json['categoryName'] as String? ?? 'Other',
      quantitySold: (json['quantitySold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      averagePrice: (json['averagePrice'] as num?)?.toInt() ?? 0,
    );
  }

  final int productId;
  final String productName;
  final String categoryName;
  final int quantitySold;
  final int totalRevenue;
  final int averagePrice;
}
