import '../models/entidade.dart';
import '../models/ponto_cantado.dart';
import '../models/ponto_item.dart';
import '../models/playlist.dart';

class MockData {
  static List<Entidade> entidades = [
    Entidade(
      id: 1,
      nomeEntidade: 'Caboclo Pena Branca',
      falange: 'Caboclos',
      linhaEntidade: 'Oxóssi',
    ),
    Entidade(
      id: 2,
      nomeEntidade: 'Preto Velho Pai Joaquim',
      falange: 'Pretos Velhos',
      linhaEntidade: 'Yori/Yorimá',
    ),
    Entidade(
      id: 3,
      nomeEntidade: 'Baiano Zé do Laço',
      falange: 'Baianos',
      linhaEntidade: 'Baianos',
    ),
    Entidade(
      id: 4,
      nomeEntidade: 'Exu Tranca Ruas',
      falange: 'Exus',
      linhaEntidade: 'Ogum/Exu',
    ),
    Entidade(
      id: 5,
      nomeEntidade: 'Oxum das Cachoeiras',
      falange: 'Orixás',
      linhaEntidade: 'Oxum',
    ),
  ];

  static List<PontoCantado> pontos = [
    PontoCantado(
      id: 1,
      nomePonto: 'Ponto de Oxóssi - Okê Arô',
      pontoLetra: 'Okê Arô Caboclo, ele é o rei da mata...\nCom sua flecha de ouro e seu arco de prata.',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      entidadeId: 1,
    ),
    PontoCantado(
      id: 2,
      nomePonto: 'Ponto de Preto Velho - Cativeiro',
      pontoLetra: 'Foi na senzala onde o preto velho viveu...\nPediu a meu Pai Ogum que nos abençoou.',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      entidadeId: 2,
    ),
    PontoCantado(
      id: 3,
      nomePonto: 'Ponto de Baiano - Se Zé Pelintra pediu',
      pontoLetra: 'Com seu chapéu de palha e seu lenço no pescoço...\nBaiano vem trabalhar no terreiro.',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      entidadeId: 3,
    ),
    PontoCantado(
      id: 4,
      nomePonto: 'Ponto de Exu - Tranca Ruas na Encruzilhada',
      pontoLetra: 'Tranca Ruas das Almas, dono do meu caminho...\nCom sua capa preta não me deixa sozinho.',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      entidadeId: 4,
    ),
  ];

  static List<Playlist> playlists = [
    Playlist(
      id: 1,
      nomePlaylist: 'Gira de Abertura',
      dataCriacao: DateTime.now().subtract(const Duration(days: 2)),
      pontos: [
        PontoItem(
          ordem: 1,
          ponto: PontoCantado(
            id: 1,
            nomePonto: 'Ponto de Oxóssi - Okê Arô',
            pontoLetra: 'Okê Arô Caboclo, ele é o rei da mata...',
            audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            entidadeId: 1,
          ),
        ),
        PontoItem(
          ordem: 2,
          ponto: PontoCantado(
            id: 2,
            nomePonto: 'Ponto de Preto Velho - Cativeiro',
            pontoLetra: 'Foi na senzala onde o preto velho viveu...',
            audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            entidadeId: 2,
          ),
        ),
      ],
    ),
    Playlist(
      id: 2,
      nomePlaylist: 'Gira de Exu',
      dataCriacao: DateTime.now().subtract(const Duration(days: 1)),
      pontos: [
        PontoItem(
          ordem: 1,
          ponto: PontoCantado(
            id: 4,
            nomePonto: 'Ponto de Exu - Tranca Ruas na Encruzilhada',
            pontoLetra: 'Tranca Ruas das Almas, dono do meu caminho...',
            audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
            entidadeId: 4,
          ),
        ),
      ],
    ),
  ];
}
