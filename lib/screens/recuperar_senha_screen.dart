import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  final String? emailInicial;

  const RecuperarSenhaScreen({
    super.key,
    this.emailInicial,
  });

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _emailController;
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // Estados de controle
  bool _codigoEnviado = false;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;

  // Regex para validação de Email
  final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // Regex para validação da nova senha (deve conter letras, números e caractere especial, max 12)
  final _hasLetter = RegExp(r'[a-zA-Z]');
  final _hasDigit = RegExp(r'\d');
  final _hasSpecialChar =
      RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?~`]');

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.emailInicial ?? '');

    // Ouvinte para atualizar a lista de checagem da senha em tempo real
    _novaSenhaController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  /// Validador de Email
  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Não pode ser nulo.';
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

  /// Validador de Código OTP
  String? _validarCodigo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o código de 6 dígitos.';
    }
    if (value.trim().length != 6) {
      return 'O código deve possuir exatamente 6 dígitos.';
    }
    return null;
  }

  /// Validador de Nova Senha (valida exigências idênticas ao cadastro)
  String? _validarNovaSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Não pode ser nulo.';
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

  /// Validador de Confirmação de Senha
  String? _validarConfirmacaoSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a nova senha.';
    }
    if (value != _novaSenhaController.text) {
      return 'As senhas não coincidem.';
    }
    return null;
  }

  /// Widget de Lista com Check para as exigências da senha
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

  /// Etapa 1: Solicitar Envio do Código
  Future<void> _solicitarCodigo() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final mensagem = await authProvider.solicitarCodigoRecuperacao(email);

    if (!mounted) return;

    if (mensagem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      setState(() {
        _codigoEnviado = true;
      });
    } else {
      final msg =
          authProvider.errorMessage ?? 'Erro ao enviar código de recuperação.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Etapa 2: Redefinir Senha com Código OTP
  Future<void> _redefinirSenha() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final codigo = _codigoController.text.trim();
    final novaSenha = _novaSenhaController.text;

    final mensagem = await authProvider.redefinirSenha(
      email: email,
      codigo: codigo,
      novaSenha: novaSenha,
    );

    if (!mounted) return;

    if (mensagem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      // Retorna para a tela de Login
      Navigator.of(context).pop();
    } else {
      final msg = authProvider.errorMessage ??
          'Erro ao redefinir senha. Verifique o código e tente novamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Reenviar código
  Future<void> _reenviarCodigo() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe um e-mail válido para reenviar.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final mensagem = await authProvider.solicitarCodigoRecuperacao(email);

    if (!mounted) return;

    if (mensagem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código reenviado! $mensagem'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final msg = authProvider.errorMessage ?? 'Erro ao reenviar código.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFFFD700);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recuperação de Senha',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: goldColor.withValues(alpha: 0.15),
                        child: Icon(
                          _codigoEnviado
                              ? Icons.mark_email_read_rounded
                              : Icons.lock_reset_rounded,
                          size: 40,
                          color: goldColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _codigoEnviado
                          ? 'Redefina sua Senha'
                          : 'Recuperar Acesso',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codigoEnviado
                          ? 'Digite o código de 6 dígitos recebido por e-mail e cadastre sua nova senha.'
                          : 'Informe seu e-mail cadastrado para receber um código de validação de 6 dígitos.\nVerifique seu e-mail e/ou caixa de spam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Transição Suave entre Etapa 1 e Etapa 2
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: !_codigoEnviado
                          ? _buildEtapa1(authProvider, goldColor)
                          : _buildEtapa2(authProvider, goldColor, theme),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Widget da Etapa 1: Solicitar Envio de Código
  Widget _buildEtapa1(AuthProvider authProvider, Color goldColor) {
    return Column(
      key: const ValueKey('etapa_1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          maxLength: 50,
          decoration: InputDecoration(
            labelText: 'E-mail cadastrado *',
            hintText: 'exemplo@batuque.com',
            prefixIcon: const Icon(Icons.email_outlined),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: _validarEmail,
        ),
        const SizedBox(height: 24),

        // Botão Enviar Código
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
            onPressed: authProvider.isLoading ? null : _solicitarCodigo,
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
                    'ENVIAR CÓDIGO',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Widget da Etapa 2: Código OTP + Nova Senha + Confirmação
  Widget _buildEtapa2(AuthProvider authProvider, Color goldColor, ThemeData theme) {
    return Column(
      key: const ValueKey('etapa_2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card de Aviso
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.amber.shade700.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: goldColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: goldColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Caso o e-mail esteja cadastrado, um código de 6 dígitos foi enviado para sua caixa de entrada.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.brightness == Brightness.dark
                        ? Colors.amber.shade100
                        : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Campo Email (Readonly com opção de alterar)
        TextFormField(
          controller: _emailController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'E-mail',
            prefixIcon: const Icon(Icons.email_outlined),
            suffixIcon: TextButton(
              onPressed: () {
                setState(() {
                  _codigoEnviado = false;
                });
              },
              child: Text(
                'Alterar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: goldColor,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Campo Código de 6 Dígitos
        TextFormField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Código de 6 dígitos *',
            hintText: '123456',
            prefixIcon: const Icon(Icons.pin_outlined),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: _validarCodigo,
        ),
        const SizedBox(height: 16),

        // Campo Nova Senha
        TextFormField(
          controller: _novaSenhaController,
          obscureText: _obscureNovaSenha,
          maxLength: 12,
          decoration: InputDecoration(
            labelText: 'Nova Senha *',
            prefixIcon: const Icon(Icons.lock_outline),
            counterText: '',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNovaSenha
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureNovaSenha = !_obscureNovaSenha;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: _validarNovaSenha,
        ),

        // Lista com Check para as exigências da senha (em tempo real)
        _buildPasswordChecklist(
          senha: _novaSenhaController.text,
        ),
        const SizedBox(height: 16),

        // Campo Confirmar Nova Senha
        TextFormField(
          controller: _confirmarSenhaController,
          obscureText: _obscureConfirmarSenha,
          decoration: InputDecoration(
            labelText: 'Confirmar Nova Senha *',
            prefixIcon: const Icon(Icons.lock_clock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmarSenha
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmarSenha = !_obscureConfirmarSenha;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: _validarConfirmacaoSenha,
        ),
        const SizedBox(height: 24),

        // Botão Redefinir Senha
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
            onPressed: authProvider.isLoading ? null : _redefinirSenha,
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
                    'REDEFINIR SENHA',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Botão Discreto: Reenviar Código
        Center(
          child: TextButton.icon(
            onPressed: authProvider.isLoading ? null : _reenviarCodigo,
            icon: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: goldColor,
            ),
            label: Text(
              'Não recebeu? Reenviar código',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: goldColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
