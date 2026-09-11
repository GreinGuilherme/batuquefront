import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/ponto_cantado.dart';
import '../models/ponto_item.dart';
import '../services/playlist_service.dart';

class PlaylistsProvider extends ChangeNotifier {
  final PlaylistService _service;

  PlaylistsProvider({PlaylistService? service}) : _service = service ?? PlaylistService();

  List<Playlist> _playlists = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _termoBusca = '';

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get termoBusca => _termoBusca;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> carregarPlaylists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_termoBusca.isNotEmpty) {
        _playlists = await _service.filtrarPlaylists(_termoBusca);
      } else {
        _playlists = await _service.buscarPlaylists();
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar playlists: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filtrarPlaylists(String termo) async {
    _termoBusca = termo;
    await carregarPlaylists();
  }

  Future<bool> cadastrarPlaylist(Playlist playlist) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nova = await _service.cadastrarPlaylist(playlist);
      _playlists.add(nova);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar playlist: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarPlaylist(int id, Playlist playlist) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizada = await _service.atualizarPlaylist(id, playlist);
      final index = _playlists.indexWhere((p) => p.id == id);
      if (index != -1) {
        _playlists[index] = atualizada;
      } else {
        _playlists.add(atualizada);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar playlist: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletarPlaylist(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deletarPlaylist(id);
      _playlists.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao deletar playlist: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reordenação local dos PontoItem em uma playlist
  void reordenarPontosLocais(int playlistId, int oldIndex, int newIndex) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    final pontos = List<PontoItem>.from(playlist.pontos);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex < 0 || oldIndex >= pontos.length || newIndex < 0 || newIndex >= pontos.length) {
      return;
    }

    final item = pontos.removeAt(oldIndex);
    pontos.insert(newIndex, item);

    // Reatualiza a ordem sequencial dos pontos (1, 2, 3...)
    final pontosReordenados = List<PontoItem>.generate(
      pontos.length,
      (i) => pontos[i].copyWith(ordem: i + 1),
    );

    _playlists[index] = playlist.copyWith(pontos: pontosReordenados);
    notifyListeners();
  }

  /// Adiciona um ponto cantado à playlist especificada
  void adicionarPontoAPlaylist(int playlistId, PontoCantado ponto) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    final pontos = List<PontoItem>.from(playlist.pontos);

    final novoItem = PontoItem(
      ordem: pontos.length + 1,
      ponto: ponto,
    );
    pontos.add(novoItem);

    _playlists[index] = playlist.copyWith(pontos: pontos);
    notifyListeners();
  }

  /// Remove um ponto da playlist pelo index do item
  void removerPontoDaPlaylist(int playlistId, int pontoIndex) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    final pontos = List<PontoItem>.from(playlist.pontos);

    if (pontoIndex < 0 || pontoIndex >= pontos.length) return;

    pontos.removeAt(pontoIndex);

    // Reatualiza ordens
    final pontosAtualizados = List<PontoItem>.generate(
      pontos.length,
      (i) => pontos[i].copyWith(ordem: i + 1),
    );

    _playlists[index] = playlist.copyWith(pontos: pontosAtualizados);
    notifyListeners();
  }

  /// Salva as alterações da playlist (incluindo reordenação/adições) no backend/service
  Future<bool> salvarPlaylist(int playlistId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return false;

    final playlist = _playlists[index];
    return await atualizarPlaylist(playlistId, playlist);
  }
}
