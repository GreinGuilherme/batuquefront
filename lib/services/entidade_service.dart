import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entidade.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'mock_data.dart';

class EntidadeService {
  final http.Client _client;
  final AuthService _authService;

  EntidadeService({http.Client? client, AuthService? authService})
      : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  final List<Entidade> _mockEntidades = List.from(MockData.entidades);
  int _nextMockId = 100;

  Future<List<Entidade>> buscarEntidades() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/buscar');
    final headers = await _authService.getAuthHeaders();

    try {
      final response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((e) => Entidade.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    return List.from(_mockEntidades);
  }

  Future<List<Entidade>> filtrarEntidades(String termo) async {
    final queryParams = <String, String>{};
    if (termo.isNotEmpty) {
      queryParams['termo'] = termo;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/buscar/filtro')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final headers = await _authService.getAuthHeaders();

    try {
      final response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((e) => Entidade.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    if (termo.isEmpty) return List.from(_mockEntidades);
    final termoLower = termo.toLowerCase();
    return _mockEntidades.where((e) {
      return e.nomeEntidade.toLowerCase().contains(termoLower) ||
          e.falange.toLowerCase().contains(termoLower) ||
          e.linhaEntidade.toLowerCase().contains(termoLower);
    }).toList();
  }

  Future<Entidade> cadastrarEntidade(Entidade entidade) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/cadastrar');
    final headers = await _authService.getAuthHeaders();

    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(entidade.toJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Entidade.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    final novaEntidade = entidade.copyWith(id: entidade.id ?? _nextMockId++);
    _mockEntidades.add(novaEntidade);
    return novaEntidade;
  }

  Future<Entidade> atualizarEntidade(int id, Entidade entidade) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/atualizar/$id');
    final headers = await _authService.getAuthHeaders();

    try {
      final response = await _client
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(entidade.toJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        return Entidade.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    final index = _mockEntidades.indexWhere((e) => e.id == id);
    final entidadeAtualizada = entidade.copyWith(id: id);
    if (index != -1) {
      _mockEntidades[index] = entidadeAtualizada;
    } else {
      _mockEntidades.add(entidadeAtualizada);
    }
    return entidadeAtualizada;
  }

  Future<void> deletarEntidade(int entidadeId, {String? nomeEntidade}) async {
    final queryParams = <String, String>{
      'id': entidadeId.toString(),
    };
    if (nomeEntidade != null && nomeEntidade.isNotEmpty) {
      queryParams['nomeEntidade'] = nomeEntidade;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/entidade/deletar')
        .replace(queryParameters: queryParams);
    final headers = await _authService.getAuthHeaders();

    try {
      final response = await _client.delete(uri, headers: headers).timeout(ApiConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Erro na requisição: ${response.statusCode}');
    } catch (_) {
      if (!ApiConfig.enableMockFallback) rethrow;
    }
    _mockEntidades.removeWhere((e) => e.id == entidadeId);
  }
}
