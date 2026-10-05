import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/audio_player_bottom_bar.dart';
import 'entidades_screen.dart';
import 'pontos_screen.dart';
import 'playlists_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = const [
    EntidadesScreen(),
    PontosScreen(),
    PlaylistsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _mostrarPerfilOuLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.account_circle, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('Perfil do Usuário'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person),
              title: const Text('Nome'),
              subtitle: Text(
                auth.userName ?? 'Não informado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email),
              title: const Text('E-mail'),
              subtitle: Text(
                auth.userEmail ?? 'Não informado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security),
              title: const Text('Perfil (Role)'),
              subtitle: Text(
                auth.userRole ?? 'USUARIO',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              await auth.logout();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Sessão encerrada com sucesso.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 140,
        leading: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoggedIn) {
              return InkWell(
                onTap: () => _mostrarPerfilOuLogoutDialog(context, auth),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFFFFD700),
                        child: Icon(Icons.person, size: 14, color: Colors.black87),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          auth.userName ?? auth.userEmail?.split('@').first ?? 'Usuário',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 18, color: Color(0xFFFFD700)),
                label: const Text(
                  'Entrar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              );
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 22),
            const SizedBox(width: 6),
            const Text('Batuque', style: TextStyle(fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            iconSize: 20,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AudioPlayerBottomBar(useBottomInset: false),
          NavigationBar(
            height: 52,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: 20),
                selectedIcon: Icon(Icons.person_rounded, size: 20),
                label: 'Entidades',
              ),
              NavigationDestination(
                icon: Icon(Icons.music_note_outlined, size: 20),
                selectedIcon: Icon(Icons.music_note_rounded, size: 20),
                label: 'Pontos',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_music_outlined, size: 20),
                selectedIcon: Icon(Icons.queue_music_rounded, size: 20),
                label: 'Playlists',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
