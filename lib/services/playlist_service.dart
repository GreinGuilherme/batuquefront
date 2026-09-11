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
            body: jsonEncode(playlist.toJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Playlist.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
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
            body: jsonEncode(playlist.toJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        return Playlist.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
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

  Future<void> deletarPlaylist(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/playlist/deletar/$id');
    try {
      final response = await _client.delete(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    _mockPlaylists.removeWhere((p) => p.id == id);
  }
}
