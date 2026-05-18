class DesktopConfig {
  DesktopConfig._();

  static const defaultApiBaseUrl = 'http://127.0.0.1:8000';

  static String apiBaseUrlFromEnvironment() {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return defaultApiBaseUrl;
  }

  static String normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
