import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';

class UserRepository {
  // Pegamos a instância global configurada do Dio
  final Dio _dio = ApiClient.instance.dio;

  /// Exemplo de requisição GET utilizando o ApiClient base.
  /// Como a baseUrl está configurada, chamamos apenas o path final.
  /// A requisição irá para: https://batuque.duckdns.org/api/v1/users
  /// E enviará automaticamente todos os headers de segurança exigidos pelo Nginx.
  Future<List<dynamic>> fetchUsers() async {
    try {
      final response = await _dio.get('/api/v1/users');

      if (response.statusCode == 200) {
        // Supondo que a API retorne uma lista no body
        final List<dynamic> data = response.data;
        return data; 
      } else {
        throw Exception('Falha ao carregar usuários: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      // O tratamento de erro específico do Dio permite capturar falhas de rede, 
      // timeout ou respostas de erro do backend com muita facilidade.
      _handleError(e);
      rethrow; 
    }
  }

  void _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout) {
      debugPrint('Erro de Timeout: Verifique a conexão com a internet.');
    } else if (e.type == DioExceptionType.badResponse) {
      debugPrint('Erro na API: ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      debugPrint('Erro de Rede Genérico: ${e.message}');
    }
  }
}
