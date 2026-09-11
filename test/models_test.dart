import 'package:flutter_test/flutter_test.dart';
import 'package:batuque/models/entidade.dart';
import 'package:batuque/models/ponto_cantado.dart';
import 'package:batuque/models/ponto_item.dart';
import 'package:batuque/models/playlist.dart';

void main() {
  group('Entidade Model', () {
    test('fromJson and toJson should serialize and deserialize correctly', () {
      final json = {
        'id': 1,
        'nomeEntidade': 'Caboclo Pena Branca',
        'falange': 'Caboclos',
        'linhaEntidade': 'Oxóssi',
      };

      final entidade = Entidade.fromJson(json);
      expect(entidade.id, 1);
      expect(entidade.nomeEntidade, 'Caboclo Pena Branca');
      expect(entidade.falange, 'Caboclos');
      expect(entidade.linhaEntidade, 'Oxóssi');

      final outputJson = entidade.toJson();
      expect(outputJson['id'], 1);
      expect(outputJson['nomeEntidade'], 'Caboclo Pena Branca');
      expect(outputJson['falange'], 'Caboclos');
      expect(outputJson['linhaEntidade'], 'Oxóssi');
    });

    test('fromJson supports snake_case fields as fallback', () {
      final json = {
        'id': 2,
        'nome_entidade': 'Preto Velho Pai Joaquim',
        'falange': 'Pretos Velhos',
        'linha_entidade': 'Yori/Yorimá',
      };

      final entidade = Entidade.fromJson(json);
      expect(entidade.id, 2);
      expect(entidade.nomeEntidade, 'Preto Velho Pai Joaquim');
      expect(entidade.linhaEntidade, 'Yori/Yorimá');
    });
  });

  group('PontoCantado Model', () {
    test('fromJson and toJson should serialize and deserialize correctly', () {
      final json = {
        'id': 10,
        'nomePonto': 'Ponto de Abertura',
        'pontoLetra': 'Okê Arô Caboclo...',
        'audioUrl': 'https://example.com/audio.mp3',
        'entidadeId': 1,
      };

      final ponto = PontoCantado.fromJson(json);
      expect(ponto.id, 10);
      expect(ponto.nomePonto, 'Ponto de Abertura');
      expect(ponto.pontoLetra, 'Okê Arô Caboclo...');
      expect(ponto.audioUrl, 'https://example.com/audio.mp3');
      expect(ponto.entidadeId, 1);

      final outputJson = ponto.toJson();
      expect(outputJson['id'], 10);
      expect(outputJson['nomePonto'], 'Ponto de Abertura');
      expect(outputJson['pontoLetra'], 'Okê Arô Caboclo...');
      expect(outputJson['audioUrl'], 'https://example.com/audio.mp3');
      expect(outputJson['entidadeId'], 1);
    });
  });

  group('PontoItem Model', () {
    test('fromJson and toJson should serialize and deserialize correctly', () {
      final json = {
        'ordem': 1,
        'ponto': {
          'id': 10,
          'nomePonto': 'Ponto de Abertura',
          'pontoLetra': 'Okê Arô...',
          'audioUrl': 'https://example.com/audio.mp3',
          'entidadeId': 1,
        },
      };

      final pontoItem = PontoItem.fromJson(json);
      expect(pontoItem.ordem, 1);
      expect(pontoItem.ponto.nomePonto, 'Ponto de Abertura');

      final outputJson = pontoItem.toJson();
      expect(outputJson['ordem'], 1);
      expect(outputJson['ponto']['nomePonto'], 'Ponto de Abertura');
    });
  });

  group('Playlist Model', () {
    test('fromJson and toJson should serialize and deserialize correctly', () {
      final json = {
        'id': 100,
        'nomePlaylist': 'Gira de Umbanda',
        'dataCriacao': '2026-03-10T10:00:00.000Z',
        'pontos': [
          {
            'ordem': 1,
            'ponto': {
              'id': 10,
              'nomePonto': 'Ponto de Abertura',
              'pontoLetra': 'Okê Arô...',
              'audioUrl': 'https://example.com/audio.mp3',
              'entidadeId': 1,
            },
          }
        ],
      };

      final playlist = Playlist.fromJson(json);
      expect(playlist.id, 100);
      expect(playlist.nomePlaylist, 'Gira de Umbanda');
      expect(playlist.dataCriacao, isNotNull);
      expect(playlist.pontos.length, 1);
      expect(playlist.pontos.first.ponto.nomePonto, 'Ponto de Abertura');

      final outputJson = playlist.toJson();
      expect(outputJson['id'], 100);
      expect(outputJson['nomePlaylist'], 'Gira de Umbanda');
      expect(outputJson['dataCriacao'], isNotNull);
      expect(outputJson['pontos'], isA<List>());
    });
  });
}
