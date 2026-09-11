import 'ponto_item.dart';

class Playlist {
  final int? id;
  final String nomePlaylist;
  final DateTime? dataCriacao;
  final List<PontoItem> pontos;

  Playlist({
    this.id,
    required this.nomePlaylist,
    this.dataCriacao,
    this.pontos = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['dataCriacao'] != null) {
      parsedDate = DateTime.tryParse(json['dataCriacao'].toString());
    } else if (json['data_criacao'] != null) {
      parsedDate = DateTime.tryParse(json['data_criacao'].toString());
    }

    var pontosList = <PontoItem>[];
    if (json['pontos'] != null) {
      pontosList = (json['pontos'] as List)
          .map((item) => PontoItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Playlist(
      id: json['id'] as int?,
      nomePlaylist: (json['nomePlaylist'] ?? json['nome_playlist'] ?? '') as String,
      dataCriacao: parsedDate,
      pontos: pontosList,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'nomePlaylist': nomePlaylist,
      'pontos': pontos.map((p) => p.toJson()).toList(),
    };
    if (id != null) {
      data['id'] = id;
    }
    if (dataCriacao != null) {
      data['dataCriacao'] = dataCriacao!.toIso8601String();
    }
    return data;
  }

  Playlist copyWith({
    int? id,
    String? nomePlaylist,
    DateTime? dataCriacao,
    List<PontoItem>? pontos,
  }) {
    return Playlist(
      id: id ?? this.id,
      nomePlaylist: nomePlaylist ?? this.nomePlaylist,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      pontos: pontos ?? this.pontos,
    );
  }
}
