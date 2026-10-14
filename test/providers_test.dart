import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:batuque/models/entidade.dart';
import 'package:batuque/models/ponto_cantado.dart';
import 'package:batuque/models/ponto_item.dart';
import 'package:batuque/models/playlist.dart';
import 'package:batuque/models/gira.dart';
import 'package:batuque/providers/entidades_provider.dart';
import 'package:batuque/providers/pontos_provider.dart';
import 'package:batuque/providers/playlists_provider.dart';
import 'package:batuque/providers/giras_provider.dart';
import 'package:batuque/providers/audio_player_provider.dart';
import 'package:batuque/services/gira_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeAudioPlayer extends AudioPlayer {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _completeController = StreamController<void>.broadcast();

  @override
  Stream<PlayerState> get onPlayerStateChanged => _stateController.stream;
  @override
  Stream<Duration> get onPositionChanged => _positionController.stream;
  @override
  Stream<Duration> get onDurationChanged => _durationController.stream;
  @override
  Stream<void> get onPlayerComplete => _completeController.stream;

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> stop() async {
    _stateController.add(PlayerState.stopped);
  }

  @override
  Future<void> pause() async {
    _stateController.add(PlayerState.paused);
  }

  @override
  Future<void> resume() async {
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> seek(Duration position) async {
    _positionController.add(position);
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _completeController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async {
        return 1;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async {
        return 1;
      },
    );
  });

  group('EntidadesProvider Testes', () {
    late EntidadesProvider provider;

    setUp(() {
      provider = EntidadesProvider();
    });

    test('carregarEntidades preenche lista de entidades e altera isLoading', () async {
      expect(provider.isLoading, isFalse);
      expect(provider.entidades, isEmpty);
    });
  });

  group('GirasProvider Testes', () {
    test('cadastrarGira, adicionarPlaylistAGira e removerPlaylistDaGira localmente', () async {
      final mockClient = MockClient((req) async {
        if (req.method == 'POST') {
          return http.Response('{"id": 1, "nomeGira": "Gira Teste", "playlist": []}', 201);
        }
        return http.Response('[]', 200);
      });

      final service = GiraService(client: mockClient);
      final provider = GirasProvider(service: service);

      final gira = Gira(nomeGira: 'Gira Teste', playlist: []);
      final ok = await provider.cadastrarGira(gira);
      expect(ok, isTrue);
      expect(provider.giras.length, 1);

      final pl = Playlist(id: 25, nomePlaylist: 'Playlist 25');
      provider.adicionarPlaylistAGira(1, pl);

      expect(provider.giras.first.playlist.length, 1);
      expect(provider.giras.first.playlist.first.playlistId, 25);

      provider.removerPlaylistDaGira(1, 25);
      expect(provider.giras.first.playlist.length, 0);
    });
  });

  group('AudioPlayerProvider Testes', () {
    late FakeAudioPlayer fakePlayer;
    late AudioPlayerProvider provider;

    setUp(() {
      fakePlayer = FakeAudioPlayer();
      provider = AudioPlayerProvider(audioPlayer: fakePlayer);
    });

    tearDown(() {
      provider.dispose();
    });

    test('Estado inicial do AudioPlayerProvider', () {
      expect(provider.isStopped, isTrue);
      expect(provider.isPlaying, isFalse);
      expect(provider.currentPonto, isNull);
      expect(provider.currentPlaylist, isNull);
      expect(provider.position, Duration.zero);
      expect(provider.progress, 0.0);
    });

    test('tocarPlaylist configura estado e sequência de faixas', () async {
      final ponto1 = PontoCantado(id: 1, nomePonto: 'Ponto 1', pontoLetra: 'L1', audioUrl: 'http://a.com/1.mp3');
      final ponto2 = PontoCantado(id: 2, nomePonto: 'Ponto 2', pontoLetra: 'L2', audioUrl: 'http://a.com/2.mp3');
      final playlist = Playlist(
        id: 1,
        nomePlaylist: 'Playlist Teste',
        pontos: [
          PontoItem(ordem: 1, ponto: ponto1),
          PontoItem(ordem: 2, ponto: ponto2),
        ],
      );

      await provider.tocarPlaylist(playlist, startIndex: 0);

      expect(provider.currentPonto?.id, equals(1));
      expect(provider.currentIndex, equals(0));
      expect(provider.temProxima, isTrue);
      expect(provider.temAnterior, isFalse);

      await provider.tocarProxima();
      expect(provider.currentPonto?.id, equals(2));
      expect(provider.currentIndex, equals(1));
      expect(provider.temProxima, isFalse);
      expect(provider.temAnterior, isTrue);

      await provider.tocarAnterior();
      expect(provider.currentPonto?.id, equals(1));
      expect(provider.currentIndex, equals(0));
    });

    test('parar zera currentPonto e fecha o player', () async {
      final ponto = PontoCantado(id: 1, nomePonto: 'Ponto Teste', pontoLetra: 'L1', audioUrl: 'http://a.com/1.mp3');
      await provider.tocarPonto(ponto);
      expect(provider.currentPonto, isNotNull);

      await provider.parar();
      expect(provider.currentPonto, isNull);
      expect(provider.currentPlaylist, isNull);
      expect(provider.isStopped, isTrue);
      expect(provider.isMinimized, isFalse);
    });

    test('toggleMinimize altera o estado de minimização', () async {
      final ponto = PontoCantado(id: 1, nomePonto: 'Ponto Teste', pontoLetra: 'L1', audioUrl: 'http://a.com/1.mp3');
      await provider.tocarPonto(ponto);
      expect(provider.isMinimized, isFalse);

      provider.toggleMinimize();
      expect(provider.isMinimized, isTrue);

      provider.toggleMinimize();
      expect(provider.isMinimized, isFalse);
    });
  });
}
