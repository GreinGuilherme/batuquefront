import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/entidades_provider.dart';
import '../providers/pontos_provider.dart';
import '../providers/playlists_provider.dart';
import '../providers/giras_provider.dart';
import '../services/stomp_service.dart';
import '../widgets/audio_player_bottom_bar.dart';
import 'entidades_screen.dart';
import 'pontos_screen.dart';
import 'playlists_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isMenuExtended = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        StompService.connect(
          entidadesProvider: context.read<EntidadesProvider>(),
          pontosProvider: context.read<PontosProvider>(),
          playlistsProvider: context.read<PlaylistsProvider>(),
          girasProvider: context.read<GirasProvider>(),
          token: auth.token,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      drawer: Drawer(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFFFD700),
                        child: Icon(Icons.person, size: 36, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        auth.isLoggedIn 
                            ? (auth.userName ?? auth.userEmail?.split('@').first ?? 'Usuário') 
                            : 'Visitante',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (auth.isLoggedIn && auth.userEmail != null)
                        Text(
                          auth.userEmail!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Conta'),
                  onTap: () {
                    Navigator.pop(context); // Fechar drawer
                    if (auth.isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Calendário'),
                  onTap: () {
                    Navigator.pop(context); // Fechar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        leadingWidth: 140,
        leading: Builder(
          builder: (context) {
            return Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final displayName = auth.isLoggedIn 
                    ? (auth.userName ?? auth.userEmail?.split('@').first ?? 'Usuário')
                    : 'Menu';
                    
                return InkWell(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu, size: 24, color: Color(0xFFFFD700)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
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
      body: Row(
        children: [
          Material(
            color: Theme.of(context).navigationRailTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Expanded(
                  child: NavigationRail(
                    extended: _isMenuExtended,
                    selectedIndex: _currentIndex,
                    groupAlignment: -1.0,
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
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline_rounded, size: 20),
                        selectedIcon: Icon(Icons.person_rounded, size: 20),
                        label: Text('Entidades'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.music_note_outlined, size: 20),
                        selectedIcon: Icon(Icons.music_note_rounded, size: 20),
                        label: Text('Pontos'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.queue_music_outlined, size: 20),
                        selectedIcon: Icon(Icons.queue_music_rounded, size: 20),
                        label: Text('Playlists'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                  child: IconButton(
                    icon: Icon(_isMenuExtended ? Icons.chevron_left : Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _isMenuExtended = !_isMenuExtended;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                const EntidadesScreen(),
                const PontosScreen(),
                PlaylistsScreen(parentPageController: _pageController),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AudioPlayerBottomBar(useBottomInset: false),
    );
  }
}
