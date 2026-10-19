import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/ponto_cantado.dart';
import '../models/ponto_item.dart';
import '../models/sync_event.dart';
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

  /// Método para sincronizar com eventos do WebSocket/STOMP
  void sincronizar(SyncEvent event) {
    if (kDebugMode) {
      debugPrint('🔄 [PlaylistsProvider.sincronizar] Ação: "${event.acao}", Dados: ${event.dados}');
    }

    if (event.acao == "CREATE") {
      if (event.dados is Map<String, dynamic>) {
        final playlist = Playlist.fromJson(event.dados as Map<String, dynamic>);
        if (playlist.id == null) {
          debugPrint('⚠️ [PlaylistsProvider] ATENÇÃO: Playlist criada veio com ID NULL!');
        } else {
          debugPrint('✅ [PlaylistsProvider] Nova Playlist sincronizada: ID=${playlist.id}, Nome="${playlist.nomePlaylist}"');
        }
        final index = _playlists.indexWhere((p) => p.id == playlist.id);
        if (index == -1) {
          final idxSemId = _playlists.indexWhere((p) => p.id == null && p.nomePlaylist == playlist.nomePlaylist);
          if (idxSemId != -1) {
            _playlists[idxSemId] = playlist;
          } else {
            _playlists.add(playlist);
          }
        } else {
          _playlists[index] = playlist;
        }
      }
    } else if (event.acao == "UPDATE") {
      if (event.dados is Map<String, dynamic>) {
        final playlist = Playlist.fromJson(event.dados as Map<String, dynamic>);
        if (playlist.id == null) {
          debugPrint('⚠️ [PlaylistsProvider] ATENÇÃO: Playlist atualizada veio com ID NULL!');
        } else {
          debugPrint('✅ [PlaylistsProvider] Playlist atualizada sincronizada: ID=${playlist.id}, Nome="${playlist.nomePlaylist}"');
        }
        final index = _playlists.indexWhere((p) => p.id == playlist.id);
        if (index != -1) {
          _playlists[index] = playlist;
        } else {
          _playlists.add(playlist);
        }
      }
    } else if (event.acao == "DELETE") {
      final id = event.idParaDeletar;
      debugPrint('🗑️ [PlaylistsProvider] Playlist deletada sincronizada: ID=$id');
      if (id != null) {
        _playlists.removeWhere((p) => p.id == id);
      }
    }
    notifyListeners();
  }

  Future<bool> cadastrarPlaylist(Playlist playlist) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nova = await _service.cadastrarPlaylist(playlist);
      final index = _playlists.indexWhere((p) => p.id == nova.id);
      if (index != -1) {
        _playlists[index] = nova;
      } else {
        _playlists.add(nova);
      }

      // Re-busca do backend para garantir consistência total
      try {
        await carregarPlaylists();
      } catch (_) {}

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

  Future<bool> deletarPlaylist(int id, {String? nomePlaylist}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deletarPlaylist(id, nomePlaylist: nomePlaylist);
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

  /// Remove um PontoCantado por ID da playlist especificada
  void removerPontoCantadoDaPlaylist(int playlistId, int pontoId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    final pontos = List<PontoItem>.from(playlist.pontos);

    pontos.removeWhere((item) => item.ponto.id == pontoId);

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
