import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';
import 'api_config.dart';
import 'auth_service.dart';

class PlaylistService {
  final http.Client _client;
  final AuthService _authService;

  PlaylistService({http.Client? client, AuthService? authService})
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

  Future<List<Playlist>> buscarPlaylists() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/buscar');
    final headers = await _authService.getAuthHeaders();

    final response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isEmpty) return [];
      final dynamic json = jsonDecode(decodedBody);
      if (json is List) {
        return json.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
      } else if (json is Map<String, dynamic> && json['content'] is List) {
        return (json['content'] as List).map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao buscar playlists (status: ${response.statusCode})');
  }

  Future<List<Playlist>> filtrarPlaylists(String termo) async {
    final queryParams = <String, String>{};
    if (termo.isNotEmpty) {
      queryParams['playlistNome'] = termo;
      queryParams['nomePonto'] = termo;
      queryParams['pontoLetra'] = termo;
      queryParams['nomeEntidade'] = termo;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/buscar/filtrar')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final headers = await _authService.getAuthHeaders();

    final response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isEmpty) return [];
      final dynamic json = jsonDecode(decodedBody);
      if (json is List) {
        return json.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
      } else if (json is Map<String, dynamic> && json['content'] is List) {
        return (json['content'] as List).map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao filtrar playlists (status: ${response.statusCode})');
  }

  Future<Playlist> cadastrarPlaylist(Playlist playlist) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/cadastrar');
    final headers = await _authService.getAuthHeaders();

    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode(playlist.toUpdateJson()),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        try {
          final dynamic jsonResponse = jsonDecode(decodedBody);
          if (jsonResponse is Map<String, dynamic>) {
            var created = Playlist.fromJson(jsonResponse);
            if (created.nomePlaylist.isEmpty && playlist.nomePlaylist.isNotEmpty) {
              created = created.copyWith(nomePlaylist: playlist.nomePlaylist);
            }
            if (created.pontos.isEmpty && playlist.pontos.isNotEmpty) {
              created = created.copyWith(pontos: playlist.pontos);
            }
            return created;
          } else if (jsonResponse is num) {
            return playlist.copyWith(id: jsonResponse.toInt());
          }
        } catch (_) {
          final intId = int.tryParse(decodedBody);
          if (intId != null) {
            return playlist.copyWith(id: intId);
          }
        }
      }
      return playlist;
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao cadastrar playlist (status: ${response.statusCode})');
  }

  Future<Playlist> atualizarPlaylist(int id, Playlist playlist) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/atualizar/$id');
    final headers = await _authService.getAuthHeaders();

    var response = await _client
        .put(
          uri,
          headers: headers,
          body: jsonEncode(playlist.toUpdateJson()),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 405 || response.statusCode == 404) {
      response = await _client
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(playlist.toUpdateJson()),
          )
          .timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
      final decodedBody = utf8.decode(response.bodyBytes).trim();
      if (decodedBody.isNotEmpty) {
        try {
          final dynamic jsonResponse = jsonDecode(decodedBody);
          if (jsonResponse is Map<String, dynamic>) {
            var updated = Playlist.fromJson(jsonResponse);
            if (updated.nomePlaylist.isEmpty && playlist.nomePlaylist.isNotEmpty) {
              updated = updated.copyWith(nomePlaylist: playlist.nomePlaylist);
            }
            if (updated.pontos.isEmpty && playlist.pontos.isNotEmpty) {
              updated = updated.copyWith(pontos: playlist.pontos);
            }
            return updated.id == null ? updated.copyWith(id: id) : updated;
          }
        } catch (_) {}
      }
      return playlist.copyWith(id: id);
    }
    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao atualizar playlist (status: ${response.statusCode})');
  }

  Future<void> deletarPlaylist(int id, {String? nomePlaylist}) async {
    final headers = await _authService.getAuthHeaders();

    final queryParams = <String, String>{
      'id': id.toString(),
    };
    if (nomePlaylist != null && nomePlaylist.isNotEmpty) {
      queryParams['nomePlaylist'] = nomePlaylist;
    }

    Uri uri = Uri.parse('${ApiConfig.baseUrl}/playlist/deletar')
        .replace(queryParameters: queryParams);
    var response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);

    if (response.statusCode == 404 || response.statusCode == 405) {
      uri = Uri.parse('${ApiConfig.baseUrl}/playlist/deletar/$id');
      response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 404 || response.statusCode == 405) {
      uri = Uri.parse('${ApiConfig.baseUrl}/playlist/$id');
      response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }

    if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Acesso negado (${response.statusCode}): Você precisa estar autenticado para deletar playlists.');
    }

    final msg = _extrairMensagemErro(response);
    throw Exception(msg ?? 'Erro ao deletar playlist (status: ${response.statusCode})');
  }
}
