import 'package:flutter/foundation.dart';
import '../models/ponto_cantado.dart';
import '../services/ponto_service.dart';

class PontosProvider extends ChangeNotifier {
  final PontoService _service;

  PontosProvider({PontoService? service}) : _service = service ?? PontoService();

  List<PontoCantado> _pontos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _termoFiltro;
  int? _entidadeIdFiltro;

  List<PontoCantado> get pontos => List.unmodifiable(_pontos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get termoFiltro => _termoFiltro;
  int? get entidadeIdFiltro => _entidadeIdFiltro;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> carregarPontos() async {
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
    } catch (e) {
      _errorMessage = 'Erro ao carregar pontos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filtrarPontos({String? termo, int? entidadeId}) async {
    _termoFiltro = termo;
    _entidadeIdFiltro = entidadeId;
    await carregarPontos();
  }

  Future<void> limparFiltros() async {
    _termoFiltro = null;
    _entidadeIdFiltro = null;
    await carregarPontos();
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
