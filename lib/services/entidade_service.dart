import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entidade.dart';
import 'api_config.dart';
import 'auth_service.dart';

class EntidadeService {
  final http.Client _client;
  final AuthService _authService;

  EntidadeService({http.Client? client, AuthService? authService})
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

  Future<List<Entidade>> buscarEntidades() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/buscar');
    final headers = await _authService.getAuthHeaders();

    final response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isEmpty) return [];
      final dynamic json = jsonDecode(decodedBody);
      if (json is List) {
        return json.map((e) => Entidade.fromJson(e as Map<String, dynamic>)).toList();
      } else if (json is Map<String, dynamic> && json['content'] is List) {
        return (json['content'] as List).map((e) => Entidade.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao buscar entidades (status: ${response.statusCode})');
  }

  Future<List<Entidade>> filtrarEntidades(String termo) async {
    final queryParams = <String, String>{};
    if (termo.isNotEmpty) {
      queryParams['nomeEntidade'] = termo;
      queryParams['falange'] = termo;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/buscar/filtrar')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final headers = await _authService.getAuthHeaders();

    final response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isEmpty) return [];
      final dynamic json = jsonDecode(decodedBody);
      if (json is List) {
        return json.map((e) => Entidade.fromJson(e as Map<String, dynamic>)).toList();
      } else if (json is Map<String, dynamic> && json['content'] is List) {
        return (json['content'] as List).map((e) => Entidade.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao filtrar entidades (status: ${response.statusCode})');
  }

  Future<Entidade> cadastrarEntidade(Entidade entidade) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/cadastrar');
    final headers = await _authService.getAuthHeaders();

    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode(entidade.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
      Entidade resultado = entidade;
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        try {
          final dynamic jsonResponse = jsonDecode(decodedBody);
          if (jsonResponse is Map<String, dynamic>) {
            var created = Entidade.fromJson(jsonResponse);
            if (created.nomeEntidade.isEmpty && entidade.nomeEntidade.isNotEmpty) {
              created = created.copyWith(nomeEntidade: entidade.nomeEntidade);
            }
            if (created.falange.isEmpty && entidade.falange.isNotEmpty) {
              created = created.copyWith(falange: entidade.falange);
            }
            if (created.linhaEntidade.isEmpty && entidade.linhaEntidade.isNotEmpty) {
              created = created.copyWith(linhaEntidade: entidade.linhaEntidade);
            }
            resultado = created;
          } else if (jsonResponse is num) {
            resultado = entidade.copyWith(id: jsonResponse.toInt());
          }
        } catch (_) {
          final intId = int.tryParse(decodedBody);
          if (intId != null) {
            resultado = entidade.copyWith(id: intId);
          }
        }
      }
      return resultado;
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao cadastrar entidade (status: ${response.statusCode})');
  }

  Future<Entidade> atualizarEntidade(int id, Entidade entidade) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/atualizar/$id');
    final headers = await _authService.getAuthHeaders();

    var response = await _client
        .patch(
          uri,
          headers: headers,
          body: jsonEncode(entidade.toJson()),
        )
        .timeout(ApiConfig.timeout);

    // Fallback para PUT se o backend não aceitar PATCH
    if (response.statusCode == 405 || response.statusCode == 404) {
      response = await _client
          .put(
            uri,
            headers: headers,
            body: jsonEncode(entidade.toJson()),
          )
          .timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
      Entidade resultado = entidade.copyWith(id: id);
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        try {
          final dynamic jsonResponse = jsonDecode(decodedBody);
          if (jsonResponse is Map<String, dynamic>) {
            var updated = Entidade.fromJson(jsonResponse);
            if (updated.nomeEntidade.isEmpty && entidade.nomeEntidade.isNotEmpty) {
              updated = updated.copyWith(nomeEntidade: entidade.nomeEntidade);
            }
            if (updated.falange.isEmpty && entidade.falange.isNotEmpty) {
              updated = updated.copyWith(falange: entidade.falange);
            }
            if (updated.linhaEntidade.isEmpty && entidade.linhaEntidade.isNotEmpty) {
              updated = updated.copyWith(linhaEntidade: entidade.linhaEntidade);
            }
            resultado = updated.id == null ? updated.copyWith(id: id) : updated;
          }
        } catch (_) {}
      }
      return resultado;
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao atualizar entidade (status: ${response.statusCode})');
  }

  Future<void> deletarEntidade(int entidadeId, {String? nomeEntidade}) async {
    final headers = await _authService.getAuthHeaders();

    // Prioriza o formato /entidade/deletar/{id} que é o padrão exigido
    Uri uri = Uri.parse('${ApiConfig.baseUrl}/entidade/deletar/$entidadeId');
    var response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);

    // Se 404/405, tenta com parâmetro de query (?id=...&nomeEntidade=...)
    if (response.statusCode == 404 || response.statusCode == 405) {
      final queryParams = <String, String>{
        'id': entidadeId.toString(),
      };
      if (nomeEntidade != null && nomeEntidade.isNotEmpty) {
        queryParams['nomeEntidade'] = nomeEntidade;
      }
      uri = Uri.parse('${ApiConfig.baseUrl}/entidade/deletar').replace(queryParameters: queryParams);
      response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    // Se ainda 404/405, tenta REST padrão (/entidade/{id})
    if (response.statusCode == 404 || response.statusCode == 405) {
      uri = Uri.parse('${ApiConfig.baseUrl}/entidade/$entidadeId');
      response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    // Se ainda 404/405, tenta com JSON Body no DELETE
    if (response.statusCode == 404 || response.statusCode == 405) {
      uri = Uri.parse('${ApiConfig.baseUrl}/entidade/deletar');
      response = await _client.delete(
        uri,
        headers: headers,
        body: jsonEncode({
          'id': entidadeId,
          if (nomeEntidade != null && nomeEntidade.isNotEmpty) 'nomeEntidade': nomeEntidade,
        }),
      ).timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Acesso negado (${response.statusCode}): Você precisa estar autenticado como Administrador para deletar entidades.');
    }

    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao deletar entidade (status: ${response.statusCode})');
  }
}
