import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/models.dart';
import '../../core/network/providers.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final DioClient _dio;

  Future<AuthLoginResult> login({
    required String username,
    required String password,
  }) {
    return _dio.post<AuthLoginResult>(
      '/api/v1/auth/login',
      body: {'username': username, 'password': password},
      dataFromJson: (d) => AuthLoginResult.fromJson(d),
    );
  }

  Future<AuthLoginResult> loginGuest() async {
    try {
      return await _dio.post<AuthLoginResult>(
        '/api/v1/auth/guest',
        body: {},
        dataFromJson: (d) => AuthLoginResult.fromJson(d),
      );
    } catch (_) {
      return await _dio.post<AuthLoginResult>(
        '/api/v1/auth/login',
        body: {'username': 'guest', 'password': 'guestPassword123'},
        dataFromJson: (d) => AuthLoginResult.fromJson(d),
      );
    }
  }

  Future<AppUser> me() {
    return _dio.get<AppUser>(
      '/api/v1/auth/me',
      dataFromJson: (d) => AppUser.fromJson(d),
    );
  }

  Future<void> logoutLocally() => _dio.clearToken();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioClientProvider));
});
