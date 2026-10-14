import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Um cliente HTTP customizado que adiciona logs detalhados de requisições
/// e respostas no console do Flutter durante o desenvolvimento (Debug mode).
class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();

    if (kDebugMode) {
      final reqLog = StringBuffer()
        ..writeln('🌐 [HTTP REQ] ${request.method} ${request.url}')
        ..writeln('Headers: ${request.headers}');

      if (request is http.Request && request.body.isNotEmpty) {
        reqLog.writeln('Body: ${request.body}');
      }

      final message = reqLog.toString().trim();
      debugPrint(message);
      developer.log(message, name: 'HTTP');
    }

    try {
      final response = await _inner.send(request);
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (kDebugMode) {
        final bytes = await response.stream.toBytes();
        String responseBody = '';
        try {
          responseBody = utf8.decode(bytes);
        } catch (_) {
          responseBody = '[Bytes de mídia ou não-UTF8 (${bytes.length} bytes)]';
        }

        final resLog = StringBuffer()
          ..writeln('🌐 [HTTP RES ${response.statusCode}] (${duration}ms) ${request.method} ${request.url}')
          ..writeln('Body: ${responseBody.length > 2000 ? '${responseBody.substring(0, 2000)}... (truncado)' : responseBody}');

        final message = resLog.toString().trim();
        debugPrint(message);
        developer.log(message, name: 'HTTP');

        return http.StreamedResponse(
          http.ByteStream.fromBytes(bytes),
          response.statusCode,
          contentLength: bytes.length,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }

      return response;
    } catch (e, stack) {
      if (kDebugMode) {
        final errMessage = '❌ [HTTP ERR] ${request.method} ${request.url} -> $e';
        debugPrint(errMessage);
        developer.log(errMessage, name: 'HTTP', error: e, stackTrace: stack);
      }
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
