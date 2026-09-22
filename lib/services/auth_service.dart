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

  /// Realiza login via email e senha (@PostMapping("/auth/login"))
  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    Uri uri = _getUri('/auth/login');

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

      // Fallback para /login caso o controller não utilize o prefixo /auth
      if (response.statusCode == 404) {
        uri = _getUri('/login');
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
        String rawNome = '';
        String userEmail = email;
        String userRole = 'USUARIO';

        final responseBody = utf8.decode(response.bodyBytes).trim();

        if (responseBody.startsWith('{')) {
          final Map<String, dynamic> data = jsonDecode(responseBody);
          token = data['token'] ?? data['jwt'] ?? data['accessToken'] ?? '';
          rawNome = data['nome'] ?? data['name'] ?? data['username'] ?? '';
          if (data.containsKey('email') && data['email'].toString().contains('@')) {
            userEmail = data['email'].toString();
          }
          if (data.containsKey('role')) {
            userRole = data['role'].toString();
          }
        } else {
          token = responseBody.replaceAll('"', '');
        }

        if (token.isEmpty) {
          throw Exception('Token JWT não foi retornado pelo servidor.');
        }

        final payload = parseJwt(token);
        final String subject = payload['sub']?.toString() ?? userEmail;

        if (rawNome.isEmpty) {
          rawNome = payload['nome']?.toString() ??
              payload['name']?.toString() ??
              payload['username']?.toString() ??
              '';
        }

        if (payload.containsKey('role')) {
          userRole = payload['role'].toString();
        }

        // Sanitiza o nome do usuário para nunca exibir a classe/entidade Java
        final String nomeSanitizado = _sanitizarNome(rawNome, subject, userEmail);

        await _salvarSessao(
          token: token,
          email: userEmail,
          nome: nomeSanitizado,
          role: userRole,
        );

        return {
          'token': token,
          'email': userEmail,
          'nome': nomeSanitizado,
          'role': userRole,
          'payload': payload,
        };
      } else {
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('Falha no login: usuário ou senha incorretos.');
        }
        final errorMsg = _extrairMensagemErro(response);
        if (errorMsg != null &&
            errorMsg.isNotEmpty &&
            !errorMsg.contains('403') &&
            !errorMsg.contains('401')) {
          throw Exception(errorMsg);
        }
        throw Exception('Falha no login: usuário ou senha incorretos.');
      }
    } catch (e) {
      if (ApiConfig.enableMockFallback) {
        final mockToken = _gerarMockJwt(email);
        final payload = parseJwt(mockToken);
        final nome = _extrairNomeDoEmail(email);
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

  /// Realiza cadastro de novo usuário (@PostMapping("/auth/registrar"))
  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String role, // ADM, FILHO, USUARIO
  }) async {
    Uri uri = _getUri('/auth/registrar');

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

      // Fallback para /registrar caso o controller não utilize o prefixo /auth
      if (response.statusCode == 404) {
        uri = _getUri('/registrar');
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
        throw Exception(errorMsg ?? 'Erro ao cadastrar usuário.');
      }
    } catch (e) {
      if (ApiConfig.enableMockFallback) {
        return true;
      }
      rethrow;
    }
  }

  /// Sanitiza o nome de exibição descartando nomes de pacotes/entidades do Java
  static String _sanitizarNome(String rawNome, String subject, String email) {
    final candidatos = [rawNome, subject];

    for (final c in candidatos) {
      final val = c.trim();
      if (val.isNotEmpty) {
        // Rejeita se for classe/pacote Java (ex: com.api.batuque...UsuarioEntity) ou email
        final eClasseJava = val.startsWith('com.') ||
            val.contains('.entity.') ||
            val.contains('Entity') ||
            val.contains('UsuarioJpa') ||
            val.contains('adpater');
        final eEmail = val.contains('@');

        if (!eClasseJava && !eEmail) {
          return val;
        }
      }
    }

    // Se nenhum candidato for um nome válido, formata a partir do e-mail
    return _extrairNomeDoEmail(email);
  }

  /// Extrai o nome amigável a partir do e-mail (ex: guilherme@gmail.com -> Guilherme)
  static String _extrairNomeDoEmail(String email) {
    if (!email.contains('@')) return email.isEmpty ? 'Usuário' : email;
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return 'Usuário';
    return prefix[0].toUpperCase() + prefix.substring(1);
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
    final savedEmail = prefs.getString(_userEmailKey) ?? '';
    final savedNome = prefs.getString(_userNameKey) ?? '';

    return {
      'token': prefs.getString(_tokenKey),
      'cookie': prefs.getString(_cookieKey),
      'email': savedEmail,
      'nome': _sanitizarNome(savedNome, '', savedEmail),
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
