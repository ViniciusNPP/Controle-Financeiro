import 'categoria.dart';

class Transacao {
  final String id;
  final DateTime data;
  final TipoLancamento tipo;
  final String categoriaId;
  final String categoriaNome;
  final double valor;
  final String? descricao;

  const Transacao({
    required this.id,
    required this.data,
    required this.tipo,
    required this.categoriaId,
    required this.categoriaNome,
    required this.valor,
    this.descricao,
  });

  Transacao copyWith({
    String? id,
    DateTime? data,
    TipoLancamento? tipo,
    String? categoriaId,
    String? categoriaNome,
    double? valor,
    String? descricao,
  }) => Transacao(
    id: id ?? this.id,
    data: data ?? this.data,
    tipo: tipo ?? this.tipo,
    categoriaId: categoriaId ?? this.categoriaId,
    categoriaNome: categoriaNome ?? this.categoriaNome,
    valor: valor ?? this.valor,
    descricao: descricao ?? this.descricao,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.toIso8601String(),
    'tipo': tipo.name,
    'categoriaId': categoriaId,
    'categoriaNome': categoriaNome,
    'valor': valor,
    'descricao': descricao,
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
  );
}
