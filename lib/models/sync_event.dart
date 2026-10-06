class SyncEvent<T> {
  final String acao;
  final dynamic dados;

  SyncEvent({
    required this.acao,
    required this.dados,
  });

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent<T>(
      acao: json['acao'] ?? '',
      dados: json['dados'],
    );
  }

  /// Retorna o ID caso a ação seja DELETE
  int? get idParaDeletar {
    if (dados is int) return dados;
    if (dados is String) return int.tryParse(dados);
    if (dados is Map && dados.containsKey('id')) return dados['id'];
    return null;
  }
}
