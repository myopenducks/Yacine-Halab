class SaleItemDetail {
  SaleItemDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.purchasePrice,
    required this.lineTotal,
  });

  factory SaleItemDetail.fromJson(Map<String, dynamic> json) {
    return SaleItemDetail(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toInt(),
      purchasePrice: (json['purchasePrice'] as num).toInt(),
      lineTotal: (json['lineTotal'] as num).toInt(),
    );
  }

  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int purchasePrice;
  final int lineTotal;
}

class SaleDetail {
  SaleDetail({
    required this.id,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.createdAt,
    required this.items,
  });

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    final Object? createdAt = json['createdAt'];
    DateTime? parsed;
    if (createdAt is String) {
      parsed = DateTime.tryParse(createdAt);
    } else if (createdAt is DateTime) {
      parsed = createdAt;
    }
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return SaleDetail(
      id: (json['id'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toInt(),
      paidAmount: (json['paidAmount'] as num).toInt(),
      remainingAmount: (json['remainingAmount'] as num?)?.toInt() ?? 0,
      createdAt: parsed ?? DateTime.now(),
      items: rawItems
          .map(
            (e) => SaleItemDetail.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }

  final int id;
  final int totalAmount;
  final int paidAmount;
  final int remainingAmount;
  final DateTime createdAt;
  final List<SaleItemDetail> items;

  int get itemCount => items.fold<int>(0, (sum, i) => sum + i.quantity);
}

class SaleHeader {
  SaleHeader({
    required this.id,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.itemCount,
    required this.createdAt,
  });

  factory SaleHeader.fromJson(Map<String, dynamic> json) {
    final Object? createdAt = json['createdAt'];
    DateTime? parsed;
    if (createdAt is String) {
      parsed = DateTime.tryParse(createdAt);
    } else if (createdAt is DateTime) {
      parsed = createdAt;
    }
    return SaleHeader(
      id: (json['id'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toInt(),
      paidAmount: (json['paidAmount'] as num).toInt(),
      remainingAmount: (json['remainingAmount'] as num?)?.toInt() ?? 0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      createdAt: parsed ?? DateTime.now(),
    );
  }

  final int id;
  final int totalAmount;
  final int paidAmount;
  final int remainingAmount;
  final int itemCount;
  final DateTime createdAt;
}

class PaginatedSales {
  PaginatedSales({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PaginatedSales.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return PaginatedSales(
      items: rawItems
          .map((e) => SaleHeader.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }

  final List<SaleHeader> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
  bool get isEmpty => items.isEmpty;
}
