import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  static const String _tokenKey = 'jwt_token';
  static const String _cookieKey = 'auth_cookie';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';

  /// Cabeçalhos limpos sem Authorization ou Cookie para chamadas não autenticadas
  static const Map<String, String> _unauthenticatedHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json, text/plain',
  };

  /// Retorna a URI usando o protocolo HTTP configurado em ApiConfig
  Uri _getUri(String endpoint) {
    String base = ApiConfig.baseUrl;
    if (base.startsWith('https://')) {
      base = base.replaceFirst('https://', 'http://');
    }
    return Uri.parse('$base$endpoint');
  }

  /// Realiza login via email e senha (@PostMapping("/login"))
  /// Garantido que NÃO envia cabeçalhos de Authorization/Cookie (pois não possui token prévio)
  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    Uri uri = _getUri('/login');

    final bodyJson = jsonEncode({
      'email': email,
      'senha': senha,
    });

    try {
      var response = await _client
          .post(
            uri,
            headers: _unauthenticatedHeaders,
            body: bodyJson,
          )
          .timeout(ApiConfig.timeout);

      // Fallback se o backend mapear em /auth/login
      if (response.statusCode == 404) {
        uri = _getUri('/auth/login');
        response = await _client
            .post(
              uri,
              headers: _unauthenticatedHeaders,
              body: bodyJson,
            )
            .timeout(ApiConfig.timeout);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        String token = '';
        final responseBody = utf8.decode(response.bodyBytes).trim();

        if (responseBody.startsWith('{')) {
          final Map<String, dynamic> data = jsonDecode(responseBody);
          token = data['token'] ?? data['jwt'] ?? data['accessToken'] ?? '';
        } else {
          token = responseBody.replaceAll('"', '');
        }

        if (token.isEmpty) {
          throw Exception('Token JWT não foi retornado pelo servidor.');
        }

        final payload = parseJwt(token);
        final String subject = payload['sub']?.toString() ?? email;
        final String nome = payload['nome']?.toString() ?? payload['name']?.toString() ?? subject.split('@').first;
        final String role = payload['role']?.toString() ?? 'USUARIO';

        await _salvarSessao(
          token: token,
          email: email,
          nome: nome,
          role: role,
        );

        return {
          'token': token,
          'email': email,
          'nome': nome,
          'role': role,
          'payload': payload,
        };
      } else {
        final errorMsg = _extrairMensagemErro(response);
        throw Exception(errorMsg ?? 'Falha no login (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (ApiConfig.enableMockFallback) {
        final mockToken = _gerarMockJwt(email);
        final payload = parseJwt(mockToken);
        final nome = email.split('@').first;
        await _salvarSessao(
          token: mockToken,
          email: email,
          nome: nome,
          role: 'USUARIO',
        );
        return {
          'token': mockToken,
          'email': email,
          'nome': nome,
          'role': 'USUARIO',
          'payload': payload,
        };
      }
      rethrow;
    }
  }

  /// Realiza cadastro de novo usuário (@PostMapping("/registrar"))
  /// Garantido que NÃO envia cabeçalhos de Authorization/Cookie
  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String role, // ADM, FILHO, USUARIO
  }) async {
    Uri uri = _getUri('/registrar');

    final bodyJson = jsonEncode({
      'nome': nome,
      'email': email,
      'senha': senha,
      'role': role,
    });

    try {
      var response = await _client
          .post(
            uri,
            headers: _unauthenticatedHeaders,
            body: bodyJson,
          )
          .timeout(ApiConfig.timeout);

      // Fallback se o backend mapear em /auth/registrar ou /auth/cadastrar
      if (response.statusCode == 404) {
        uri = _getUri('/auth/registrar');
        response = await _client
            .post(
              uri,
              headers: _unauthenticatedHeaders,
              body: bodyJson,
            )
            .timeout(ApiConfig.timeout);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final errorMsg = _extrairMensagemErro(response);
        throw Exception(errorMsg ?? 'Erro ao cadastrar (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (ApiConfig.enableMockFallback) {
        return true;
      }
      rethrow;
    }
  }

  Future<void> _salvarSessao({
    required String token,
    required String email,
    required String nome,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_cookieKey, 'jwt=$token');
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, nome);
    await prefs.setString(_userRoleKey, role);
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String?>> getSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_tokenKey),
      'cookie': prefs.getString(_cookieKey),
      'email': prefs.getString(_userEmailKey),
      'nome': prefs.getString(_userNameKey),
      'role': prefs.getString(_userRoleKey),
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_cookieKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
  }

  /// Retorna os headers com Authorization e Cookie apenas para chamadas autenticadas
  Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final cookie = prefs.getString(_cookieKey);

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    return headers;
  }

  static Map<String, dynamic> parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException('Formato de token JWT inválido.');
      }
      final payload = _decodeBase64(parts[1]);
      final payloadMap = jsonDecode(payload);
      if (payloadMap is! Map<String, dynamic>) {
        throw const FormatException('Payload de JWT inválido.');
      }
      return payloadMap;
    } catch (e) {
      return {};
    }
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('String Base64 URL inválida.');
    }
    return utf8.decode(base64Url.decode(output));
  }

  static bool isTokenExpired(String token) {
    try {
      final payload = parseJwt(token);
      if (!payload.containsKey('exp')) return false;

      final exp = payload['exp'];
      if (exp is int) {
        final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(expirationDate);
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  String? _extrairMensagemErro(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded['message'] ?? decoded['error'] ?? decoded['mensagem'];
      }
    } catch (_) {}
    return null;
  }

  String _gerarMockJwt(String email) {
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final expTime = DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000;
    final payloadMap = {
      'iss': 'batuque-api',
      'sub': email,
      'nome': email.split('@').first,
      'role': 'USUARIO',
      'exp': expTime,
    };
    final payload = base64Url.encode(utf8.encode(jsonEncode(payloadMap)));
    return '$header.$payload.mock_signature_hash';
  }
}
