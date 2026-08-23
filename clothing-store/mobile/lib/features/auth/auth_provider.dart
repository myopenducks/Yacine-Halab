import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/models.dart';
import '../../core/network/providers.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  AuthState({
    required this.status,
    this.user,
    this.error,
  });

  factory AuthState.unknown() => AuthState(status: AuthStatus.unknown);

  final AuthStatus status;
  final AppUser? user;
  final String? error;

  bool get isLoggedIn => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState.unknown();
  }

  AuthRepository get _repo => ref.watch(authRepositoryProvider);
  DioClient get _dio => ref.watch(dioClientProvider);

  Future<void> bootstrap() async {
    final token = await _dio.loadStoredToken();
    if (token == null || token.isEmpty) {
      state = AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      await _repo.logoutLocally();
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(
      {required String username, required String password}) async {
    state = state.copyWith(clearError: true);
    try {
      final res =
          await _repo.login(username: username.trim(), password: password);
      await _dio.setToken(res.token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: res.user,
      );
      return true;
    } catch (e) {
      String msg = 'Login failed. Please check your credentials.';
      if (e is ApiException) {
        msg = e.error.message;
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: msg,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logoutLocally();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
