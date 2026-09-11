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
    return Entidade(
      id: json['id'] as int?,
      nomeEntidade: (json['nomeEntidade'] ?? json['nome_entidade'] ?? '') as String,
      falange: (json['falange'] ?? '') as String,
      linhaEntidade: (json['linhaEntidade'] ?? json['linha_entidade'] ?? '') as String,
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
