enum DebitoEm { fechamento, vencimento }

class ConfigCredito {
  final bool debitoAutomatico;
  final DebitoEm debitoEm;
  final DateTime? fechamento;
  final DateTime? vencimento;

  const ConfigCredito({
    this.debitoAutomatico = false,
    this.debitoEm = DebitoEm.vencimento,
    this.fechamento,
    this.vencimento,
  });

  /// Data em que o débito automático acontece (a escolhida em "debitoEm").
  DateTime? get dataDebito =>
      debitoEm == DebitoEm.fechamento ? fechamento : vencimento;

  Map<String, dynamic> toJson() => {
    'debitoAutomatico': debitoAutomatico,
    'debitoEm': debitoEm.name,
    'fechamento': fechamento?.toIso8601String(),
    'vencimento': vencimento?.toIso8601String(),
  };

  static DateTime? _data(Object? v) => v is String ? DateTime.tryParse(v) : null;

  factory ConfigCredito.fromJson(Map<String, dynamic> json) => ConfigCredito(
    debitoAutomatico: json['debitoAutomatico'] as bool? ?? false,
    debitoEm:
        DebitoEm.values.where((e) => e.name == json['debitoEm']).firstOrNull ??
        DebitoEm.vencimento,
    fechamento: _data(json['fechamento']),
    vencimento: _data(json['vencimento']),
  );

  static int? _dia(DateTime? d) =>
      d == null ? null : d.year * 10000 + d.month * 100 + d.day;

  @override
  bool operator ==(Object other) =>
      other is ConfigCredito &&
      other.debitoAutomatico == debitoAutomatico &&
      other.debitoEm == debitoEm &&
      _dia(other.fechamento) == _dia(fechamento) &&
      _dia(other.vencimento) == _dia(vencimento);

  @override
  int get hashCode =>
      Object.hash(debitoAutomatico, debitoEm, _dia(fechamento), _dia(vencimento));
}