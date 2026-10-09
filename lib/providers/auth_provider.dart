import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  String? _token;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Inicializa o estado de autenticação recuperando a sessão salva (Auto Login)
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await _authService.getSavedUserData();
      final savedToken = userData['token'];

      if (savedToken != null && savedToken.isNotEmpty) {
        // Verifica se o token expirou
        if (!AuthService.isTokenExpired(savedToken)) {
          _token = savedToken;
          _userEmail = userData['email'];
          _userName = userData['nome'];
          _userRole = userData['role'];
          _isLoggedIn = true;
        } else {
          // Tenta renovar o token expirado na inicialização
          bool refreshed = await _authService.refreshTokenSilently();
          if (refreshed) {
             final updatedUserData = await _authService.getSavedUserData();
             _token = updatedUserData['token'];
             _userEmail = updatedUserData['email'];
             _userName = updatedUserData['nome'];
             _userRole = updatedUserData['role'];
             _isLoggedIn = true;
          } else {
            // Se o refresh falhar, limpa a sessão
            await _authService.logout();
            _isLoggedIn = false;
            _token = null;
          }
        }
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Executa o login com validações do backend
  Future<bool> login(String email, String senha) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _authService.login(
        email: email,
        senha: senha,
      );

      _token = resultado['token'];
      _userEmail = resultado['email'];
      _userName = resultado['nome'];
      _userRole = resultado['role'];
      _isLoggedIn = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Executa o cadastro de novo usuário
  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sucesso = await _authService.cadastrar(
        nome: nome,
        email: email,
        senha: senha,
        role: role,
      );

      _isLoading = false;
      notifyListeners();
      return sucesso;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Efetua o logout do usuário e limpa o token/cookie armazenado
  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _userEmail = null;
    _userName = null;
    _userRole = null;
    _isLoggedIn = false;
    _errorMessage = null;
    notifyListeners();
  }
}
