import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/logging_http_client.dart';
import 'api_config.dart';

class AuthService {
  final http.Client _client;
  Future<bool>? _refreshFuture;

  AuthService({http.Client? client}) : _client = client ?? LoggingHttpClient();

  static const String _tokenKey = 'jwt_token';
  static const String _cookieKey = 'auth_cookie';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';

  /// Retorna a URI usando a URL base configurada em ApiConfig
  Uri _getUri(String endpoint) {
    final base = ApiConfig.baseUrl;
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
            headers: await getAuthHeaders(),
            body: bodyJson,
          )
          .timeout(ApiConfig.timeout);

      // Fallback para /login caso o controller não utilize o prefixo /auth
      if (response.statusCode == 404) {
        uri = _getUri('/login');
        response = await _client
            .post(
              uri,
              headers: await getAuthHeaders(),
              body: bodyJson,
            )
            .timeout(ApiConfig.timeout);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        String token = '';
        String rawNome = '';
        String userEmail = email;
        String userRole = 'USUARIO';
        String? refreshToken;

        final responseBody = utf8.decode(response.bodyBytes).trim();

        if (responseBody.startsWith('{')) {
          final Map<String, dynamic> data = jsonDecode(responseBody);
          token = data['token'] ?? data['jwt'] ?? data['accessToken'] ?? '';
          rawNome = _extrairNomeDoMap(data);
          final dataRole = _extrairRole(data);
          if (dataRole.isNotEmpty) {
            userRole = dataRole;
          }
          if (data.containsKey('email') && data['email'].toString().contains('@')) {
            userEmail = data['email'].toString();
          }
          for (final key in ['tokenRefresh', 'refreshToken', 'refresh_token', 'token_refresh']) {
            if (data[key] != null && data[key].toString().isNotEmpty) {
              refreshToken = data[key].toString();
              break;
            }
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
          rawNome = _extrairNomeDoMap(payload);
        }

        final jwtRole = _extrairRole(payload);
        if (jwtRole.isNotEmpty) {
          userRole = jwtRole;
        }

        final jwtEmail = payload['email']?.toString() ?? payload['sub']?.toString();
        if (jwtEmail != null && jwtEmail.contains('@')) {
          userEmail = jwtEmail;
        }

        // Tenta buscar o nome salvo anteriormente nas SharedPreferences se o servidor não retornou nada
        final prefs = await SharedPreferences.getInstance();
        final savedNome = prefs.getString(_userNameKey);

        // Sanitiza o nome do usuário priorizando o nome retornado pelo servidor / JWT
        final String nomeSanitizado = _sanitizarNome(rawNome, subject, userEmail, savedNome: savedNome);

        // Captura o cookie retornado pelo servidor no header Set-Cookie, se existir
        String cookieValue = 'jwt=$token';
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader != null && setCookieHeader.trim().isNotEmpty) {
          final rawCookie = setCookieHeader.split(';').first.trim();
          if (rawCookie.isNotEmpty) {
            cookieValue = rawCookie;
          }
        }

        await _salvarSessao(
          token: token,
          cookie: cookieValue,
          email: userEmail,
          nome: nomeSanitizado,
          role: userRole,
          refreshToken: refreshToken,
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
            headers: await getAuthHeaders(),
            body: bodyJson,
          )
          .timeout(ApiConfig.timeout);

      // Fallback para /registrar caso o controller não utilize o prefixo /auth
      if (response.statusCode == 404) {
        uri = _getUri('/registrar');
        response = await _client
            .post(
              uri,
              headers: await getAuthHeaders(),
              body: bodyJson,
            )
            .timeout(ApiConfig.timeout);
      }

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 202) {
        // Armazena o nome cadastrado no SharedPreferences para preservá-lo após o login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userNameKey, nome.trim());
        await prefs.setString(_userEmailKey, email.trim());
        return true;
      } else {
        final errorMsg = _extrairMensagemErro(response);
        throw Exception(errorMsg ?? 'Erro ao cadastrar usuário.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Solicita o código de recuperação de senha enviado por e-mail (@PostMapping("/auth/esqueci-senha"))
  Future<String> solicitarCodigoRecuperacao({required String email}) async {
    Uri uri = _getUri('/auth/esqueci-senha');

    final bodyJson = jsonEncode({
      'email': email.trim(),
    });

    try {
      var response = await _client
          .post(
            uri,
            headers: await getAuthHeaders(),
            body: bodyJson,
          )
          .timeout(ApiConfig.timeout);

      // Fallback para /esqueci-senha caso o controller não utilize o prefixo /auth
      if (response.statusCode == 404) {
        uri = _getUri('/esqueci-senha');
        response = await _client
            .post(
              uri,
              headers: await getAuthHeaders(),
              body: bodyJson,
            )
            .timeout(ApiConfig.timeout);
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final responseBody = utf8.decode(response.bodyBytes).trim();
        if (responseBody.isNotEmpty && responseBody.startsWith('{')) {
          final Map<String, dynamic> data = jsonDecode(responseBody);
          final msg = data['mensagem'] ?? data['message'];
          if (msg != null && msg.toString().isNotEmpty) {
            return msg.toString();
          }
        }
        return 'Caso o e-mail esteja cadastrado, você receberá um código de recuperação em instantes.';
      } else {
        final errorMsg = _extrairMensagemErro(response);
        throw Exception(
            errorMsg ?? 'Erro ao solicitar código de recuperação.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Redefine a senha utilizando e-mail, código OTP e a nova senha (@PostMapping("/auth/redefinir-senha"))
  Future<String> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    Uri uri = _getUri('/auth/redefinir-senha');

    final bodyJson = jsonEncode({
      'email': email.trim(),
      'codigo': codigo.trim(),
      'novaSenha': novaSenha,
    });

    try {
      var response = await _client
          .post(
            uri,
            headers: await getAuthHeaders(),
            body: bodyJson,
          )
          .timeout(ApiConfig.timeout);

      // Fallback para /redefinir-senha caso o controller não utilize o prefixo /auth
      if (response.statusCode == 404) {
        uri = _getUri('/redefinir-senha');
        response = await _client
            .post(
              uri,
              headers: await getAuthHeaders(),
              body: bodyJson,
            )
            .timeout(ApiConfig.timeout);
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final responseBody = utf8.decode(response.bodyBytes).trim();
        if (responseBody.isNotEmpty && responseBody.startsWith('{')) {
          final Map<String, dynamic> data = jsonDecode(responseBody);
          final msg = data['mensagem'] ?? data['message'];
          if (msg != null && msg.toString().isNotEmpty) {
            return msg.toString();
          }
        }
        return 'Senha atualizada com sucesso! Faça login com sua nova senha.';
      } else {
        final errorMsg = _extrairMensagemErro(response);
        throw Exception(errorMsg ??
            'Erro ao redefinir senha. Verifique o código e tente novamente.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Extrai a Role do usuário a partir do mapa JSON da resposta de login ou do JWT
  static String _extrairRole(Map<String, dynamic> map) {
    // 1. Tenta chaves diretas no mapa principal
    for (final key in ['role', 'userRole', 'perfil', 'user_role', 'authority']) {
      if (map[key] != null && map[key].toString().trim().isNotEmpty) {
        final r = map[key].toString().trim().replaceAll('ROLE_', '');
        if (r.isNotEmpty) return r;
      }
    }

    // 2. Tenta arrays (roles, authorities, etc.)
    for (final key in ['roles', 'authorities', 'groups']) {
      if (map[key] is List && (map[key] as List).isNotEmpty) {
        final first = (map[key] as List).first;
        if (first is Map && first['authority'] != null) {
          final r = first['authority'].toString().trim().replaceAll('ROLE_', '');
          if (r.isNotEmpty) return r;
        } else if (first != null) {
          final r = first.toString().trim().replaceAll('ROLE_', '');
          if (r.isNotEmpty) return r;
        }
      }
    }

    // 3. Tenta objetos aninhados (usuario, user, etc.)
    for (final key in ['usuario', 'user', 'dadosUsuario', 'account']) {
      if (map[key] is Map<String, dynamic>) {
        final subRole = _extrairRole(map[key] as Map<String, dynamic>);
        if (subRole.isNotEmpty) return subRole;
      }
    }

    return '';
  }

  /// Extrai o nome do usuário a partir do mapa JSON da resposta de login ou do JWT
  static String _extrairNomeDoMap(Map<String, dynamic> data) {
    // 1. Tenta chaves diretas no objeto principal
    String? n = data['nome']?.toString() ??
        data['nomeUsuario']?.toString() ??
        data['nomeCompleto']?.toString() ??
        data['name']?.toString() ??
        data['displayName']?.toString() ??
        data['fullName']?.toString();

    if (n != null && n.trim().isNotEmpty && !n.contains('@') && !_isClasseJava(n)) {
      return n.trim();
    }

    // 2. Tenta objetos aninhados (usuario, user, etc.)
    for (final subKey in ['usuario', 'user', 'dadosUsuario', 'account']) {
      if (data[subKey] is Map<String, dynamic>) {
        final subMap = data[subKey] as Map<String, dynamic>;
        final subName = subMap['nome']?.toString() ??
            subMap['nomeUsuario']?.toString() ??
            subMap['nomeCompleto']?.toString() ??
            subMap['name']?.toString() ??
            subMap['displayName']?.toString() ??
            subMap['fullName']?.toString();
        if (subName != null && subName.trim().isNotEmpty && !subName.contains('@') && !_isClasseJava(subName)) {
          return subName.trim();
        }
      }
    }

    // 3. Tenta campo 'username' APENAS se não for email
    final username = data['username']?.toString();
    if (username != null && username.trim().isNotEmpty && !username.contains('@') && !_isClasseJava(username)) {
      return username.trim();
    }

    return '';
  }

  static bool _isClasseJava(String str) {
    final val = str.trim();
    return val.startsWith('com.') ||
        val.contains('.entity.') ||
        val.contains('Entity') ||
        val.contains('UsuarioJpa') ||
        val.contains('adpater');
  }

  /// Sanitiza o nome de exibição descartando nomes de pacotes/entidades do Java ou e-mails
  static String _sanitizarNome(String rawNome, String subject, String email, {String? savedNome}) {
    final candidatos = [rawNome, savedNome ?? '', subject];

    for (final c in candidatos) {
      final val = c.trim();
      if (val.isNotEmpty) {
        final eClasseJava = _isClasseJava(val);
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

  /// Rota para renovar o token. O Backend deve receber o refresh_token e devolver um novo access_token (e opcionalmente novo refresh_token)
  Future<bool> refreshTokenSilently() async {
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }
    _refreshFuture = _doRefreshTokenSilently();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefreshTokenSilently() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      return false; // Não há refresh token para usar
    }

    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json, text/plain, */*',
        'x-app-batuque': 'GiraSegura2026',
        'User-Agent': 'BatuqueFlutterApp/1.0 (Android; iOS)',
      };

      final bodyJson = jsonEncode({
        'tokenRefresh': refreshToken,
        'refreshToken': refreshToken,
        'refresh_token': refreshToken,
      });

      Uri uri = _getUri('/auth/refresh');
      var response = await _client
          .post(
            uri,
            headers: headers,
            body: bodyJson,
          )
          .timeout(ApiConfig.timeout);

      // Fallback para /refresh caso o controller não utilize o prefixo /auth
      if (response.statusCode == 404 || response.statusCode == 405) {
        uri = _getUri('/refresh');
        response = await _client
            .post(
              uri,
              headers: headers,
              body: bodyJson,
            )
            .timeout(ApiConfig.timeout);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = utf8.decode(response.bodyBytes).trim();
        if (responseBody.isEmpty) return false;

        String? newToken;
        String? newRefreshToken;

        if (responseBody.startsWith('{')) {
          final Map<String, dynamic> data = jsonDecode(responseBody);
          newToken = data['token'] ?? data['accessToken'] ?? data['jwt'] ?? data['tokenAcesso'];
          newRefreshToken = data['tokenRefresh'] ?? data['refreshToken'] ?? data['refresh_token'] ?? data['token_refresh'];
        } else {
          newToken = responseBody.replaceAll('"', '');
        }

        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString(_tokenKey, newToken);
          await prefs.setString(_cookieKey, 'jwt=$newToken');

          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await prefs.setString('refresh_token', newRefreshToken);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _salvarSessao({
    required String token,
    String? cookie,
    required String email,
    required String nome,
    required String role,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_cookieKey, cookie ?? 'jwt=$token');
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, nome);
    await prefs.setString(_userRoleKey, role);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString('refresh_token', refreshToken);
    }
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String?>> getSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final savedEmail = prefs.getString(_userEmailKey) ?? '';
    final savedNome = prefs.getString(_userNameKey) ?? '';
    final savedRole = prefs.getString(_userRoleKey) ?? 'USUARIO';

    String userEmail = savedEmail;
    String rawNome = savedNome;
    String userRole = savedRole;

    if (token != null && token.isNotEmpty) {
      final payload = parseJwt(token);
      if (payload.isNotEmpty) {
        final jwtRole = _extrairRole(payload);
        if (jwtRole.isNotEmpty) userRole = jwtRole;

        final jwtEmail = payload['email']?.toString() ?? payload['sub']?.toString();
        if (jwtEmail != null && jwtEmail.contains('@')) userEmail = jwtEmail;

        final jwtNome = _extrairNomeDoMap(payload);
        if (jwtNome.isNotEmpty) rawNome = jwtNome;
      }
    }

    final nomeSanitizado = _sanitizarNome(rawNome, '', userEmail, savedNome: savedNome);

    return {
      'token': token,
      'cookie': prefs.getString(_cookieKey),
      'email': userEmail,
      'nome': nomeSanitizado,
      'role': userRole,
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_cookieKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove('refresh_token');
  }

  /// Retorna os headers com Authorization e Cookie apenas para chamadas autenticadas.
  /// Se o token JWT estiver expirado ou prestes a expirar (30s), tenta renová-lo silenciosamente usando o refresh_token.
  Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(_tokenKey);

    // Se o token estiver expirado ou prestes a expirar nos próximos 30 segundos, renova automaticamente
    if (token != null && token.isNotEmpty && isTokenExpired(token, thresholdSeconds: 30)) {
      final refreshed = await refreshTokenSilently();
      if (refreshed) {
        token = prefs.getString(_tokenKey);
      }
    }

    final cookie = prefs.getString(_cookieKey);

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json, text/plain, */*',
      'x-app-batuque': 'GiraSegura2026',
      'User-Agent': 'BatuqueFlutterApp/1.0 (Android; iOS)',
    };

    if (token != null && token.isNotEmpty) {
      final bearerToken = token.startsWith('Bearer ') ? token : 'Bearer $token';
      headers['Authorization'] = bearerToken;
    }
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    } else if (token != null && token.isNotEmpty) {
      headers['Cookie'] = 'jwt=$token';
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

  static bool isTokenExpired(String token, {int thresholdSeconds = 0}) {
    try {
      final payload = parseJwt(token);
      if (!payload.containsKey('exp')) return false;

      final exp = payload['exp'];
      if (exp is int) {
        final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final nowWithThreshold = DateTime.now().add(Duration(seconds: thresholdSeconds));
        return nowWithThreshold.isAfter(expirationDate);
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
}
