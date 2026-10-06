import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/sync_event.dart';
import '../providers/entidades_provider.dart';
import '../providers/pontos_provider.dart';
import '../providers/playlists_provider.dart';

class StompService {
  static StompClient? _stompClient;

  static void connect({
    required EntidadesProvider entidadesProvider,
    required PontosProvider pontosProvider,
    required PlaylistsProvider playlistsProvider,
    String? token, // Opcional caso use autenticação no handshake
  }) {
    if (_stompClient != null) return;

    _stompClient = StompClient(
      config: StompConfig(
        url: 'wss://batuque.duckdns.org/ws', // URL base definida
        onConnect: (StompFrame frame) {
          debugPrint('STOMP Conectado!');
          
          // Inscreve no tópico de Entidades
          _stompClient?.subscribe(
            destination: '/topic/entidade',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                try {
                  final json = jsonDecode(frame.body!);
                  final event = SyncEvent.fromJson(json);
                  entidadesProvider.sincronizar(event);
                } catch (e) {
                  debugPrint('Erro ao decodificar SyncEvent de Entidade: $e');
                }
              }
            },
          );

          // Inscreve no tópico de Pontos
          _stompClient?.subscribe(
            destination: '/topic/ponto',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                try {
                  final json = jsonDecode(frame.body!);
                  final event = SyncEvent.fromJson(json);
                  pontosProvider.sincronizar(event);
                } catch (e) {
                  debugPrint('Erro ao decodificar SyncEvent de Ponto: $e');
                }
              }
            },
          );

          // Inscreve no tópico de Playlists
          _stompClient?.subscribe(
            destination: '/topic/playlist',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                try {
                  final json = jsonDecode(frame.body!);
                  final event = SyncEvent.fromJson(json);
                  playlistsProvider.sincronizar(event);
                } catch (e) {
                  debugPrint('Erro ao decodificar SyncEvent de Playlist: $e');
                }
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => debugPrint('Erro no WebSocket: $error'),
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
      ),
    );

    _stompClient?.activate();
  }

  static void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
  }
}
