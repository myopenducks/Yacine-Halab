import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';
import '../utils/env.dart';
import 'models.dart';

class DioClient {
  DioClient({
    required SecureStorageService secureStorage,
    @visibleForTesting Dio? dio,
    String? overrideBaseUrl,
  })  : _secureStorage = secureStorage,
        _dio = dio ?? _buildDio(overrideBaseUrl) {
    _installInterceptors();
  }

  final Dio _dio;
  final SecureStorageService _secureStorage;
  String? _cachedToken;

  Dio get raw => _dio;

  static Dio _buildDio(String? overrideBaseUrl) {
    final d = Dio();
    d.options
      ..baseUrl = overrideBaseUrl ??
          AppEnv.resolveApiBaseUrlForHost(
            kIsWeb ? 'web' : defaultTargetPlatform.name,
          )
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
    if (kDebugMode && AppEnv.debugAllowBadCert) {
      // (opt-in) for self-signed certs via --dart-define=DEBUG_ALLOW_BAD_CERT=true
    }
    return d;
  }

  void _installInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tok = _cachedToken ?? await _secureStorage.readToken();
          if (tok != null && tok.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $tok';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          final res = e.response;
          if (res?.data is Map<String, dynamic>) {
            final map = res!.data as Map<String, dynamic>;
            final err = map['error'];
            if (err is Map<String, dynamic>) {
              final apiErr = ApiError.fromJson(err);
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  response: res,
                  error: ApiException(apiErr, res.statusCode),
                ),
              );
            }
          }
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: NetworkException(e.message ?? 'No connection'),
              ),
            );
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _secureStorage.writeToken(token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.deleteToken();
  }

  Future<String?> loadStoredToken() async {
    final tok = await _secureStorage.readToken();
    _cachedToken = tok;
    return tok;
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) dataFromJson,
    Map<String, dynamic>? Function(Map<String, dynamic> raw)? unwrap,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    final raw = res.data!;
    if (unwrap != null) {
      final unwrapped = unwrap(raw);
      if (unwrapped == null) return dataFromJson({});
      return dataFromJson(unwrapped);
    }
    return unwrapEnvelope<T>(raw, dataFromJson);
  }

  Future<List<T>> getList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) itemFromJson,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    final raw = res.data!;
    final err = raw['error'] as Map<String, dynamic>?;
    if (err != null) throw ApiException(ApiError.fromJson(err));
    final data = raw['data'];
    if (data is! List) return <T>[];
    return data
        .map((e) => itemFromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) dataFromJson,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      path,
      data: body,
      queryParameters: queryParameters,
    );
    return unwrapEnvelope<T>(res.data!, dataFromJson);
  }

  Future<T> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) dataFromJson,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      path,
      data: body,
      queryParameters: queryParameters,
    );
    return unwrapEnvelope<T>(res.data!, dataFromJson);
  }

  Future<void> deleteVoid(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _dio.delete<void>(
      path,
      data: body,
      queryParameters: queryParameters,
    );
  }
}
