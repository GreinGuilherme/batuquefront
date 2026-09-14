import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:batuque/main.dart';
import 'package:batuque/models/entidade.dart';
import 'package:batuque/models/ponto_cantado.dart';
import 'package:batuque/providers/audio_player_provider.dart';
import 'package:batuque/providers/entidades_provider.dart';
import 'package:batuque/providers/pontos_provider.dart';
import 'package:batuque/screens/ponto_detail_screen.dart';
import 'package:batuque/widgets/entidade_card.dart';
import 'package:batuque/widgets/ponto_card.dart';
import 'package:batuque/widgets/audio_player_bottom_bar.dart';

void main() {
  testWidgets('BatuqueApp renders home page and tabs correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BatuqueApp());
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Batuque'), findsOneWidget);

    // Verify NavigationBar destinations
    expect(find.text('Entidades'), findsOneWidget);
    expect(find.text('Pontos'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);

    // Tap on 'Pontos' tab
    await tester.tap(find.text('Pontos'));
    await tester.pumpAndSettle();

    // Tap on 'Playlists' tab
    await tester.tap(find.text('Playlists'));
    await tester.pumpAndSettle();
  });

  testWidgets('EntidadeCard renders entity details', (WidgetTester tester) async {
    final entidade = Entidade(
      id: 1,
      nomeEntidade: 'Caboclo Pena Branca',
      falange: 'Caboclos',
      linhaEntidade: 'Oxóssi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntidadeCard(entidade: entidade),
        ),
      ),
    );

    expect(find.text('Caboclo Pena Branca'), findsOneWidget);
    expect(find.text('Caboclos'), findsOneWidget);
    expect(find.text('Linha: Oxóssi'), findsOneWidget);
  });

  testWidgets('PontoCard renders ponto details and responds to play tap', (WidgetTester tester) async {
    bool playTapped = false;

    final ponto = PontoCantado(
      id: 1,
      nomePonto: 'Hino da Umbanda',
      pontoLetra: 'Refletiu a luz divina...',
      audioUrl: 'https://example.com/hino.mp3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PontoCard(
            ponto: ponto,
            nomeEntidadeOverride: 'Linha Geral',
            onPlayTap: () {
              playTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Hino da Umbanda'), findsOneWidget);
    expect(find.text('Linha Geral'), findsOneWidget);

    await tester.tap(find.byType(IconButton).first);
    expect(playTapped, isTrue);
  });

  testWidgets('PontoDetailScreen renders ponto details and screen awake indicator', (WidgetTester tester) async {
    final ponto = PontoCantado(
      id: 1,
      nomePonto: 'Ponto de Caboclo',
      pontoLetra: 'Okê Caboclo...',
      audioUrl: 'https://example.com/caboclo.mp3',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => EntidadesProvider()),
          ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
          ChangeNotifierProvider(create: (_) => PontosProvider()),
        ],
        child: MaterialApp(
          home: PontoDetailScreen(ponto: ponto),
        ),
      ),
    );

    expect(find.text('Ponto de Caboclo'), findsNWidgets(2)); // AppBar and Header Card
    expect(find.text('Okê Caboclo...'), findsOneWidget);
    expect(find.text('Tela mantida acesa'), findsOneWidget);
  });

  testWidgets('AudioPlayerBottomBar renders playing ponto details', (WidgetTester tester) async {
    final audioProvider = AudioPlayerProvider();
    final ponto = PontoCantado(
      id: 1,
      nomePonto: 'Ponto Teste',
      pontoLetra: 'Letra Teste',
      audioUrl: 'https://example.com/teste.mp3',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerProvider>.value(value: audioProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AudioPlayerBottomBar(),
          ),
        ),
      ),
    );

    // Initially bottom bar is empty when no ponto is active
    expect(find.text('Ponto Teste'), findsNothing);

    // Set active ponto
    audioProvider.tocarPonto(ponto);
    await tester.pump();

    expect(find.text('Ponto Teste'), findsOneWidget);

    // Minimize player
    await tester.tap(find.byTooltip('Minimizar player'));
    await tester.pump();
    expect(audioProvider.isMinimized, isTrue);
    expect(find.byTooltip('Expandir player'), findsOneWidget);

    // Expand player
    await tester.tap(find.byTooltip('Expandir player'));
    await tester.pump();
    expect(audioProvider.isMinimized, isFalse);

    // Close player
    await tester.tap(find.byTooltip('Fechar player'));
    await tester.pumpAndSettle();
    expect(find.text('Ponto Teste'), findsNothing);
  });
}
