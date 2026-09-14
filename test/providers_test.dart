import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:batuque/models/entidade.dart';
import 'package:batuque/models/ponto_cantado.dart';
import 'package:batuque/models/ponto_item.dart';
import 'package:batuque/models/playlist.dart';
import 'package:batuque/providers/entidades_provider.dart';
import 'package:batuque/providers/pontos_provider.dart';
import 'package:batuque/providers/playlists_provider.dart';
import 'package:batuque/providers/audio_player_provider.dart';
import 'package:batuque/services/api_config.dart';

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
    ApiConfig.enableMockFallback = true;
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

      await provider.carregarEntidades();

      expect(provider.isLoading, isFalse);
      expect(provider.entidades, isNotEmpty);
      expect(provider.errorMessage, null);
    });

    test('filtrarEntidades busca corretamente', () async {
      await provider.carregarEntidades();
      final totalInicial = provider.entidades.length;

      await provider.filtrarEntidades('Pena');
      expect(provider.entidades.length, lessThan(totalInicial));
      expect(provider.entidades.first.nomeEntidade, contains('Pena Branca'));
    });

    test('cadastrar, atualizar e deletar Entidade no Provider', () async {
      await provider.carregarEntidades();
      final countInicial = provider.entidades.length;

      final nova = Entidade(
        nomeEntidade: 'Caboclo Sete Flechas',
        falange: 'Caboclos',
        linhaEntidade: 'Oxóssi',
      );

      final sucessoCad = await provider.cadastrarEntidade(nova);
      expect(sucessoCad, isTrue);
      expect(provider.entidades.length, equals(countInicial + 1));

      final id = provider.entidades.last.id!;
      final sucessoAlt = await provider.atualizarEntidade(
        id,
        nova.copyWith(nomeEntidade: 'Caboclo Sete Flechas da Jurema'),
      );
      expect(sucessoAlt, isTrue);
      expect(provider.entidades.last.nomeEntidade, 'Caboclo Sete Flechas da Jurema');

      final sucessoDel = await provider.deletarEntidade(id);
      expect(sucessoDel, isTrue);
      expect(provider.entidades.length, equals(countInicial));
    });
  });

  group('PontosProvider Testes', () {
    late PontosProvider provider;

    setUp(() {
      provider = PontosProvider();
    });

    test('carregarPontos e filtrarPontos', () async {
      await provider.carregarPontos();
      expect(provider.pontos, isNotEmpty);

      await provider.filtrarPontos(termo: 'Cativeiro');
      expect(provider.pontos.length, equals(1));
      expect(provider.pontos.first.nomePonto, contains('Cativeiro'));

      await provider.limparFiltros();
      expect(provider.pontos.length, greaterThan(1));
    });

    test('cadastrar, atualizar e deletar PontoCantado no Provider', () async {
      await provider.carregarPontos();
      final countInicial = provider.pontos.length;

      final novo = PontoCantado(
        nomePonto: 'Ponto de Xangô',
        pontoLetra: 'Kao Kabecile...',
        audioUrl: 'https://example.com/xango.mp3',
        entidadeId: 1,
      );

      final sucessoCad = await provider.cadastrarPonto(novo);
      expect(sucessoCad, isTrue);
      expect(provider.pontos.length, equals(countInicial + 1));

      final id = provider.pontos.last.id!;
      final sucessoAlt = await provider.atualizarPonto(
        id,
        novo.copyWith(nomePonto: 'Ponto de Xangô Agandju'),
      );
      expect(sucessoAlt, isTrue);

      final sucessoDel = await provider.deletarPonto(id);
      expect(sucessoDel, isTrue);
      expect(provider.pontos.length, equals(countInicial));
    });
  });

  group('PlaylistsProvider Testes', () {
    late PlaylistsProvider provider;

    setUp(() {
      provider = PlaylistsProvider();
    });

    test('carregarPlaylists e reordenarPontosLocais', () async {
      await provider.carregarPlaylists();
      expect(provider.playlists, isNotEmpty);

      final playlistId = provider.playlists.first.id!;
      final totalPontos = provider.playlists.first.pontos.length;

      if (totalPontos >= 2) {
        final primeiroPontoAntes = provider.playlists.first.pontos[0].ponto.nomePonto;
        final segundoPontoAntes = provider.playlists.first.pontos[1].ponto.nomePonto;

        provider.reordenarPontosLocais(playlistId, 0, 2);

        expect(provider.playlists.first.pontos[0].ponto.nomePonto, segundoPontoAntes);
        expect(provider.playlists.first.pontos[1].ponto.nomePonto, primeiroPontoAntes);
        expect(provider.playlists.first.pontos[0].ordem, equals(1));
        expect(provider.playlists.first.pontos[1].ordem, equals(2));
      }
    });

    test('adicionarPontoAPlaylist e removerPontoDaPlaylist', () async {
      await provider.carregarPlaylists();
      final playlistId = provider.playlists.first.id!;
      final countAntes = provider.playlists.first.pontos.length;

      final novoPonto = PontoCantado(
        id: 99,
        nomePonto: 'Ponto Novo',
        pontoLetra: 'Letra...',
        audioUrl: 'https://example.com/audio.mp3',
      );

      provider.adicionarPontoAPlaylist(playlistId, novoPonto);
      expect(provider.playlists.first.pontos.length, equals(countAntes + 1));
      expect(provider.playlists.first.pontos.last.ordem, equals(countAntes + 1));

      provider.removerPontoCantadoDaPlaylist(playlistId, 99);
      expect(provider.playlists.first.pontos.length, equals(countAntes));
    });

    test('cadastrar, salvar e deletar Playlist', () async {
      await provider.carregarPlaylists();
      final countInicial = provider.playlists.length;

      final nova = Playlist(nomePlaylist: 'Gira de Ogum');
      final sucessoCad = await provider.cadastrarPlaylist(nova);
      expect(sucessoCad, isTrue);

      final playlistId = provider.playlists.last.id!;
      final sucessoSalvar = await provider.salvarPlaylist(playlistId);
      expect(sucessoSalvar, isTrue);

      final sucessoDel = await provider.deletarPlaylist(playlistId);
      expect(sucessoDel, isTrue);
      expect(provider.playlists.length, equals(countInicial));
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
