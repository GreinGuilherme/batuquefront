import 'package:flutter/foundation.dart';
import '../models/entidade.dart';
import '../services/entidade_service.dart';

class EntidadesProvider extends ChangeNotifier {
  final EntidadeService _service;

  EntidadesProvider({EntidadeService? service}) : _service = service ?? EntidadeService();

  List<Entidade> _entidades = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _termoBusca = '';

  List<Entidade> get entidades => List.unmodifiable(_entidades);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get termoBusca => _termoBusca;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> carregarEntidades() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_termoBusca.isNotEmpty) {
        _entidades = await _service.filtrarEntidades(_termoBusca);
      } else {
        _entidades = await _service.buscarEntidades();
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar entidades: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filtrarEntidades(String termo) async {
    _termoBusca = termo;
    await carregarEntidades();
  }

  Future<bool> cadastrarEntidade(Entidade entidade) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final novaEntidade = await _service.cadastrarEntidade(entidade);
      _entidades.add(novaEntidade);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar entidade: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarEntidade(int id, Entidade entidade) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizada = await _service.atualizarEntidade(id, entidade);
      final index = _entidades.indexWhere((e) => e.id == id);
      if (index != -1) {
        _entidades[index] = atualizada;
      } else {
        _entidades.add(atualizada);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar entidade: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletarEntidade(int id, {String? nomeEntidade}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deletarEntidade(id, nomeEntidade: nomeEntidade);
      _entidades.removeWhere((e) => e.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao deletar entidade: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
