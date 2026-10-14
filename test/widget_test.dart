import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:batuque/main.dart';
import 'package:batuque/models/entidade.dart';
import 'package:batuque/models/ponto_cantado.dart';
import 'package:batuque/providers/auth_provider.dart';
import 'package:batuque/providers/audio_player_provider.dart';
import 'package:batuque/providers/entidades_provider.dart';
import 'package:batuque/providers/pontos_provider.dart';
import 'package:batuque/providers/playlists_provider.dart';
import 'package:batuque/providers/giras_provider.dart';
import 'package:batuque/screens/ponto_detail_screen.dart';
import 'package:batuque/widgets/entidade_card.dart';
import 'package:batuque/widgets/ponto_card.dart';
import 'package:batuque/widgets/audio_player_bottom_bar.dart';

import 'package:shared_preferences/shared_preferences.dart';

class FakePontosProvider extends PontosProvider {
  @override
  Future<bool> atualizarPonto(int id, PontoCantado ponto) async {
    return true;
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('BatuqueApp renders home page and tabs correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BatuqueApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    // Verify AppBar title
    expect(find.text('Batuque'), findsOneWidget);

    // Verify NavigationBar destinations
    expect(find.text('Entidades'), findsOneWidget);
    expect(find.text('Pontos'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);

    // Tap on 'Pontos' tab
    await tester.tap(find.text('Pontos'));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap on 'Playlists' tab
    await tester.tap(find.text('Playlists'));
    await tester.pump(const Duration(milliseconds: 500));
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
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => EntidadesProvider()),
          ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
          ChangeNotifierProvider(create: (_) => PontosProvider()),
          ChangeNotifierProvider(create: (_) => PlaylistsProvider()),
          ChangeNotifierProvider(create: (_) => GirasProvider()),
        ],
        child: MaterialApp(
          home: PontoDetailScreen(ponto: ponto),
        ),
      ),
    );

    expect(find.text('Ponto de Caboclo'), findsWidgets); // AppBar and Header Card
    expect(find.text('Okê Caboclo...'), findsOneWidget);
  });

  testWidgets('PontoDetailScreen returns to source screen when editing and returnToSourceOnSave is true', (WidgetTester tester) async {
    final ponto = PontoCantado(
      id: 1,
      nomePonto: 'Ponto Origem',
      pontoLetra: 'Letra Origem',
      audioUrl: '',
    );

    bool? returnedResult;

    final fakePontosProvider = FakePontosProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => EntidadesProvider()),
          ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
          ChangeNotifierProvider<PontosProvider>.value(value: fakePontosProvider),
          ChangeNotifierProvider(create: (_) => PlaylistsProvider()),
          ChangeNotifierProvider(create: (_) => GirasProvider()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedResult = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => PontoDetailScreen(
                        ponto: ponto,
                        startInEditMode: true,
                        returnToSourceOnSave: true,
                      ),
                    ),
                  );
                },
                child: const Text('Abrir Edição'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Edição'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Ponto'), findsOneWidget);

    // Tap Save icon button
    await tester.tap(find.byTooltip('Salvar'));
    await tester.pumpAndSettle();

    expect(returnedResult, isTrue);
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
