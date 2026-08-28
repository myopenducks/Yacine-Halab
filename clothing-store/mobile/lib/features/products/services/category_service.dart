import '../../../core/network/dio_client.dart';
import '../models/product.dart';

class CategoryService {
  CategoryService(this._dio);

  final DioClient _dio;

  Future<List<Category>> list() {
    return _dio.getList<Category>(
      '/api/v1/categories',
      itemFromJson: Category.fromJson,
    );
  }

  Future<Category> create(String name) {
    return _dio.post<Category>(
      '/api/v1/categories',
      body: {'name': name.trim()},
      dataFromJson: Category.fromJson,
    );
  }

  Future<Map<String, dynamic>> delete(int id) {
    return _dio.delete<Map<String, dynamic>>(
      '/api/v1/categories/$id',
      dataFromJson: (data) => data,
    );
  }
}
