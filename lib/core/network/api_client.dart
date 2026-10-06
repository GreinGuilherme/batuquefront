import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_config.dart'; // Importando seu arquivo de configuração

class ApiClient {
  late final Dio _dio;

  // Construtor privado para o padrão Singleton
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl, // Agora puxa dinamicamente do seu ApiConfig
        // Timeouts são boas práticas essenciais em mobile
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        // Aqui injetamos os headers estáticos obrigatórios do Nginx
        headers: {
          'x-app-batuque': 'GiraSegura2026',
          'User-Agent': 'BatuqueFlutterApp/1.0 (Android; iOS)',
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain',
        },
      ),
    );

    // Configurando Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          final cookie = prefs.getString('auth_cookie');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (cookie != null && cookie.isNotEmpty) {
            options.headers['Cookie'] = cookie;
          } else if (token != null && token.isNotEmpty) {
            options.headers['Cookie'] = 'jwt=$token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Processamento global de respostas de sucesso pode ser feito aqui
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Tratamento global de erros
          if (e.response?.statusCode == 403) {
            debugPrint('Erro 403: Bloqueio do Nginx ou Falta de Permissão.');
          } else if (e.response?.statusCode == 401) {
            debugPrint('Erro 401: Token expirado ou não autorizado.');
            // Lógica de logout ou refresh token entraria aqui
          }
          return handler.next(e);
        },
      ),
    );

    // Em ambiente de desenvolvimento, é muito útil logar as requisições
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  // Instância Singleton
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  // Expondo a instância do Dio para ser usada nos Repositórios
  Dio get dio => _dio;
}
