import 'categoria.dart';

class Transacao {
  final String id;
  final DateTime data;
  final TipoLancamento tipo;
  final String categoriaId;
  final String categoriaNome;
  final double valor;

  const Transacao({
    required this.id,
    required this.data,
    required this.tipo,
    required this.categoriaId,
    required this.categoriaNome,
    required this.valor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'tipo': tipo.name,
        'categoriaId': categoriaId,
        'categoriaNome': categoriaNome,
        'valor': valor,
      };

  factory Transacao.fromJson(Map<String, dynamic> json) => Transacao(
        id: json['id'] as String,
        data: DateTime.parse(json['data'] as String),
        tipo: TipoLancamento.values.firstWhere(
          (t) => t.name == json['tipo'],
          orElse: () => TipoLancamento.saida,
        ),
        categoriaId: json['categoriaId'] as String,
        categoriaNome: json['categoriaNome'] as String,
        valor: (json['valor'] as num).toDouble(),
      );
}
