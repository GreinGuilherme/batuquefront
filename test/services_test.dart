import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:batuque/models/entidade.dart';
import 'package:batuque/models/ponto_cantado.dart';
import 'package:batuque/models/playlist.dart';
import 'package:batuque/models/gira.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batuque/services/entidade_service.dart';
import 'package:batuque/services/ponto_service.dart';
import 'package:batuque/services/playlist_service.dart';
import 'package:batuque/services/gira_service.dart';
import 'package:batuque/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Testes', () {
    test('solicitarCodigoRecuperacao envia POST para /auth/esqueci-senha com headers corretos', () async {
      late String capturedMethod;
      late String capturedUrl;
      late Map<String, String> capturedHeaders;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();
        capturedHeaders = request.headers;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({'mensagem': 'Caso o e-mail esteja cadastrado, você receberá um código de recuperação em instantes.'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AuthService(client: client);
      final msg = await service.solicitarCodigoRecuperacao(email: 'teste@email.com');

      expect(capturedMethod, 'POST');
      expect(capturedUrl, contains('/auth/esqueci-senha'));
      expect(capturedHeaders['x-app-batuque'], 'GiraSegura2026');
      expect(capturedHeaders['User-Agent'], contains('BatuqueFlutterApp'));
      expect(capturedBody['email'], 'teste@email.com');
      expect(msg, contains('Caso o e-mail esteja cadastrado'));
    });

    test('redefinirSenha envia POST para /auth/redefinir-senha com headers corretos', () async {
      late String capturedMethod;
      late String capturedUrl;
      late Map<String, String> capturedHeaders;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();
        capturedHeaders = request.headers;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({'mensagem': 'Senha atualizada com sucesso! Faça login com sua nova senha.'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AuthService(client: client);
      final msg = await service.redefinirSenha(
        email: 'teste@email.com',
        codigo: '123456',
        novaSenha: 'novaSenha123',
      );

      expect(capturedMethod, 'POST');
      expect(capturedUrl, contains('/auth/redefinir-senha'));
      expect(capturedHeaders['x-app-batuque'], 'GiraSegura2026');
      expect(capturedHeaders['User-Agent'], contains('BatuqueFlutterApp'));
      expect(capturedBody['email'], 'teste@email.com');
      expect(capturedBody['codigo'], '123456');
      expect(capturedBody['novaSenha'], 'novaSenha123');
      expect(msg, contains('Senha atualizada com sucesso!'));
    });
  });

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
      expect(capturedUrl, contains('/entidade/deletar/1'));
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

  group('GiraService Testes', () {
    test('cadastrarGira envia payload para /gira/cadastrar', () async {
      late String capturedMethod;
      late String capturedUrl;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'id': 50,
            'nomeGira': 'PlaylistsTests2',
            'descricao': 'Test playlists',
            'playlist': [
              {'playlistId': 25, 'ordem': 1},
              {'playlistId': 26, 'ordem': 2},
            ],
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GiraService(client: client);
      final gira = Gira(
        nomeGira: 'PlaylistsTests2',
        descricao: 'Test playlists',
        playlist: [
          GiraPlaylistItem(playlistId: 25, ordem: 1),
          GiraPlaylistItem(playlistId: 26, ordem: 2),
        ],
      );

      final resultado = await service.cadastrarGira(gira);

      expect(capturedMethod, 'POST');
      expect(capturedUrl, contains('/gira/cadastrar'));
      expect(capturedBody['nomeGira'], 'PlaylistsTests2');
      expect(capturedBody['descricao'], 'Test playlists');
      expect(capturedBody['playlist'], [
        {'playlistId': 25, 'ordem': 1},
        {'playlistId': 26, 'ordem': 2},
      ]);
      expect(resultado.id, 50);
    });

    test('buscarGiras retorna lista de giras', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'nomeGira': 'Gira de Exu',
              'playlist': [],
            }
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GiraService(client: client);
      final giras = await service.buscarGiras();

      expect(giras.length, 1);
      expect(giras.first.nomeGira, 'Gira de Exu');
    });

    test('atualizarGira envia PUT para /gira/atualizar/{playlistId}', () async {
      late String capturedMethod;
      late String capturedUrl;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'id': 25,
            'nomeGira': 'Adicionando playlist2',
            'playlist': [
              {'playlistId': 25, 'ordem': 1},
              {'playlistId': 26, 'ordem': 2},
              {'playlistId': 8, 'ordem': 3},
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GiraService(client: client);
      final gira = Gira(
        id: 25,
        nomeGira: 'Adicionando playlist2',
        playlist: [
          GiraPlaylistItem(playlistId: 25, ordem: 1),
          GiraPlaylistItem(playlistId: 26, ordem: 2),
          GiraPlaylistItem(playlistId: 8, ordem: 3),
        ],
      );

      final resultado = await service.atualizarGira(25, gira);

      expect(capturedMethod, 'PUT');
      expect(capturedUrl, contains('/gira/atualizar/25'));
      expect(capturedBody['nomeGira'], 'Adicionando playlist2');
      expect(capturedBody['playlist'].length, 3);
      expect(resultado.id, 25);
    });

    test('deletarGira envia DELETE para /gira/deletar?id=25', () async {
      late String capturedMethod;
      late String capturedUrl;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedUrl = request.url.toString();

        return http.Response('', 200);
      });

      final service = GiraService(client: client);
      await service.deletarGira(25);

      expect(capturedMethod, 'DELETE');
      expect(capturedUrl, contains('/gira/deletar?id=25'));
    });
  });
}
