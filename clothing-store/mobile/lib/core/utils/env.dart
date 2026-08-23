class AppEnv {
  AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const bool debugAllowBadCert = bool.fromEnvironment(
    'DEBUG_ALLOW_BAD_CERT',
    defaultValue: false,
  );

  static String resolveApiBaseUrlForHost(String host) {
    if (apiBaseUrl != 'http://10.0.2.2:3000') return apiBaseUrl;
    if (host == 'windows' ||
        host == 'web' ||
        host == 'chrome' ||
        host == 'edge') {
      return 'http://127.0.0.1:3000';
    }
    return apiBaseUrl;
  }
}
