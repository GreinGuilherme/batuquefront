class ApiConfig {
  /// URL base configurável para a API REST
  /// - Celular Físico (via Cabo USB + adb reverse) ou Desktop/Web: http://localhost:8080
  /// - Emulador Android (AVD): http://10.0.2.2:8080
  /// - Celular Físico (Wi-Fi): http://SEU_IP_LOCAL:8080 (ex: http://192.168.1.15:8080)
  static String baseUrl = 'http://localhost:8080';

  /// Timeout padrão para requisições HTTP
  static Duration timeout = const Duration(seconds: 10);

  /// Alternar fallback automático para dados mock.
  /// Definido como `false` para usar exclusivamente o backend Java e o Banco de Dados.
  static bool enableMockFallback = false;
}
