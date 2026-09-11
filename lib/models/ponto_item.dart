import 'ponto_cantado.dart';

class PontoItem {
  final int ordem;
  final PontoCantado ponto;

  PontoItem({
    required this.ordem,
    required this.ponto,
  });

  factory PontoItem.fromJson(Map<String, dynamic> json) {
    return PontoItem(
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
      ponto: json['ponto'] != null
          ? PontoCantado.fromJson(json['ponto'] as Map<String, dynamic>)
          : PontoCantado(
              id: (json['pontoId'] ?? json['ponto_id']) as int?,
              nomePonto: '',
              pontoLetra: '',
              audioUrl: '',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ordem': ordem,
      'ponto': ponto.toJson(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'pontoId': ponto.id,
      'ordem': ordem,
    };
  }

  PontoItem copyWith({
    int? ordem,
    PontoCantado? ponto,
  }) {
    return PontoItem(
      ordem: ordem ?? this.ordem,
      ponto: ponto ?? this.ponto,
    );
  }
}
