import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/audio_player_bottom_bar.dart';
import 'entidades_screen.dart';
import 'pontos_screen.dart';
import 'playlists_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
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
