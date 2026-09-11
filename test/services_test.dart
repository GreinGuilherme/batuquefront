import 'package:flutter_test/flutter_test.dart';
import 'package:batuque/models/entidade.dart';
import 'package:batuque/models/ponto_cantado.dart';
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

      await service.deletarEntidade(cadastrada.id!);
      final todas = await service.buscarEntidades();
      expect(todas.any((e) => e.id == cadastrada.id), isFalse);
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

      await service.deletarPonto(cadastrado.id!);
      final todos = await service.buscarPontos();
      expect(todos.any((p) => p.id == cadastrado.id), isFalse);
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
  });
}
