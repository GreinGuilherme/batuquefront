import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/entidades_provider.dart';
import '../providers/pontos_provider.dart';
import '../providers/playlists_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
    _inicializarEIrParaHome();
  }

  Future<void> _inicializarEIrParaHome() async {
    // Garante que a animação e o carregamento durem pelo menos 2 segundos para boa UX
    final minTimer = Future.delayed(const Duration(seconds: 2));

    // Recarrega ou aguarda os providers carregarem os dados iniciais
    final entidadesFuture = context.read<EntidadesProvider>().carregarEntidades();
    final pontosFuture = context.read<PontosProvider>().carregarPontos();
    final playlistsFuture = context.read<PlaylistsProvider>().carregarPlaylists();

    await Future.wait([
      minTimer,
      entidadesFuture,
      pontosFuture,
      playlistsFuture,
    ]);

    if (!mounted) return;

    // Navega para a HomeScreen substituindo a rota atual
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF4E2C01); // Marrom escuro espiritual
    const goldColor = Color(0xFFFFD700); // Dourado brilhante
    const spiritualGold = Color(0xFF91720B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Logo do Aplicativo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withAlpha(51),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nome do App
                      Text(
                        'Batuque',
                        style: GoogleFonts.cinzel(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtítulo / Slogan
                      Text(
                        'Pontos Cantados e Espiritualidade',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFFF8F9FA).withAlpha(204),
                          letterSpacing: 0.5,
                        ),
                      ),

                      const Spacer(),

                      // Barra de Loading (Indicador de Progresso)
                      SizedBox(
                        width: 160,
                        child: Column(
                          children: [
                            const ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: Color(0xFF2A1700),
                                valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Carregando...',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: spiritualGold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
