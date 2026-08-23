class Category {
  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final Object? createdAt = json['createdAt'];
    DateTime? parsed;
    if (createdAt is String) {
      parsed = DateTime.tryParse(createdAt);
    } else if (createdAt is DateTime) {
      parsed = createdAt;
    }
    return Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      categoryId: (json['categoryId'] as num).toInt(),
      categoryName: json['categoryName'] as String? ?? '',
      purchasePrice: (json['purchasePrice'] as num).toInt(),
      sellingPrice: (json['sellingPrice'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      createdAt: parsed ?? DateTime.now(),
    );
  }

  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final int purchasePrice;
  final int sellingPrice;
  final int quantity;
  final String? imageUrl;
  final DateTime createdAt;

  int get unitProfit => sellingPrice - purchasePrice;
  double get marginPc => sellingPrice == 0 ? 0 : unitProfit / sellingPrice;
  bool get isLowStock => quantity <= 5;
  bool get isOutOfStock => quantity <= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}

class PaginatedProducts {
  PaginatedProducts({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PaginatedProducts.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return PaginatedProducts(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }

  final List<Product> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
  bool get isEmpty => items.isEmpty;
}
