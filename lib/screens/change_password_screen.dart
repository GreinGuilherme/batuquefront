import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  
  bool _obscureSenhaAtual = true;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;
  bool _isLoading = false;

  // Regex para validação de senha (deve conter letras, números e caractere especial)
  final _hasLetter = RegExp(r'[a-zA-Z]');
  final _hasDigit = RegExp(r'\d');
  final _hasSpecialChar = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?~`]');

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  String? _validarSenhaCadastro(String? value) {
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

  Future<void> _alterarSenha() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('As novas senhas não coincidem.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulando uma requisição à API
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      // Como não temos o endpoint exato no backend mapeado ainda,
      // mostramos uma mensagem de sucesso simulada.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Senha alterada com sucesso!'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFFFD700);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alterar Senha',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Atualize sua senha de acesso',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Senha Atual
              TextFormField(
                controller: _senhaAtualController,
                obscureText: _obscureSenhaAtual,
                decoration: InputDecoration(
                  labelText: 'Senha Atual *',
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSenhaAtual ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureSenhaAtual = !_obscureSenhaAtual;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Informe a senha atual.';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Nova Senha
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
                      _obscureNovaSenha ? Icons.visibility_off : Icons.visibility,
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
                validator: _validarSenhaCadastro,
              ),
              const SizedBox(height: 16),

              // Confirmar Nova Senha
              TextFormField(
                controller: _confirmarSenhaController,
                obscureText: _obscureConfirmarSenha,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nova Senha *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmarSenha ? Icons.visibility_off : Icons.visibility,
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
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Confirme a nova senha.';
                  if (val != _novaSenhaController.text) return 'As senhas não coincidem.';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botão Salvar
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
                  onPressed: _isLoading ? null : _alterarSenha,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black87,
                          ),
                        )
                      : Text(
                          'ATUALIZAR SENHA',
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
    );
  }
}
