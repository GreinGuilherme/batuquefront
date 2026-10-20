import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/sync_event.dart';
import '../providers/entidades_provider.dart';
import '../providers/pontos_provider.dart';
import '../providers/playlists_provider.dart';
import '../providers/giras_provider.dart';

class StompService {
  static StompClient? _stompClient;

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WEBSOCKET] $message');
      developer.log(message, name: 'WebSocket');
    }
  }

  static void connect({
    required EntidadesProvider entidadesProvider,
    required PontosProvider pontosProvider,
    required PlaylistsProvider playlistsProvider,
    GirasProvider? girasProvider,
    String? token, // Opcional caso use autenticação no handshake
  }) {
    if (_stompClient != null) {
      _log('⚠️ StompClient já está conectado ou inicializado.');
      return;
    }

    _log('🔌 Conectando ao WebSocket STOMP em wss://batuque.duckdns.org/ws ...');

    _stompClient = StompClient(
      config: StompConfig(
        url: 'wss://batuque.duckdns.org/ws', // URL base definida
        onConnect: (StompFrame frame) {
          _log('✅ STOMP Conectado! Command: ${frame.command}');

          // Inscreve no tópico de Entidades
          _stompClient?.subscribe(
            destination: '/topic/entidade',
            callback: (StompFrame frame) {
              _log('📥 [STOMP /topic/entidade] JSON Recebido:\n${frame.body}');
              if (frame.body != null) {
                try {
                  final json = jsonDecode(frame.body!);
                  final event = SyncEvent.fromJson(json);
                  _log('🔄 SyncEvent Entidade: acao="${event.acao}", dados=${event.dados}');
                  entidadesProvider.sincronizar(event);
                } catch (e, stack) {
                  _log('❌ Erro ao decodificar SyncEvent de Entidade: $e\n$stack');
                }
              }
            },
          );

          // Inscreve no tópico de Pontos
          _stompClient?.subscribe(
            destination: '/topic/ponto',
            callback: (StompFrame frame) {
              _log('📥 [STOMP /topic/ponto] JSON Recebido:\n${frame.body}');
              if (frame.body != null) {
                try {
                  final json = jsonDecode(frame.body!);
                  final event = SyncEvent.fromJson(json);
                  _log('🔄 SyncEvent Ponto: acao="${event.acao}", dados=${event.dados}');
                  pontosProvider.sincronizar(event);
                } catch (e, stack) {
                  _log('❌ Erro ao decodificar SyncEvent de Ponto: $e\n$stack');
                }
              }
            },
          );

          // Inscreve no tópico de Playlists
          _stompClient?.subscribe(
            destination: '/topic/playlist',
            callback: (StompFrame frame) {
              _log('📥 [STOMP /topic/playlist] JSON Recebido:\n${frame.body}');
              if (frame.body != null) {
                try {
                  final json = jsonDecode(frame.body!);
                  final event = SyncEvent.fromJson(json);
                  _log('🔄 SyncEvent Playlist: acao="${event.acao}", dados=${event.dados}');
                  playlistsProvider.sincronizar(event);
                } catch (e, stack) {
                  _log('❌ Erro ao decodificar SyncEvent de Playlist: $e\n$stack');
                }
              }
            },
          );

          // Inscreve no tópico de Giras
          if (girasProvider != null) {
            _stompClient?.subscribe(
              destination: '/topic/gira',
              callback: (StompFrame frame) {
                _log('📥 [STOMP /topic/gira] JSON Recebido:\n${frame.body}');
                if (frame.body != null) {
                  try {
                    final json = jsonDecode(frame.body!);
                    final event = SyncEvent.fromJson(json);
                    _log('🔄 SyncEvent Gira: acao="${event.acao}", dados=${event.dados}');
                    girasProvider.sincronizar(event);
                  } catch (e, stack) {
                    _log('❌ Erro ao decodificar SyncEvent de Gira: $e\n$stack');
                  }
                }
              },
            );
          }
        },
        onDisconnect: (StompFrame frame) {
          _log('🛑 STOMP Desconectado.');
        },
        onWebSocketError: (dynamic error) => _log('❌ Erro WS: $error'),
        onStompError: (StompFrame frame) => _log('❌ Erro STOMP Frame: ${frame.body}'),
        // Funciona perfeitamente no Android/iOS (Conexão nativa)
        webSocketConnectHeaders: {
          'X-App-Batuque': 'GiraSegura2026',
          'User-Agent': 'BatuqueFlutterApp/1.0 (Android; iOS)',
        },
        // Como navegadores bloqueiam headers customizados no WebSocket HTTP,
        // enviamos os mesmos dados como Headers do STOMP (que a Web permite!)
        stompConnectHeaders: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          'X-App-Batuque': 'GiraSegura2026',
          'User-Agent': 'BatuqueFlutterApp/1.0 (Web; STOMP)',
        },
      ),
    );

    _stompClient?.activate();
  }

  static void disconnect() {
    _log('🔌 Desconectando WebSocket...');
    _stompClient?.deactivate();
    _stompClient = null;
  }
}
