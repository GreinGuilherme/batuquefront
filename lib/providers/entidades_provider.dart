import 'package:flutter/foundation.dart';
import '../models/entidade.dart';
import '../services/entidade_service.dart';

class EntidadesProvider extends ChangeNotifier {
  final EntidadeService _service;

  EntidadesProvider({EntidadeService? service}) : _service = service ?? EntidadeService();

  List<Entidade> _todasEntidades = [];
  List<Entidade> _entidades = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _termoBusca = '';

  Set<String> _linhasFiltro = {};
  Set<String> _falangesFiltro = {};

  List<Entidade> get entidades => List.unmodifiable(_entidades);
  List<Entidade> get todasEntidades => List.unmodifiable(_todasEntidades.isNotEmpty ? _todasEntidades : _entidades);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get termoBusca => _termoBusca;

  Set<String> get linhasFiltro => Set.unmodifiable(_linhasFiltro);
  Set<String> get falangesFiltro => Set.unmodifiable(_falangesFiltro);
  bool get temFiltrosAtivos =>
      _termoBusca.isNotEmpty ||
      _linhasFiltro.isNotEmpty ||
      _falangesFiltro.isNotEmpty;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _aplicarFiltrosLocais(List<Entidade> base) {
    var resultado = base;

    if (_linhasFiltro.isNotEmpty) {
      resultado = resultado.where((e) => _linhasFiltro.contains(e.linhaEntidade)).toList();
    }

    if (_falangesFiltro.isNotEmpty) {
      resultado = resultado.where((e) => _falangesFiltro.contains(e.falange)).toList();
    }

    _entidades = resultado;
  }

  Future<void> carregarEntidades() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<Entidade> base;
      if (_termoBusca.isNotEmpty) {
        base = await _service.filtrarEntidades(_termoBusca);
      } else {
        base = await _service.buscarEntidades();
        _todasEntidades = List.from(base);
      }

      _aplicarFiltrosLocais(base);
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

  Future<void> aplicarFiltroCascata({
    String? termo,
    Set<String>? linhas,
    Set<String>? falanges,
  }) async {
    if (termo != null) _termoBusca = termo;
    _linhasFiltro = linhas != null ? Set.from(linhas) : {};
    _falangesFiltro = falanges != null ? Set.from(falanges) : {};
    await carregarEntidades();
  }

  Future<void> limparFiltros() async {
    _termoBusca = '';
    _linhasFiltro.clear();
    _falangesFiltro.clear();
    await carregarEntidades();
  }

  Future<bool> cadastrarEntidade(Entidade entidade) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final novaEntidade = await _service.cadastrarEntidade(entidade);
      _todasEntidades.add(novaEntidade);
      _aplicarFiltrosLocais(_todasEntidades);
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
      final index = _todasEntidades.indexWhere((e) => e.id == id);
      if (index != -1) {
        _todasEntidades[index] = atualizada;
      } else {
        _todasEntidades.add(atualizada);
      }
      _aplicarFiltrosLocais(_todasEntidades);
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
      _todasEntidades.removeWhere((e) => e.id == id);
      _aplicarFiltrosLocais(_todasEntidades);
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
