class Entidade {
  final int? id;
  final String nomeEntidade;
  final String falange;
  final String linhaEntidade;

  Entidade({
    this.id,
    required this.nomeEntidade,
    required this.falange,
    required this.linhaEntidade,
  });

  factory Entidade.fromJson(Map<String, dynamic> json) {
    int? parsedId;
    if (json['id'] != null) {
      if (json['id'] is num) {
        parsedId = (json['id'] as num).toInt();
      } else if (json['id'] is String) {
        parsedId = int.tryParse(json['id'] as String);
      }
    }

    return Entidade(
      id: parsedId,
      nomeEntidade: (json['nomeEntidade'] ?? json['nome_entidade'] ?? json['nome'] ?? '') as String,
      falange: (json['falange'] ?? '') as String,
      linhaEntidade: (json['linhaEntidade'] ?? json['linha_entidade'] ?? json['linha'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'nomeEntidade': nomeEntidade,
      'falange': falange,
      'linhaEntidade': linhaEntidade,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }

  Entidade copyWith({
    int? id,
    String? nomeEntidade,
    String? falange,
    String? linhaEntidade,
  }) {
    return Entidade(
      id: id ?? this.id,
      nomeEntidade: nomeEntidade ?? this.nomeEntidade,
      falange: falange ?? this.falange,
      linhaEntidade: linhaEntidade ?? this.linhaEntidade,
    );
  }
}
