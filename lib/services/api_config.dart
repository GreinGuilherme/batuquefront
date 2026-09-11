class ApiConfig {
  /// URL base configurável para a API REST
  /// Padrão: http://10.0.2.2:8080 (Emulador Android) ou http://localhost:8080
  static String baseUrl = 'http://10.0.2.2:8080';

  /// Timeout padrão para requisições HTTP
  static Duration timeout = const Duration(seconds: 4);

  /// Alternar fallback automático para dados mock em desenvolvimento/local
  static bool enableMockFallback = true;
}
