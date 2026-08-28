import '../../../core/network/dio_client.dart';
import '../models/dashboard.dart';

class DashboardQuery {
  const DashboardQuery({
    required this.period,
    this.month,
    this.year,
  });

  final DashboardPeriod period;
  final int? month;
  final int? year;

  Map<String, dynamic> toParams() {
    final params = <String, dynamic>{'period': period.apiValue};
    if (period == DashboardPeriod.custom && month != null && year != null) {
      params['month'] = '$month';
      params['year'] = '$year';
    }
    return params;
  }
}

class DashboardService {
  DashboardService(this._dio);

  final DioClient _dio;

  Future<DashboardSummary> getSummary(DashboardQuery query) {
    return _dio.get<DashboardSummary>(
      '/api/v1/dashboard/summary',
      queryParameters: query.toParams(),
      dataFromJson: DashboardSummary.fromJson,
    );
  }

  Future<DashboardChart> getSalesChart(DashboardQuery query) {
    return _dio.get<DashboardChart>(
      '/api/v1/dashboard/sales',
      queryParameters: query.toParams(),
      dataFromJson: DashboardChart.fromJson,
    );
  }

  Future<List<SoldItemDetail>> getSoldItems(DashboardQuery query) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/dashboard/sold-items',
      queryParameters: query.toParams(),
      dataFromJson: (json) => json,
    );
    final rawList = res['items'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => SoldItemDetail.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
