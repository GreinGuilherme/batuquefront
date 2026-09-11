import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/entidades_provider.dart';
import 'providers/pontos_provider.dart';
import 'providers/playlists_provider.dart';
import 'providers/audio_player_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const BatuqueApp());
}

class BatuqueApp extends StatelessWidget {
  const BatuqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EntidadesProvider()),
        ChangeNotifierProvider(create: (_) => PontosProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistsProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Batuque',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}