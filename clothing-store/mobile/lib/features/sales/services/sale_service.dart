import '../../../core/network/dio_client.dart';
import '../models/sale.dart';

class SaleService {
  SaleService(this._dio);

  final DioClient _dio;

  Future<PaginatedSales> list({
    required int page,
    required int limit,
    DateTime? from,
    DateTime? to,
  }) async {
    final Map<String, dynamic> query = {
      'page': '$page',
      'limit': '$limit',
    };
    if (from != null) {
      query['from'] = from.toUtc().toIso8601String();
    }
    if (to != null) {
      query['to'] = to.toUtc().toIso8601String();
    }
    return _dio.get<PaginatedSales>(
      '/api/v1/sales',
      queryParameters: query,
      dataFromJson: PaginatedSales.fromJson,
    );
  }

  Future<SaleDetail> create({
    required List<({int productId, int quantity})> items,
  }) {
    return _dio.post<SaleDetail>(
      '/api/v1/sales',
      body: {
        'items': items
            .map((i) => {'productId': i.productId, 'quantity': i.quantity})
            .toList(growable: false),
      },
      dataFromJson: SaleDetail.fromJson,
    );
  }

  Future<SaleDetail> getById(int id) {
    return _dio.get<SaleDetail>(
      '/api/v1/sales/$id',
      dataFromJson: SaleDetail.fromJson,
    );
  }
}
