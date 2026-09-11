class PontoCantado {
  final int? id;
  final String nomePonto;
  final String pontoLetra;
  final String audioUrl;
  final int? entidadeId;

  PontoCantado({
    this.id,
    required this.nomePonto,
    required this.pontoLetra,
    required this.audioUrl,
    this.entidadeId,
  });

  factory PontoCantado.fromJson(Map<String, dynamic> json) {
    return PontoCantado(
      id: json['id'] as int?,
      nomePonto: (json['nomePonto'] ?? json['nome_ponto'] ?? '') as String,
      pontoLetra: (json['pontoLetra'] ?? json['ponto_letra'] ?? '') as String,
      audioUrl: (json['audioUrl'] ?? json['audio_url'] ?? '') as String,
      entidadeId: json['entidadeId'] as int? ?? json['entidade_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'nomePonto': nomePonto,
      'pontoLetra': pontoLetra,
      'audioUrl': audioUrl,
    };
    if (id != null) {
      data['id'] = id;
    }
    if (entidadeId != null) {
      data['entidadeId'] = entidadeId;
    }
    return data;
  }

  PontoCantado copyWith({
    int? id,
    String? nomePonto,
    String? pontoLetra,
    String? audioUrl,
    int? entidadeId,
  }) {
    return PontoCantado(
      id: id ?? this.id,
      nomePonto: nomePonto ?? this.nomePonto,
      pontoLetra: pontoLetra ?? this.pontoLetra,
      audioUrl: audioUrl ?? this.audioUrl,
      entidadeId: entidadeId ?? this.entidadeId,
    );
  }
}
