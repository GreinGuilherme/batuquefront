import 'playlist.dart';

class GiraPlaylistItem {
  final int playlistId;
  final int ordem;
  final Playlist? playlist;

  GiraPlaylistItem({
    required this.playlistId,
    required this.ordem,
    this.playlist,
  });

  factory GiraPlaylistItem.fromJson(Map<String, dynamic> json) {
    Playlist? nestedPlaylist;
    int pId = 0;

    if (json.containsKey('playlist') && json['playlist'] is Map<String, dynamic>) {
      nestedPlaylist = Playlist.fromJson(json['playlist'] as Map<String, dynamic>);
      pId = nestedPlaylist.id ?? 0;
    }

    if (pId == 0) {
      final rawId = json['playlistId'] ?? json['idPlaylist'] ?? json['id_playlist'] ?? json['id'];
      if (rawId is int) {
        pId = rawId;
      } else if (rawId != null) {
        pId = int.tryParse(rawId.toString()) ?? 0;
      }
    }

    final int ordem = json['ordem'] is int ? json['ordem'] as int : int.tryParse(json['ordem']?.toString() ?? '0') ?? 0;

    return GiraPlaylistItem(
      playlistId: pId,
      ordem: ordem,
      playlist: nestedPlaylist,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlistId': playlistId,
      'ordem': ordem,
      if (playlist != null) 'playlist': playlist!.toJson(),
    };
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'playlistId': playlistId,
      'ordem': ordem,
    };
  }

  GiraPlaylistItem copyWith({
    int? playlistId,
    int? ordem,
    Playlist? playlist,
  }) {
    return GiraPlaylistItem(
      playlistId: playlistId ?? this.playlistId,
      ordem: ordem ?? this.ordem,
      playlist: playlist ?? this.playlist,
    );
  }
}

class Gira {
  final int? id;
  final String nomeGira;
  final String? descricao;
  final DateTime? dataCriacao;
  final List<GiraPlaylistItem> playlist;

  Gira({
    this.id,
    required this.nomeGira,
    this.descricao,
    this.dataCriacao,
    this.playlist = const [],
  });

  factory Gira.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['dataCriacao'] != null) {
      parsedDate = DateTime.tryParse(json['dataCriacao'].toString());
    } else if (json['data_criacao'] != null) {
      parsedDate = DateTime.tryParse(json['data_criacao'].toString());
    }

    var playlistList = <GiraPlaylistItem>[];
    final rawPlaylist = json['playlist'] ?? json['playlists'];
    if (rawPlaylist != null && rawPlaylist is List) {
      playlistList = rawPlaylist
          .map((item) => GiraPlaylistItem.fromJson(item as Map<String, dynamic>))
          .toList();
      playlistList.sort((a, b) => a.ordem.compareTo(b.ordem));
    }

    final rawId = json['id'] ?? json['idGira'] ?? json['id_gira'] ?? json['playlistId'];
    int? id;
    if (rawId is int) {
      id = rawId;
    } else if (rawId != null) {
      id = int.tryParse(rawId.toString());
    }

    return Gira(
      id: id,
      nomeGira: (json['nomeGira'] ?? json['nome_gira'] ?? json['nome'] ?? '') as String,
      descricao: (json['descricao'] ?? json['description'] ?? '') as String?,
      dataCriacao: parsedDate,
      playlist: playlistList,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'nomeGira': nomeGira,
      'playlist': playlist.map((p) => p.toJson()).toList(),
    };
    if (id != null) {
      data['id'] = id;
    }
    if (descricao != null && descricao!.isNotEmpty) {
      data['descricao'] = descricao;
    }
    if (dataCriacao != null) {
      data['dataCriacao'] = dataCriacao!.toIso8601String();
    }
    return data;
  }

  Map<String, dynamic> toInsertJson() {
    final Map<String, dynamic> data = {
      'nomeGira': nomeGira,
      'playlist': playlist.map((p) => p.toRequestJson()).toList(),
    };
    if (descricao != null && descricao!.isNotEmpty) {
      data['descricao'] = descricao;
    }
    return data;
  }

  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> data = {
      'nomeGira': nomeGira,
      'playlist': playlist.map((p) => p.toRequestJson()).toList(),
    };
    if (descricao != null && descricao!.isNotEmpty) {
      data['descricao'] = descricao;
    }
    return data;
  }

  Gira copyWith({
    int? id,
    String? nomeGira,
    String? descricao,
    DateTime? dataCriacao,
    List<GiraPlaylistItem>? playlist,
  }) {
    return Gira(
      id: id ?? this.id,
      nomeGira: nomeGira ?? this.nomeGira,
      descricao: descricao ?? this.descricao,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      playlist: playlist ?? this.playlist,
    );
  }
}
