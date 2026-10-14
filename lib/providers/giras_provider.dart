import 'package:flutter/foundation.dart';
import '../models/gira.dart';
import '../models/playlist.dart';
import '../models/sync_event.dart';
import '../services/gira_service.dart';

class GirasProvider extends ChangeNotifier {
  final GiraService _service;

  GirasProvider({GiraService? service}) : _service = service ?? GiraService();

  List<Gira> _giras = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _termoBusca = '';

  List<Gira> get giras => List.unmodifiable(_giras);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get termoBusca => _termoBusca;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> carregarGiras() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_termoBusca.isNotEmpty) {
        _giras = await _service.filtrarGiras(_termoBusca);
      } else {
        _giras = await _service.buscarGiras();
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar giras: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filtrarGiras(String termo) async {
    _termoBusca = termo;
    await carregarGiras();
  }

  void sincronizar(SyncEvent event) {
    if (event.acao == "CREATE") {
      final gira = Gira.fromJson(event.dados as Map<String, dynamic>);
      final index = _giras.indexWhere((g) => g.id == gira.id);
      if (index == -1) {
        _giras.add(gira);
      }
    } else if (event.acao == "UPDATE") {
      final gira = Gira.fromJson(event.dados as Map<String, dynamic>);
      final index = _giras.indexWhere((g) => g.id == gira.id);
      if (index != -1) {
        _giras[index] = gira;
      } else {
        _giras.add(gira);
      }
    } else if (event.acao == "DELETE") {
      final id = event.idParaDeletar;
      if (id != null) {
        _giras.removeWhere((g) => g.id == id);
      }
    }
    notifyListeners();
  }

  Future<bool> cadastrarGira(Gira gira) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nova = await _service.cadastrarGira(gira);
      _giras.add(nova);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar gira: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarGira(int id, Gira gira) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizada = await _service.atualizarGira(id, gira);
      final index = _giras.indexWhere((g) => g.id == id);
      if (index != -1) {
        _giras[index] = atualizada;
      } else {
        _giras.add(atualizada);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar gira: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletarGira(int id, {String? nomeGira}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deletarGira(id, nomeGira: nomeGira);
      _giras.removeWhere((g) => g.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao deletar gira: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reordenarPlaylistsLocais(int giraId, int oldIndex, int newIndex) {
    final index = _giras.indexWhere((g) => g.id == giraId);
    if (index == -1) return;

    final gira = _giras[index];
    final items = List<GiraPlaylistItem>.from(gira.playlist);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex < 0 || oldIndex >= items.length || newIndex < 0 || newIndex >= items.length) {
      return;
    }

    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    final itemsReordenados = List<GiraPlaylistItem>.generate(
      items.length,
      (i) => items[i].copyWith(ordem: i + 1),
    );

    _giras[index] = gira.copyWith(playlist: itemsReordenados);
    notifyListeners();
  }

  void adicionarPlaylistAGira(int giraId, Playlist playlist) {
    if (playlist.id == null) return;
    final index = _giras.indexWhere((g) => g.id == giraId);
    if (index == -1) return;

    final gira = _giras[index];
    final items = List<GiraPlaylistItem>.from(gira.playlist);

    if (items.any((item) => item.playlistId == playlist.id)) return;

    final novoItem = GiraPlaylistItem(
      playlistId: playlist.id!,
      ordem: items.length + 1,
      playlist: playlist,
    );
    items.add(novoItem);

    _giras[index] = gira.copyWith(playlist: items);
    notifyListeners();
  }

  void removerPlaylistDaGira(int giraId, int playlistId) {
    final index = _giras.indexWhere((g) => g.id == giraId);
    if (index == -1) return;

    final gira = _giras[index];
    final items = List<GiraPlaylistItem>.from(gira.playlist);

    items.removeWhere((item) => item.playlistId == playlistId);

    final itemsAtualizados = List<GiraPlaylistItem>.generate(
      items.length,
      (i) => items[i].copyWith(ordem: i + 1),
    );

    _giras[index] = gira.copyWith(playlist: itemsAtualizados);
    notifyListeners();
  }

  Future<bool> salvarGira(int giraId) async {
    final index = _giras.indexWhere((g) => g.id == giraId);
    if (index == -1) return false;

    final gira = _giras[index];
    return await atualizarGira(giraId, gira);
  }
}
