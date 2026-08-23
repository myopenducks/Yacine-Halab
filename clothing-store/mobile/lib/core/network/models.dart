class AppUser {
  AppUser({required this.id, required this.username});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
    );
  }

  final int id;
  final String username;

  Map<String, dynamic> toJson() => {'id': id, 'username': username};
}

class AuthLoginResult {
  AuthLoginResult({required this.token, required this.user});

  factory AuthLoginResult.fromJson(Map<String, dynamic> json) {
    return AuthLoginResult(
      token: json['token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String token;
  final AppUser user;
}

class ApiError {
  ApiError({
    required this.code,
    required this.statusCode,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 500,
      message: json['message'] as String? ?? 'An error occurred',
      details: json['details'],
    );
  }

  final String code;
  final int statusCode;
  final String message;
  final Object? details;

  @override
  String toString() => 'ApiError($code): $message';
}

class ApiException implements Exception {
  ApiException(this.error, [this.statusCode]);

  final ApiError error;
  final int? statusCode;

  @override
  String toString() => error.toString();
}

class NetworkException implements Exception {
  NetworkException(this.message);

  final String message;

  @override
  String toString() => 'Network error: $message';
}

T unwrapEnvelope<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) dataFromJson,
) {
  final err = json['error'] as Map<String, dynamic>?;
  if (err != null) throw ApiException(ApiError.fromJson(err));
  final data = json['data'];
  if (data == null) return dataFromJson({});
  if (T == Null || T == void_) {
    // ignore: avoid_dynamic_calls
    return null as T;
  }
  if (data is Map<String, dynamic>) return dataFromJson(data);
  // For list-returning endpoints or non-object data; callers can use data directly.
  return data as T;
}

Type get void_ => Null;
