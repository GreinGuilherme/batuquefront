import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../models/ponto_cantado.dart';
import '../models/ponto_item.dart';
import '../models/playlist.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer;

  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration> _durationSub;
  late final StreamSubscription<void> _completeSub;

  PlayerState _playerState = PlayerState.stopped;
  PontoCantado? _currentPonto;
  PontoItem? _currentItem;
  Playlist? _currentPlaylist;
  int _currentIndex = -1;
  bool _isMinimized = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;

  AudioPlayerProvider({AudioPlayer? audioPlayer})
      : _audioPlayer = audioPlayer ?? AudioPlayer() {
    _initStreams();
  }

  void _initStreams() {
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      _onTrackCompleted();
    });
  }

  // Getters
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped;

  PontoCantado? get currentPonto => _currentPonto;
  PontoItem? get currentItem => _currentItem;
  Playlist? get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  bool get isMinimized => _isMinimized;

  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;

  double get progress {
    if (_duration.inMilliseconds > 0) {
      return _position.inMilliseconds / _duration.inMilliseconds;
    }
    return 0.0;
  }

  bool get temProxima =>
      _currentPlaylist != null &&
      _currentPlaylist!.pontos.isNotEmpty &&
      _currentIndex < _currentPlaylist!.pontos.length - 1;

  bool get temAnterior =>
      _currentPlaylist != null &&
      _currentPlaylist!.pontos.isNotEmpty &&
      _currentIndex > 0;

  void toggleMinimize() {
    _isMinimized = !_isMinimized;
    notifyListeners();
  }

  void setMinimized(bool value) {
    _isMinimized = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool _isYouTubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com/') || lower.contains('youtu.be/');
  }

  /// Toca um ponto isolado ou com contexto de playlist/índice
  Future<void> tocarPonto(
    PontoCantado ponto, {
    Playlist? playlist,
    int? index,
    PontoItem? item,
  }) async {
    try {
      _errorMessage = null;
      _currentPonto = ponto;
      _currentItem = item;
      _currentPlaylist = playlist;
      if (index != null) {
        _currentIndex = index;
      } else if (playlist != null) {
        _currentIndex = playlist.pontos.indexWhere((p) => p.ponto.id == ponto.id);
      } else {
        _currentIndex = -1;
      }

      _position = Duration.zero;
      _duration = Duration.zero;
      _isMinimized = false;
      _playerState = PlayerState.stopped;
      notifyListeners();

      await _audioPlayer.stop();

      final trimmedUrl = ponto.audioUrl.trim();
      if (trimmedUrl.isEmpty) {
        _errorMessage = 'URL de áudio inválida ou vazia.';
        notifyListeners();
        return;
      }

      String playUrl = trimmedUrl;
      if (_isYouTubeUrl(trimmedUrl)) {
        try {
          final yt = YoutubeExplode();
          final manifest = await yt.videos.streamsClient.getManifest(trimmedUrl);
          yt.close();
          final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
          playUrl = audioStreamInfo.url.toString();
        } catch (e) {
          _errorMessage = 'Não foi possível carregar o áudio do YouTube. Verifique o link ou a conexão.';
          _playerState = PlayerState.stopped;
          notifyListeners();
          return;
        }
      }

      await _audioPlayer.play(UrlSource(playUrl));
    } catch (e) {
      _errorMessage = 'Erro ao reproduzir áudio: $e';
      _playerState = PlayerState.stopped;
      notifyListeners();
    }
  }

  /// Inicia a reprodução sequencial de uma playlist
  Future<void> tocarPlaylist(Playlist playlist, {int startIndex = 0}) async {
    if (playlist.pontos.isEmpty) {
      _errorMessage = 'A playlist está vazia.';
      notifyListeners();
      return;
    }

    final validIndex = startIndex.clamp(0, playlist.pontos.length - 1);
    final item = playlist.pontos[validIndex];
    await tocarPonto(
      item.ponto,
      playlist: playlist,
      index: validIndex,
      item: item,
    );
  }

  /// Toca a próxima faixa da playlist
  Future<void> tocarProxima() async {
    if (temProxima) {
      final nextIndex = _currentIndex + 1;
      final item = _currentPlaylist!.pontos[nextIndex];
      await tocarPonto(
        item.ponto,
        playlist: _currentPlaylist,
        index: nextIndex,
        item: item,
      );
    } else {
      await parar();
    }
  }

  /// Toca a faixa anterior da playlist
  Future<void> tocarAnterior() async {
    if (temAnterior) {
      final prevIndex = _currentIndex - 1;
      final item = _currentPlaylist!.pontos[prevIndex];
      await tocarPonto(
        item.ponto,
        playlist: _currentPlaylist,
        index: prevIndex,
        item: item,
      );
    }
  }

  Future<void> pausar() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _errorMessage = 'Erro ao pausar: $e';
      notifyListeners();
    }
  }

  Future<void> retomar() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      _errorMessage = 'Erro ao retomar: $e';
      notifyListeners();
    }
  }

  Future<void> parar() async {
    _position = Duration.zero;
    _playerState = PlayerState.stopped;
    _currentPonto = null;
    _currentItem = null;
    _currentPlaylist = null;
    _currentIndex = -1;
    _isMinimized = false;
    notifyListeners();
    try {
      await _audioPlayer.stop();
    } catch (e) {
      _errorMessage = 'Erro ao parar: $e';
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _errorMessage = 'Erro ao buscar posição: $e';
      notifyListeners();
    }
  }

  void _onTrackCompleted() {
    if (_errorMessage != null || (_position == Duration.zero && _duration == Duration.zero)) {
      _playerState = PlayerState.stopped;
      notifyListeners();
      return;
    }

    if (temProxima) {
      tocarProxima();
    } else {
      _playerState = PlayerState.stopped;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _completeSub.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
