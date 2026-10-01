enum PeriodoRecorrencia { diariamente, semanalmente, mensalmente, anualmente }

/// Regra de recorrência de uma [Transacao]. Guarda só a REGRA — as
/// ocorrências futuras não são persistidas aqui; outra parte do código usa
/// essa regra como um lembrete para lançar a transação quando chegar a data.
class RegraRecorrencia {
  final PeriodoRecorrencia periodo;
  final DateTime dataInicio;

  /// `null` significa recorrência indeterminada (sem data de término).
  final DateTime? dataTermino;

  const RegraRecorrencia({
    required this.periodo,
    required this.dataInicio,
    this.dataTermino,
  });

  Map<String, dynamic> toJson() => {
        'periodo': periodo.name,
        'dataInicio': dataInicio.toIso8601String(),
        'dataTermino': dataTermino?.toIso8601String(),
      };

  factory RegraRecorrencia.fromJson(Map<String, dynamic> json) => RegraRecorrencia(
        periodo: PeriodoRecorrencia.values.firstWhere(
          (p) => p.name == json['periodo'],
          orElse: () => PeriodoRecorrencia.mensalmente,
        ),
        dataInicio: DateTime.parse(json['dataInicio'] as String),
        dataTermino: (json['dataTermino'] as String?) == null
            ? null
            : DateTime.parse(json['dataTermino'] as String),
      );
}