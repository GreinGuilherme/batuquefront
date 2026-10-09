import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_config.dart'; // Importando seu arquivo de configuração
import '../../services/auth_service.dart';

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
        onError: (DioException e, handler) async {
          // Tratamento global de erros
          if (e.response?.statusCode == 403) {
            debugPrint('Erro 403: Bloqueio do Nginx ou Falta de Permissão.');
          } else if (e.response?.statusCode == 401) {
            debugPrint('Erro 401: Token expirado. Tentando Refresh Token...');
            
            // Impede requests infinitos em loop (caso o refresh dê 401)
            if (e.requestOptions.path.contains('/auth/refresh')) {
              return handler.next(e);
            }

            final authService = AuthService();
            bool success = await authService.refreshTokenSilently();

            if (success) {
              debugPrint('Refresh Token realizado com sucesso. Refazendo a requisição original...');
              try {
                // Pega o novo token salvo
                final prefs = await SharedPreferences.getInstance();
                final newToken = prefs.getString('jwt_token');

                // Clona a requisição original que falhou com erro 401
                final options = e.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';
                
                // Realiza a requisição original de novo
                final cloneReq = await _dio.fetch(options);
                return handler.resolve(cloneReq);
              } catch (cloneError) {
                return handler.next(e);
              }
            } else {
              debugPrint('Falha ao tentar renovar o token. O usuário será deslogado.');
              // Aqui idealmente deveríamos chamar o AuthProvider para atualizar o estado da tela,
              // mas para não criar uma dependência circular, apenas limpamos o cache local.
              await authService.logout();
            }
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
