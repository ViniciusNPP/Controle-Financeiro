import 'categoria.dart';

enum PeriodoRecorrencia { diariamente, semanalmente, mensalmente, anualmente }

class LancamentoRecorrente {
  final String id;
  final TipoLancamento tipo;
  final String categoriaId;
  final String categoriaNome;
  final double valor;
  final String? descricao;

  final PeriodoRecorrencia periodo;
  final DateTime dataInicio;
  final DateTime dataRecorrencia;
  final DateTime? dataTermino;

  const LancamentoRecorrente({
    required this.id,
    required this.tipo,
    required this.categoriaId,
    required this.categoriaNome,
    required this.valor,
    this.descricao,
    required this.periodo,
    required this.dataInicio,
    required this.dataRecorrencia,
    this.dataTermino,
  });

  bool get finalizado => dataTermino != null && dataRecorrencia.isAfter(dataTermino!);

  LancamentoRecorrente copyWith({
    String? id,
    TipoLancamento? tipo,
    String? categoriaId,
    String? categoriaNome,
    double? valor,
    String? descricao,
    PeriodoRecorrencia? periodo,
    DateTime? dataInicio,
    DateTime? dataRecorrencia,
    DateTime? dataTermino,
  }) {
    return LancamentoRecorrente(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNome: categoriaNome ?? this.categoriaNome,
      valor: valor ?? this.valor,
      descricao: descricao ?? this.descricao,
      periodo: periodo ?? this.periodo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataRecorrencia: dataRecorrencia ?? this.dataRecorrencia,
      dataTermino: dataTermino ?? this.dataTermino,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'categoriaId': categoriaId,
        'categoriaNome': categoriaNome,
        'valor': valor,
        'descricao': descricao,
        'periodo': periodo.name,
        'dataInicio': dataInicio.toIso8601String(),
        'dataRecorrencia': dataRecorrencia.toIso8601String(),
        'dataTermino': dataTermino?.toIso8601String(),
      };

  factory LancamentoRecorrente.fromJson(Map<String, dynamic> json) => LancamentoRecorrente(
        id: json['id'] as String,
        tipo: TipoLancamento.values.firstWhere(
          (t) => t.name == json['tipo'],
          orElse: () => TipoLancamento.saida,
        ),
        categoriaId: json['categoriaId'] as String,
        categoriaNome: json['categoriaNome'] as String,
        valor: (json['valor'] as num).toDouble(),
        descricao: json['descricao'] as String?,
        periodo: PeriodoRecorrencia.values.firstWhere(
          (p) => p.name == json['periodo'],
          orElse: () => PeriodoRecorrencia.mensalmente,
        ),
        dataInicio: DateTime.parse(json['dataInicio'] as String),
        dataRecorrencia: DateTime.parse(json['dataRecorrencia'] as String),
        dataTermino: (json['dataTermino'] as String?) == null
            ? null
            : DateTime.parse(json['dataTermino'] as String),
      );
}