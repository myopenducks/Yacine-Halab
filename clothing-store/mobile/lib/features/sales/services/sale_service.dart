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
    bool? debtOnly,
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
    if (debtOnly == true) {
      query['hasDebt'] = 'true';
      query['debtOnly'] = 'true';
    }
    return _dio.get<PaginatedSales>(
      '/api/v1/sales',
      queryParameters: query,
      dataFromJson: PaginatedSales.fromJson,
    );
  }

  Future<SaleDetail> create({
    required List<({int productId, int quantity, int? unitPrice})> items,
    String? customerName,
    String? notes,
    int? paidAmount,
  }) {
    return _dio.post<SaleDetail>(
      '/api/v1/sales',
      body: {
        'items': items
            .map((i) => {
                  'productId': i.productId,
                  'quantity': i.quantity,
                  if (i.unitPrice != null) 'unitPrice': i.unitPrice,
                })
            .toList(growable: false),
        if (customerName != null && customerName.trim().isNotEmpty)
          'customerName': customerName.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (paidAmount != null) 'paidAmount': paidAmount,
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

  /// Delete a sale and restore inventory stock.
  Future<void> deleteSale(int saleId) {
    return _dio.deleteVoid('/api/v1/sales/$saleId');
  }

  /// Record a partial or full payment for a debt sale.
  Future<SaleDetail> recordPayment(int saleId, int amount, {String? note}) {
    return _dio.post<SaleDetail>(
      '/api/v1/sales/$saleId/payments',
      body: {
        'amount': amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      dataFromJson: SaleDetail.fromJson,
    );
  }

  /// Update customer name or notes of a sale.
  Future<SaleDetail> updateSale(
    int saleId, {
    String? customerName,
    String? notes,
  }) {
    return _dio.patch<SaleDetail>(
      '/api/v1/sales/$saleId',
      body: {
        'customerName': customerName,
        'notes': notes,
      },
      dataFromJson: SaleDetail.fromJson,
    );
  }
}
