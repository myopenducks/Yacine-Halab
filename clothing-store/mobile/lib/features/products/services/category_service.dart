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
}
