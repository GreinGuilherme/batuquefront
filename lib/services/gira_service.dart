import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/logging_http_client.dart';
import '../models/gira.dart';
import 'api_config.dart';
import 'auth_service.dart';

class GiraService {
  final http.Client _client;
  final AuthService _authService;

  GiraService({http.Client? client, AuthService? authService})
      : _client = client ?? LoggingHttpClient(),
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

  Future<List<Gira>> buscarGiras() async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/gira/buscar');
    final headers = await _authService.getAuthHeaders();

    var response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);

    // Se a rota /gira/buscar retornar 404, 405 ou 504 (Gateway Timeout), tenta rota REST /gira ou /gira/
    if (response.statusCode == 404 || response.statusCode == 405 || response.statusCode == 504) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gira');
      response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
    }
    if (response.statusCode == 404 || response.statusCode == 405 || response.statusCode == 504) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gira/');
      response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isEmpty) return [];
      final dynamic json = jsonDecode(decodedBody);
      if (json is List) {
        return json.map((e) => Gira.fromJson(e as Map<String, dynamic>)).toList();
      } else if (json is Map<String, dynamic> && json['content'] is List) {
        return (json['content'] as List).map((e) => Gira.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao buscar playlists de gira (status: ${response.statusCode})');
  }

  Future<List<Gira>> filtrarGiras(String termo) async {
    final todagiras = await buscarGiras();
    if (termo.trim().isEmpty) return todagiras;
    final query = termo.trim().toLowerCase();
    return todagiras.where((g) {
      final matchNome = g.nomeGira.toLowerCase().contains(query);
      final matchDesc = g.descricao != null && g.descricao!.toLowerCase().contains(query);
      return matchNome || matchDesc;
    }).toList();
  }

  Future<Gira> cadastrarGira(Gira gira) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/gira/cadastrar');
    final headers = await _authService.getAuthHeaders();

    var response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode(gira.toInsertJson()),
        )
        .timeout(ApiConfig.timeout);

    // Fallback para /gira/cadastar ou /gira
    if (response.statusCode == 404 || response.statusCode == 405 || response.statusCode == 504) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gira/cadastar');
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(gira.toInsertJson()),
          )
          .timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 404 || response.statusCode == 405 || response.statusCode == 504) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gira');
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(gira.toInsertJson()),
          )
          .timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        try {
          final dynamic jsonResponse = jsonDecode(decodedBody);
          if (jsonResponse is Map<String, dynamic>) {
            var created = Gira.fromJson(jsonResponse);
            if (created.nomeGira.isEmpty && gira.nomeGira.isNotEmpty) {
              created = created.copyWith(nomeGira: gira.nomeGira);
            }
            if (created.playlist.isEmpty && gira.playlist.isNotEmpty) {
              created = created.copyWith(playlist: gira.playlist);
            }
            return created;
          } else if (jsonResponse is num) {
            return gira.copyWith(id: jsonResponse.toInt());
          }
        } catch (_) {
          final intId = int.tryParse(decodedBody);
          if (intId != null) {
            return gira.copyWith(id: intId);
          }
        }
      }
      return gira;
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao cadastrar playlist de gira (status: ${response.statusCode})');
  }

  Future<Gira> atualizarGira(int id, Gira gira) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/gira/atualizar/$id');
    final headers = await _authService.getAuthHeaders();

    var response = await _client
        .put(
          uri,
          headers: headers,
          body: jsonEncode(gira.toUpdateJson()),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 405 || response.statusCode == 404 || response.statusCode == 504) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gira/$id');
      response = await _client
          .put(
            uri,
            headers: headers,
            body: jsonEncode(gira.toUpdateJson()),
          )
          .timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 405 || response.statusCode == 404 || response.statusCode == 504) {
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(gira.toUpdateJson()),
          )
          .timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        try {
          final dynamic jsonResponse = jsonDecode(decodedBody);
          if (jsonResponse is Map<String, dynamic>) {
            var updated = Gira.fromJson(jsonResponse);
            if (updated.nomeGira.isEmpty && gira.nomeGira.isNotEmpty) {
              updated = updated.copyWith(nomeGira: gira.nomeGira);
            }
            if (updated.playlist.isEmpty && gira.playlist.isNotEmpty) {
              updated = updated.copyWith(playlist: gira.playlist);
            }
            return updated.id == null ? updated.copyWith(id: id) : updated;
          }
        } catch (_) {}
      }
      return gira.copyWith(id: id);
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao atualizar playlist de gira (status: ${response.statusCode})');
  }

  Future<void> deletarGira(int id, {String? nomeGira}) async {
    final headers = await _authService.getAuthHeaders();

    final queryParams = <String, String>{
      'id': id.toString(),
    };
    if (nomeGira != null && nomeGira.isNotEmpty) {
      queryParams['nomeGira'] = nomeGira;
    }

    Uri uri = Uri.parse('${ApiConfig.baseUrl}/gira/deletar')
        .replace(queryParameters: queryParams);
    var response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);

    if (response.statusCode == 404 || response.statusCode == 405 || response.statusCode == 504) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gira/deletar/$id');
      response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 404 || response.statusCode == 405 || response.statusCode == 504) {
      uri = Uri.parse('${ApiConfig.baseUrl}/gira/$id');
      response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Acesso negado (${response.statusCode}): Você precisa estar autenticado para deletar playlists de gira.');
    }

    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao deletar playlist de gira (status: ${response.statusCode})');
  }
}
