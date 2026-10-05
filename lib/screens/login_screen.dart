import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers - Login
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginSenhaController = TextEditingController();
  bool _loginObscureSenha = true;

  // Form Controllers - Cadastro
  final _cadastroFormKey = GlobalKey<FormState>();
  final _cadastroNomeController = TextEditingController();
  final _cadastroEmailController = TextEditingController();
  final _cadastroSenhaController = TextEditingController();
  bool _cadastroObscureSenha = true;
  String _selectedRole = 'USUARIO'; // ADM, FILHO, USUARIO

  // Regex para validação de Email
  final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // Regex para validação de senha no cadastro (deve conter letras, números e caractere especial)
  final _hasLetter = RegExp(r'[a-zA-Z]');
  final _hasDigit = RegExp(r'\d');
  final _hasSpecialChar =
      RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?~`]');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Ouvinte para atualizar a lista de checagem da senha em tempo real apenas no cadastro
    _cadastroSenhaController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginSenhaController.dispose();
    _cadastroNomeController.dispose();
    _cadastroEmailController.dispose();
    _cadastroSenhaController.dispose();
    super.dispose();
  }

  /// Validador de Email
  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Não pode ser nullo.';
    }
    final trimmed = value.trim();
    if (trimmed.length > 50) {
      return 'Máximo de 50 caracteres.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Informe um e-mail válido (ex: usuario@email.com).';
    }
    return null;
  }

  /// Validador de Senha para Login (aceita qualquer senha preenchida)
  String? _validarSenhaLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Não pode ser nullo.';
    }
    return null;
  }

  /// Validador de Senha para Cadastro (valida exigências do backend)
  String? _validarSenhaCadastro(String? value) {
    if (value == null || value.isEmpty) {
      return 'Não pode ser nullo.';
    }
    if (value.length > 12) {
      return 'Máximo de 12 caracteres.';
    }
    if (!_hasLetter.hasMatch(value) ||
        !_hasDigit.hasMatch(value) ||
        !_hasSpecialChar.hasMatch(value)) {
      return 'A senha não atende a todas as exigências.';
    }
    return null;
  }

  /// Validador de Nome para Cadastro (max 50)
  String? _validarNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Não pode ser nullo.';
    }
    if (value.trim().length > 50) {
      return 'Máximo de 50 caracteres.';
    }
    return null;
  }

  Future<void> _efetuarLogin() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    final email = _loginEmailController.text.trim();
    final senha = _loginSenhaController.text;

    final sucesso = await authProvider.login(email, senha);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bem-vindo(a), ${authProvider.userName ?? email}!'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final msg = authProvider.errorMessage ?? 'Erro ao efetuar login.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _efetuarCadastro() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    if (!_cadastroFormKey.currentState!.validate()) {
      return;
    }

    final nome = _cadastroNomeController.text.trim();
    final email = _cadastroEmailController.text.trim();
    final senha = _cadastroSenhaController.text;
    final role = _selectedRole;

    final sucesso = await authProvider.cadastrar(
      nome: nome,
      email: email,
      senha: senha,
      role: role,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cadastro realizado com sucesso! Efetuando login...'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );

      final loginSucesso = await authProvider.login(email, senha);
      if (mounted && loginSucesso) {
        Navigator.of(context).pop();
      } else if (mounted) {
        _tabController.animateTo(0);
        _loginEmailController.text = email;
      }
    } else {
      final msg = authProvider.errorMessage ?? 'Erro ao realizar cadastro.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Widget de Lista com Check para as exigências da senha (exibido apenas no cadastro)
  Widget _buildPasswordChecklist({required String senha}) {
    final hasLength = senha.isNotEmpty && senha.length <= 12;
    final hasLetter = _hasLetter.hasMatch(senha);
    final hasDigit = _hasDigit.hasMatch(senha);
    final hasSpecial = _hasSpecialChar.hasMatch(senha);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amber.shade700.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exigências da Senha:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _buildCheckItem('Até 12 caracteres', hasLength),
          _buildCheckItem('Contém ao menos uma letra', hasLetter),
          _buildCheckItem('Contém ao menos um número', hasDigit),
          _buildCheckItem('Contém ao menos um caractere especial (!@#\$...)', hasSpecial),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool satisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: satisfied ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: satisfied ? Colors.green : Colors.grey.shade400,
                fontWeight: satisfied ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFFFD700);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Autenticação',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: goldColor,
          labelColor: goldColor,
          unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          tabs: const [
            Tab(icon: Icon(Icons.login), text: 'Entrar'),
            Tab(icon: Icon(Icons.person_add_alt_1), text: 'Cadastrar'),
          ],
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return TabBarView(
              controller: _tabController,
              children: [
                // ABA 1: LOGIN (Sem box de exigência de senha)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: goldColor.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              size: 36,
                              color: goldColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Acesse sua conta',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Campo Email
                        TextFormField(
                          controller: _loginEmailController,
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 50,
                          decoration: InputDecoration(
                            labelText: 'E-mail *',
                            hintText: 'exemplo@batuque.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: _validarEmail,
                        ),
                        const SizedBox(height: 16),

                        // Campo Senha (aceita qualquer valor preenchido)
                        TextFormField(
                          controller: _loginSenhaController,
                          obscureText: _loginObscureSenha,
                          decoration: InputDecoration(
                            labelText: 'Senha *',
                            prefixIcon: const Icon(Icons.lock_clock_outlined),
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _loginObscureSenha
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _loginObscureSenha = !_loginObscureSenha;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: _validarSenhaLogin,
                        ),
                        const SizedBox(height: 24),

                        // Botão Entrar
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldColor,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: authProvider.isLoading ? null : _efetuarLogin,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Text(
                                    'ENTRAR',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ABA 2: CADASTRO (Com box de exigência de senha)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _cadastroFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: goldColor.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 36,
                              color: goldColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Criar nova conta',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Campo Nome
                        TextFormField(
                          controller: _cadastroNomeController,
                          maxLength: 50,
                          decoration: InputDecoration(
                            labelText: 'Nome *',
                            hintText: 'Seu nome completo',
                            prefixIcon: const Icon(Icons.person_outline),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: _validarNome,
                        ),
                        const SizedBox(height: 16),

                        // Campo Email
                        TextFormField(
                          controller: _cadastroEmailController,
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 50,
                          decoration: InputDecoration(
                            labelText: 'E-mail *',
                            hintText: 'exemplo@batuque.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: _validarEmail,
                        ),
                        const SizedBox(height: 16),

                        // Campo Senha
                        TextFormField(
                          controller: _cadastroSenhaController,
                          obscureText: _cadastroObscureSenha,
                          maxLength: 12,
                          decoration: InputDecoration(
                            labelText: 'Senha *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _cadastroObscureSenha
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _cadastroObscureSenha =
                                      !_cadastroObscureSenha;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: _validarSenhaCadastro,
                        ),

                        // Lista com Check para as exigências da senha (Apenas no Cadastro)
                        _buildPasswordChecklist(
                          senha: _cadastroSenhaController.text,
                        ),
                        const SizedBox(height: 16),

                        // Campo Role (sem informações em parênteses)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Perfil (Role) *',
                            prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'USUARIO',
                              child: Text('Usuário Comum'),
                            ),
                            DropdownMenuItem(
                              value: 'FILHO',
                              child: Text('Filho de Santo'),
                            ),
                            DropdownMenuItem(
                              value: 'ADM',
                              child: Text('Administrador'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRole = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Botão Cadastrar
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldColor,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: authProvider.isLoading ? null : _efetuarCadastro,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Text(
                                    'CADASTRAR',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
