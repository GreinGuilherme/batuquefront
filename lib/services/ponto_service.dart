import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ponto_cantado.dart';
import 'api_config.dart';
import 'auth_service.dart';

class PontoService {
  final http.Client _client;
  final AuthService _authService;

  PontoService({http.Client? client, AuthService? authService})
      : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  String? _extrairMensagemErro(http.Response response) {
    try {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        final decoded = jsonDecode(decodedBody);
        if (decoded is Map<String, dynamic>) {
          return decoded['message'] ?? decoded['error'] ?? decoded['mensagem'] ?? decoded['erro'] ?? decoded['detail'];
        }
        return decodedBody;
      }
    } catch (_) {}
    return null;
  }

  Future<List<PontoCantado>> buscarPontos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/buscar');
    final headers = await _authService.getAuthHeaders();

    final response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isEmpty) return [];
      final dynamic json = jsonDecode(decodedBody);
      if (json is List) {
        return json.map((e) => PontoCantado.fromJson(e as Map<String, dynamic>)).toList();
      } else if (json is Map<String, dynamic> && json['content'] is List) {
        return (json['content'] as List).map((e) => PontoCantado.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao buscar pontos (status: ${response.statusCode})');
  }

  Future<List<PontoCantado>> filtrarPontos({String? termo, int? entidadeId}) async {
    final queryParams = <String, String>{};
    if (termo != null && termo.isNotEmpty) {
      queryParams['termo'] = termo;
    }
    if (entidadeId != null) {
      queryParams['entidadeId'] = entidadeId.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/buscar/filtrar')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final headers = await _authService.getAuthHeaders();

    final response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isEmpty) return [];
      final dynamic json = jsonDecode(decodedBody);
      if (json is List) {
        return json.map((e) => PontoCantado.fromJson(e as Map<String, dynamic>)).toList();
      } else if (json is Map<String, dynamic> && json['content'] is List) {
        return (json['content'] as List).map((e) => PontoCantado.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao filtrar pontos (status: ${response.statusCode})');
  }

  Future<PontoCantado> cadastrarPonto(PontoCantado ponto) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/cadastrar');
    final headers = await _authService.getAuthHeaders();

    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode(ponto.toJson()),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
      PontoCantado resultado = ponto;
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        try {
          final dynamic jsonResponse = jsonDecode(decodedBody);
          if (jsonResponse is Map<String, dynamic>) {
            resultado = PontoCantado.fromJson(jsonResponse);
          } else if (jsonResponse is num) {
            resultado = ponto.copyWith(id: jsonResponse.toInt());
          }
        } catch (_) {
          final intId = int.tryParse(decodedBody);
          if (intId != null) {
            resultado = ponto.copyWith(id: intId);
          }
        }
      }
      return resultado;
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao cadastrar ponto (status: ${response.statusCode})');
  }

  Future<PontoCantado> atualizarPonto(int id, PontoCantado ponto) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/atualizar/$id');
    final headers = await _authService.getAuthHeaders();

    var response = await _client
        .patch(
          uri,
          headers: headers,
          body: jsonEncode(ponto.toJson()),
        )
        .timeout(ApiConfig.timeout);

    // Fallback para PUT se o backend retornar 405 (Method Not Allowed) ou 404
    if (response.statusCode == 405 || response.statusCode == 404) {
      response = await _client
          .put(
            uri,
            headers: headers,
            body: jsonEncode(ponto.toJson()),
          )
          .timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
      PontoCantado resultado = ponto.copyWith(id: id);
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        try {
          final dynamic jsonResponse = jsonDecode(decodedBody);
          if (jsonResponse is Map<String, dynamic>) {
            var updated = PontoCantado.fromJson(jsonResponse);
            if (updated.nomePonto.isEmpty && ponto.nomePonto.isNotEmpty) {
              updated = updated.copyWith(nomePonto: ponto.nomePonto);
            }
            if (updated.pontoLetra.isEmpty && ponto.pontoLetra.isNotEmpty) {
              updated = updated.copyWith(pontoLetra: ponto.pontoLetra);
            }
            resultado = updated.id == null ? updated.copyWith(id: id) : updated;
          }
        } catch (_) {}
      }
      return resultado;
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao atualizar ponto (status: ${response.statusCode})');
  }

  Future<void> deletarPonto(int id, {String? nomePonto, String? nomeEntidade}) async {
    final headers = await _authService.getAuthHeaders();

    final queryParams = <String, String>{
      'id': id.toString(),
    };
    if (nomePonto != null && nomePonto.isNotEmpty) {
      queryParams['nomePonto'] = nomePonto;
    }
    if (nomeEntidade != null && nomeEntidade.isNotEmpty) {
      queryParams['nomeEntidade'] = nomeEntidade;
    }

    Uri uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/deletar')
        .replace(queryParameters: queryParams);
    var response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);

    if (response.statusCode == 404 || response.statusCode == 405) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/deletar/$id');
      response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 404 || response.statusCode == 405) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/$id');
      response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Acesso negado (${response.statusCode}): Você precisa estar autenticado para deletar pontos.');
    }

    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao deletar ponto (status: ${response.statusCode})');
  }
}
