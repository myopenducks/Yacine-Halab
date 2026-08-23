import '../../../core/network/dio_client.dart';
import '../models/product.dart';

class ProductService {
  ProductService(this._dio);

  final DioClient _dio;

  Future<PaginatedProducts> list({
    required int page,
    required int limit,
    String? search,
    int? categoryId,
    bool? lowStock,
  }) async {
    final Map<String, dynamic> query = {
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (categoryId != null) {
      query['categoryId'] = '$categoryId';
    }
    if (lowStock != null) {
      query['lowStock'] = lowStock ? 'true' : 'false';
    }
    return _dio.get<PaginatedProducts>(
      '/api/v1/products',
      queryParameters: query,
      dataFromJson: PaginatedProducts.fromJson,
    );
  }

  Future<Product> getById(int id) {
    return _dio.get<Product>(
      '/api/v1/products/$id',
      dataFromJson: Product.fromJson,
    );
  }

  Future<Product> create({
    required String name,
    required int categoryId,
    required int purchasePrice,
    required int sellingPrice,
    required int quantity,
    String? imageUrl,
  }) {
    final Map<String, dynamic> body = {
      'name': name,
      'categoryId': categoryId,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
    };
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      body['imageUrl'] = imageUrl.trim();
    }
    return _dio.post<Product>(
      '/api/v1/products',
      body: body,
      dataFromJson: Product.fromJson,
    );
  }

  Future<Product> update({
    required int id,
    String? name,
    int? categoryId,
    int? purchasePrice,
    int? sellingPrice,
    int? quantity,
    Object? imageUrl = _sentinel,
  }) {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (categoryId != null) body['categoryId'] = categoryId;
    if (purchasePrice != null) body['purchasePrice'] = purchasePrice;
    if (sellingPrice != null) body['sellingPrice'] = sellingPrice;
    if (quantity != null) body['quantity'] = quantity;
    if (!identical(imageUrl, _sentinel)) {
      if (imageUrl is String && imageUrl.trim().isNotEmpty) {
        body['imageUrl'] = imageUrl.trim();
      } else {
        body['imageUrl'] = null;
      }
    }
    return _dio.patch<Product>(
      '/api/v1/products/$id',
      body: body,
      dataFromJson: Product.fromJson,
    );
  }

  Future<void> delete(int id) {
    return _dio.deleteVoid('/api/v1/products/$id');
  }
}

const Object _sentinel = Object();
