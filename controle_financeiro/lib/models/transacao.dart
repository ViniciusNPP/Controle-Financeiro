import 'categoria.dart';
import 'recorrencia.dart';

class Transacao {
  final String id;
  final DateTime data;
  final TipoLancamento tipo;
  final String categoriaId;
  final String categoriaNome;
  final double valor;
  final String? descricao;
  final RegraRecorrencia? recorrencia;

  const Transacao({
    required this.id,
    required this.data,
    required this.tipo,
    required this.categoriaId,
    required this.categoriaNome,
    required this.valor,
    this.descricao,
    this.recorrencia,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'tipo': tipo.name,
        'categoriaId': categoriaId,
        'categoriaNome': categoriaNome,
        'valor': valor,
        'descricao': descricao,
        'recorrencia': recorrencia?.toJson(),
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
        descricao: json['descricao'] as String?,
        recorrencia: json['recorrencia'] == null
            ? null
            : RegraRecorrencia.fromJson(json['recorrencia'] as Map<String, dynamic>),
      );
}