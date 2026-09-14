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
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        PontoCantado resultado = ponto;
        final decodedBody = utf8.decode(response.bodyBytes).trim();
        if (decodedBody.isNotEmpty) {
          try {
            final dynamic jsonResponse = jsonDecode(decodedBody);
            if (jsonResponse is Map<String, dynamic>) {
              resultado = PontoCantado.fromJson(jsonResponse);
            } else if (jsonResponse is num) {
              resultado = ponto.copyWith(id: jsonResponse.toInt());
            }
          } catch (_) {
            final intId = int.tryParse(decodedBody);
            if (intId != null) {
              resultado = ponto.copyWith(id: intId);
            }
          }
        }
        final novoPonto = resultado.id == null ? resultado.copyWith(id: _nextMockId++) : resultado;
        _mockPontos.add(novoPonto);
        return novoPonto;
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
      var response = await _client
          .patch(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(ponto.toJson()),
          )
          .timeout(ApiConfig.timeout);

      // Fallback para PUT se o backend retornar 405 (Method Not Allowed) ou 404
      if (response.statusCode == 405 || response.statusCode == 404) {
        response = await _client
            .put(
              uri,
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: jsonEncode(ponto.toJson()),
            )
            .timeout(ApiConfig.timeout);
      }

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        PontoCantado resultado = ponto.copyWith(id: id);
        final decodedBody = utf8.decode(response.bodyBytes).trim();
        if (decodedBody.isNotEmpty) {
          try {
            final dynamic jsonResponse = jsonDecode(decodedBody);
            if (jsonResponse is Map<String, dynamic>) {
              var updated = PontoCantado.fromJson(jsonResponse);
              if (updated.nomePonto.isEmpty && ponto.nomePonto.isNotEmpty) {
                updated = updated.copyWith(nomePonto: ponto.nomePonto);
              }
              if (updated.pontoLetra.isEmpty && ponto.pontoLetra.isNotEmpty) {
                updated = updated.copyWith(pontoLetra: ponto.pontoLetra);
              }
              resultado = updated.id == null ? updated.copyWith(id: id) : updated;
            }
          } catch (_) {}
        }
        final index = _mockPontos.indexWhere((p) => p.id == id);
        if (index != -1) {
          _mockPontos[index] = resultado;
        } else {
          _mockPontos.add(resultado);
        }
        return resultado;
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

  Future<void> deletarPonto(int id, {String? nomePonto, String? nomeEntidade}) async {
    final queryParams = <String, String>{
      'id': id.toString(),
    };
    if (nomePonto != null && nomePonto.isNotEmpty) {
      queryParams['nomePonto'] = nomePonto;
    }
    if (nomeEntidade != null && nomeEntidade.isNotEmpty) {
      queryParams['nomeEntidade'] = nomeEntidade;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/gestaopontos/deletar')
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
    _mockPontos.removeWhere((p) => p.id == id);
  }
}
