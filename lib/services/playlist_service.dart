import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';
import 'api_config.dart';
import 'mock_data.dart';

class PlaylistService {
  final http.Client _client;

  PlaylistService({http.Client? client}) : _client = client ?? http.Client();

  final List<Playlist> _mockPlaylists = List.from(MockData.playlists);
  int _nextMockId = 100;

  Future<List<Playlist>> buscarPlaylists() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/buscar');
    try {
      final response = await _client.get(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    return List.from(_mockPlaylists);
  }

  Future<List<Playlist>> filtrarPlaylists(String termo) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/playlist/buscar/filtro?termo=${Uri.encodeComponent(termo)}',
    );
    try {
      final response = await _client.get(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    if (termo.isEmpty) return List.from(_mockPlaylists);
    final termoLower = termo.toLowerCase();
    return _mockPlaylists.where((p) {
      return p.nomePlaylist.toLowerCase().contains(termoLower);
    }).toList();
  }

  Future<Playlist> cadastrarPlaylist(Playlist playlist) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/cadastrar');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(playlist.toUpdateJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
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
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    final novaPlaylist = playlist.copyWith(
      id: playlist.id ?? _nextMockId++,
      dataCriacao: playlist.dataCriacao ?? DateTime.now(),
    );
    _mockPlaylists.add(novaPlaylist);
    return novaPlaylist;
  }

  Future<Playlist> atualizarPlaylist(int id, Playlist playlist) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/atualizar/$id');
    try {
      final response = await _client
          .put(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(playlist.toUpdateJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
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
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    final index = _mockPlaylists.indexWhere((p) => p.id == id);
    final playlistAtualizada = playlist.copyWith(id: id);
    if (index != -1) {
      _mockPlaylists[index] = playlistAtualizada;
    } else {
      _mockPlaylists.add(playlistAtualizada);
    }
    return playlistAtualizada;
  }

  Future<void> deletarPlaylist(int id, {String? nomePlaylist}) async {
    final queryParams = <String, String>{
      'id': id.toString(),
    };
    if (nomePlaylist != null && nomePlaylist.isNotEmpty) {
      queryParams['nomePlaylist'] = nomePlaylist;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/deletar')
        .replace(queryParameters: queryParams);
    try {
      final response = await _client.delete(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    _mockPlaylists.removeWhere((p) => p.id == id);
  }
}
