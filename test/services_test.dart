import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:batuque/models/entidade.dart';
import 'package:batuque/models/ponto_cantado.dart';
import 'package:batuque/models/ponto_item.dart';
import 'package:batuque/models/playlist.dart';
import 'package:batuque/services/entidade_service.dart';
import 'package:batuque/services/ponto_service.dart';
import 'package:batuque/services/playlist_service.dart';

void main() {
  group('EntidadeService Testes', () {
    late EntidadeService service;

    setUp(() {
      service = EntidadeService();
    });

    test('buscarEntidades retorna lista de entidades', () async {
      final entidades = await service.buscarEntidades();
      expect(entidades, isNotEmpty);
    });

    test('filtrarEntidades filtra por termo', () async {
      final filtradas = await service.filtrarEntidades('Pena');
      expect(filtradas.length, equals(1));
      expect(filtradas.first.nomeEntidade, contains('Pena Branca'));
    });

    test('cadastrar, atualizar e deletar Entidade', () async {
      final nova = Entidade(
        nomeEntidade: 'Caboclo Roxo',
        falange: 'Caboclos',
        linhaEntidade: 'Oxóssi',
      );

      final cadastrada = await service.cadastrarEntidade(nova);
      expect(cadastrada.id, isNotNull);
      expect(cadastrada.nomeEntidade, 'Caboclo Roxo');

      final paraAtualizar = cadastrada.copyWith(nomeEntidade: 'Caboclo Roxo do Mato');
      final atualizada = await service.atualizarEntidade(cadastrada.id!, paraAtualizar);
      expect(atualizada.nomeEntidade, 'Caboclo Roxo do Mato');

      await service.deletarEntidade(cadastrada.id!, nomeEntidade: cadastrada.nomeEntidade);
      final todas = await service.buscarEntidades();
      expect(todas.any((e) => e.id == cadastrada.id), isFalse);
    });

    test('deletarEntidade envia os parâmetros id e nomeEntidade na query string (/entidade/deletar?id=1&nomeEntidade=Caboclo)', () async {
      late String capturedMethod;
      late String capturedUrl;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();

        return http.Response('', 204);
      });

      final mockService = EntidadeService(client: client);
      await mockService.deletarEntidade(1, nomeEntidade: 'Caboclo Pena Branca');

      expect(capturedMethod, 'DELETE');
      expect(capturedUrl, contains('/entidade/deletar?id=1&nomeEntidade=Caboclo'));
    });
  });

  group('PontoService Testes', () {
    late PontoService service;

    setUp(() {
      service = PontoService();
    });

    test('buscarPontos retorna lista de pontos', () async {
      final pontos = await service.buscarPontos();
      expect(pontos, isNotEmpty);
    });

    test('filtrarPontos filtra por termo e entidadeId', () async {
      final filtrados = await service.filtrarPontos(termo: 'Oxóssi', entidadeId: 1);
      expect(filtrados, isNotEmpty);
      expect(filtrados.first.entidadeId, equals(1));
    });

    test('cadastrar, atualizar e deletar PontoCantado', () async {
      final novoPonto = PontoCantado(
        nomePonto: 'Ponto de Ogum',
        pontoLetra: 'Ogum yê...',
        audioUrl: 'https://example.com/ogum.mp3',
        entidadeId: 1,
      );

      final cadastrado = await service.cadastrarPonto(novoPonto);
      expect(cadastrado.id, isNotNull);
      expect(cadastrado.nomePonto, 'Ponto de Ogum');

      final paraAtualizar = cadastrado.copyWith(nomePonto: 'Ponto de Ogum Beira Mar');
      final atualizado = await service.atualizarPonto(cadastrado.id!, paraAtualizar);
      expect(atualizado.nomePonto, 'Ponto de Ogum Beira Mar');

      await service.deletarPonto(cadastrado.id!, nomePonto: cadastrado.nomePonto);
      final todos = await service.buscarPontos();
      expect(todos.any((p) => p.id == cadastrado.id), isFalse);
    });

    test('deletarPonto envia os parâmetros id e nomePonto na query string (/gestaopontos/deletar?id=10&nomePonto=Barulho no cemitério)', () async {
      late String capturedMethod;
      late String capturedUrl;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();

        return http.Response('', 204);
      });

      final mockService = PontoService(client: client);
      await mockService.deletarPonto(10, nomePonto: 'Barulho no cemitério');

      expect(capturedMethod, 'DELETE');
      expect(capturedUrl, contains('/gestaopontos/deletar?id=10&nomePonto=Barulho'));
    });
  });

  group('PlaylistService Testes', () {
    late PlaylistService service;

    setUp(() {
      service = PlaylistService();
    });

    test('buscarPlaylists retorna lista de playlists', () async {
      final playlists = await service.buscarPlaylists();
      expect(playlists, isNotEmpty);
    });

    test('filtrarPlaylists por termo', () async {
      final filtradas = await service.filtrarPlaylists('Abertura');
      expect(filtradas, isNotEmpty);
      expect(filtradas.first.nomePlaylist, contains('Abertura'));
    });

    test('cadastrar, atualizar (PUT) e deletar Playlist', () async {
      final novaPlaylist = Playlist(
        nomePlaylist: 'Gira de Iemanjá',
        pontos: [],
      );

      final cadastrada = await service.cadastrarPlaylist(novaPlaylist);
      expect(cadastrada.id, isNotNull);
      expect(cadastrada.nomePlaylist, 'Gira de Iemanjá');

      final paraAtualizar = cadastrada.copyWith(nomePlaylist: 'Gira de Iemanjá e Oxum');
      final atualizada = await service.atualizarPlaylist(cadastrada.id!, paraAtualizar);
      expect(atualizada.nomePlaylist, 'Gira de Iemanjá e Oxum');

      await service.deletarPlaylist(cadastrada.id!);
      final todas = await service.buscarPlaylists();
      expect(todas.any((p) => p.id == cadastrada.id), isFalse);
    });

    test('atualizarPlaylist envia payload correto para o backend', () async {
      late String capturedMethod;
      late String capturedUrl;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'id': 15,
            'nomePlaylist': 'Playlist figueira',
            'dataCriacao': '2026-03-10T10:00:00.000Z',
            'pontos': [
              {
                'ordem': 1,
                'ponto': {
                  'id': 14,
                  'nomePonto': 'Ponto Figueral',
                  'pontoLetra': '',
                  'audioUrl': '',
                }
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockService = PlaylistService(client: client);
      final playlistParaAtualizar = Playlist(
        id: 15,
        nomePlaylist: 'Playlist figueira',
        pontos: [
          PontoItem(
            ordem: 1,
            ponto: PontoCantado(
              id: 14,
              nomePonto: 'Ponto Figueral',
              pontoLetra: '',
              audioUrl: '',
            ),
          ),
        ],
      );

      final resultado = await mockService.atualizarPlaylist(15, playlistParaAtualizar);

      expect(capturedMethod, 'PUT');
      expect(capturedUrl, contains('/playlist/atualizar/15'));
      expect(capturedBody, {
        'nomePlaylist': 'Playlist figueira',
        'pontos': [
          {'pontoId': 14, 'ordem': 1}
        ],
      });
      expect(resultado.nomePlaylist, 'Playlist figueira');
      expect(resultado.pontos.length, 1);
      expect(resultado.pontos.first.ponto.id, 14);
    });

    test('cadastrarPlaylist envia payload correto e exibe nome da playlist', () async {
      late String capturedMethod;
      late String capturedUrl;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'id': 20,
            'nomePlaylist': 'Playlist test mu',
            'pontos': [
              {
                'ordem': 1,
                'ponto': {
                  'id': 1,
                  'nomePonto': 'Ponto Exemplo',
                  'pontoLetra': '',
                  'audioUrl': '',
                }
              }
            ],
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockService = PlaylistService(client: client);
      final novaPlaylist = Playlist(
        nomePlaylist: 'Playlist test mu',
        pontos: [
          PontoItem(
            ordem: 1,
            ponto: PontoCantado(
              id: 1,
              nomePonto: 'Ponto Exemplo',
              pontoLetra: '',
              audioUrl: '',
            ),
          ),
        ],
      );

      final resultado = await mockService.cadastrarPlaylist(novaPlaylist);

      expect(capturedMethod, 'POST');
      expect(capturedUrl, contains('/playlist/cadastrar'));
      expect(capturedBody, {
        'nomePlaylist': 'Playlist test mu',
        'pontos': [
          {'pontoId': 1, 'ordem': 1}
        ],
      });
      expect(resultado.id, 20);
      expect(resultado.nomePlaylist, 'Playlist test mu');
    });

    test('deletarPlaylist envia o parâmetro id na query string da URL (/playlist/deletar?id=2)', () async {
      late String capturedMethod;
      late String capturedUrl;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();

        return http.Response('', 204);
      });

      final mockService = PlaylistService(client: client);
      await mockService.deletarPlaylist(2);

      expect(capturedMethod, 'DELETE');
      expect(capturedUrl, contains('/playlist/deletar?id=2'));
    });
  });
}
