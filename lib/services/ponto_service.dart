import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ponto_cantado.dart';
import 'api_config.dart';
import 'mock_data.dart';

class PontoService {
  final http.Client _client;

  PontoService({http.Client? client}) : _client = client ?? http.Client();

  final List<PontoCantado> _mockPontos = List.from(MockData.pontos);
  int _nextMockId = 100;

  Future<List<PontoCantado>> buscarPontos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/buscar');
    try {
      final response = await _client.get(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((e) => PontoCantado.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    return List.from(_mockPontos);
  }

  Future<List<PontoCantado>> filtrarPontos({String? termo, int? entidadeId}) async {
    final queryParams = <String, String>{};
    if (termo != null && termo.isNotEmpty) {
      queryParams['termo'] = termo;
    }
    if (entidadeId != null) {
      queryParams['entidadeId'] = entidadeId.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/buscar/filtro')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await _client.get(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((e) => PontoCantado.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }

    return _mockPontos.where((p) {
      bool matchesTermo = true;
      if (termo != null && termo.isNotEmpty) {
        final tLower = termo.toLowerCase();
        matchesTermo = p.nomePonto.toLowerCase().contains(tLower) ||
            p.pontoLetra.toLowerCase().contains(tLower);
      }
      bool matchesEntidade = true;
      if (entidadeId != null) {
        matchesEntidade = p.entidadeId == entidadeId;
      }
      return matchesTermo && matchesEntidade;
    }).toList();
  }

  Future<PontoCantado> cadastrarPonto(PontoCantado ponto) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/cadastrar');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(ponto.toJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return PontoCantado.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    final novoPonto = ponto.copyWith(id: ponto.id ?? _nextMockId++);
    _mockPontos.add(novoPonto);
    return novoPonto;
  }

  Future<PontoCantado> atualizarPonto(int id, PontoCantado ponto) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/atualizar/$id');
    try {
      final response = await _client
          .patch(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(ponto.toJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        return PontoCantado.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    final index = _mockPontos.indexWhere((p) => p.id == id);
    final pontoAtualizado = ponto.copyWith(id: id);
    if (index != -1) {
      _mockPontos[index] = pontoAtualizado;
    } else {
      _mockPontos.add(pontoAtualizado);
    }
    return pontoAtualizado;
  }

  Future<void> deletarPonto(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/deletar/$id');
    try {
      final response = await _client.delete(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    _mockPontos.removeWhere((p) => p.id == id);
  }
}
