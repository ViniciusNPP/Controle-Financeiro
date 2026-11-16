import 'categoria.dart';

enum PagamentoLancamento { credito, reembolso }

class Transacao {
  final String id;
  final DateTime data;
  final TipoLancamento tipo;
  final String categoriaId;
  final String categoriaNome;
  final double valor;
  final String? descricao;
  final PagamentoLancamento? pagamento;
  final bool reembolsado;
  final String? reembolsoDeId;
  final bool pago;

  const Transacao({
    required this.id,
    required this.data,
    required this.tipo,
    required this.categoriaId,
    required this.categoriaNome,
    required this.valor,
    this.descricao,
    this.pagamento,
    this.reembolsado = false,
    this.reembolsoDeId,
    this.pago = false,
  });

  bool get ehCredito => pagamento == PagamentoLancamento.credito;
  bool get ehReembolso => pagamento == PagamentoLancamento.reembolso;
  bool get neutralizadaPorReembolso => reembolsado || ehReembolso;
  bool get usaCartao => pagamento != null;
  bool get pendenteNoCredito =>
      tipo == TipoLancamento.saida && ehCredito && !reembolsado && !pago;

  Transacao copyWith({
    String? id,
    DateTime? data,
    TipoLancamento? tipo,
    String? categoriaId,
    String? categoriaNome,
    double? valor,
    String? descricao,
    PagamentoLancamento? pagamento,
    bool limparPagamento = false,
    bool? reembolsado,
    String? reembolsoDeId,
    bool? pago,
  }) => Transacao(
    id: id ?? this.id,
    data: data ?? this.data,
    tipo: tipo ?? this.tipo,
    categoriaId: categoriaId ?? this.categoriaId,
    categoriaNome: categoriaNome ?? this.categoriaNome,
    valor: valor ?? this.valor,
    descricao: descricao ?? this.descricao,
    pagamento: limparPagamento ? null : (pagamento ?? this.pagamento),
    reembolsado: reembolsado ?? this.reembolsado,
    reembolsoDeId: reembolsoDeId ?? this.reembolsoDeId,
    pago: pago ?? this.pago,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.toIso8601String(),
    'tipo': tipo.name,
    'categoriaId': categoriaId,
    'categoriaNome': categoriaNome,
    'valor': valor,
    'descricao': descricao,
    'pagamento': pagamento?.name,
    'reembolsado': reembolsado,
    'reembolsoDeId': reembolsoDeId,
    'pago': pago,
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
    pagamento: PagamentoLancamento.values
        .where((p) => p.name == json['pagamento'])
        .firstOrNull,
    reembolsado: json['reembolsado'] as bool? ?? false,
    reembolsoDeId: json['reembolsoDeId'] as String?,
    pago: json['pago'] as bool? ?? false,
  );
}
