class AppEnv {
  AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://yacine-halab-production.up.railway.app',
  );

  static const bool debugAllowBadCert = bool.fromEnvironment(
    'DEBUG_ALLOW_BAD_CERT',
    defaultValue: false,
  );

  static String resolveApiBaseUrlForHost(String host) {
    return apiBaseUrl;
  }
}
