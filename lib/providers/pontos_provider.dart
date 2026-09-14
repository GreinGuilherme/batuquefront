import 'package:flutter/foundation.dart';
import '../models/ponto_cantado.dart';
import '../models/entidade.dart';
import '../services/ponto_service.dart';

class PontosProvider extends ChangeNotifier {
  final PontoService _service;

  PontosProvider({PontoService? service}) : _service = service ?? PontoService();

  List<PontoCantado> _pontos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _termoFiltro;
  int? _entidadeIdFiltro;

  Set<String> _linhasFiltro = {};
  Set<String> _falangesFiltro = {};
  Set<int> _entidadesFiltro = {};

  List<PontoCantado> get pontos => List.unmodifiable(_pontos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get termoFiltro => _termoFiltro;
  int? get entidadeIdFiltro => _entidadeIdFiltro;

  Set<String> get linhasFiltro => Set.unmodifiable(_linhasFiltro);
  Set<String> get falangesFiltro => Set.unmodifiable(_falangesFiltro);
  Set<int> get entidadesFiltro => Set.unmodifiable(_entidadesFiltro);
  bool get temFiltrosAtivos =>
      (_termoFiltro != null && _termoFiltro!.isNotEmpty) ||
      _entidadeIdFiltro != null ||
      _linhasFiltro.isNotEmpty ||
      _falangesFiltro.isNotEmpty ||
      _entidadesFiltro.isNotEmpty;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> carregarPontos({List<Entidade>? listaEntidades}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if ((_termoFiltro != null && _termoFiltro!.isNotEmpty) || _entidadeIdFiltro != null) {
        _pontos = await _service.filtrarPontos(
          termo: _termoFiltro,
          entidadeId: _entidadeIdFiltro,
        );
      } else {
        _pontos = await _service.buscarPontos();
      }

      // Aplicar refinamento por cascata (linhas, falanges, entidades selecionadas)
      if (_pontos.isNotEmpty) {
        if (_entidadesFiltro.isNotEmpty) {
          _pontos = _pontos.where((p) => p.entidadeId != null && _entidadesFiltro.contains(p.entidadeId)).toList();
        }

        if (listaEntidades != null && listaEntidades.isNotEmpty) {
          final entidadeMap = {for (var e in listaEntidades) if (e.id != null) e.id!: e};
          if (_linhasFiltro.isNotEmpty) {
            _pontos = _pontos.where((p) {
              if (p.entidadeId == null) return false;
              final e = entidadeMap[p.entidadeId];
              return e != null && _linhasFiltro.contains(e.linhaEntidade);
            }).toList();
          }
          if (_falangesFiltro.isNotEmpty) {
            _pontos = _pontos.where((p) {
              if (p.entidadeId == null) return false;
              final e = entidadeMap[p.entidadeId];
              return e != null && _falangesFiltro.contains(e.falange);
            }).toList();
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar pontos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> aplicarFiltroCascata({
    String? termo,
    int? entidadeId,
    Set<String>? linhas,
    Set<String>? falanges,
    Set<int>? entidades,
    List<Entidade>? listaEntidades,
  }) async {
    _termoFiltro = termo;
    _entidadeIdFiltro = entidadeId;
    _linhasFiltro = linhas != null ? Set.from(linhas) : {};
    _falangesFiltro = falanges != null ? Set.from(falanges) : {};
    _entidadesFiltro = entidades != null ? Set.from(entidades) : {};
    await carregarPontos(listaEntidades: listaEntidades);
  }

  Future<void> filtrarPontos({String? termo, int? entidadeId, List<Entidade>? listaEntidades}) async {
    _termoFiltro = termo;
    _entidadeIdFiltro = entidadeId;
    await carregarPontos(listaEntidades: listaEntidades);
  }

  Future<void> limparFiltros({List<Entidade>? listaEntidades}) async {
    _termoFiltro = null;
    _entidadeIdFiltro = null;
    _linhasFiltro.clear();
    _falangesFiltro.clear();
    _entidadesFiltro.clear();
    await carregarPontos(listaEntidades: listaEntidades);
  }

  Future<bool> cadastrarPonto(PontoCantado ponto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final novoPonto = await _service.cadastrarPonto(ponto);
      _pontos.add(novoPonto);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar ponto: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarPonto(int id, PontoCantado ponto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizado = await _service.atualizarPonto(id, ponto);
      final index = _pontos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _pontos[index] = atualizado;
      } else {
        _pontos.add(atualizado);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar ponto: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletarPonto(int id, {String? nomePonto, String? nomeEntidade}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deletarPonto(id, nomePonto: nomePonto, nomeEntidade: nomeEntidade);
      _pontos.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao deletar ponto: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
