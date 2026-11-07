enum TipoLancamento { entrada, saida }

class Categoria {
  final String id;
  final String nome;
  final TipoLancamento tipo;
  final int vezesUsada;

  const Categoria({
    required this.id,
    required this.nome,
    required this.tipo,
    this.vezesUsada = 0,
  });

  Categoria copyWith({
    String? id,
    String? nome,
    TipoLancamento? tipo,
    int? vezesUsada,
  }) => Categoria(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    vezesUsada: vezesUsada ?? this.vezesUsada,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'tipo': tipo.name,
    'vezesUsada': vezesUsada,
  };

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    id: json['id'] as String,
    nome: json['nome'] as String,
    tipo: TipoLancamento.values.firstWhere(
      (t) => t.name == json['tipo'],
      orElse: () => TipoLancamento.saida,
    ),
    vezesUsada: json['vezesUsada'] as int? ?? 0,
  );

  static const Map<int, String> _nomesSaida = {
    1: 'Academia',
    2: 'Água',
    3: 'Aluguel',
    4: 'Aplicativos/Softwares',
    5: 'Aposta',
    6: 'Assinaturas',
    7: 'Barbeiro',
    8: 'Combustível',
    9: 'Comida',
    10: 'Compras',
    11: 'Cuidados Pessoais',
    12: 'Dentista',
    13: 'Emprestado',
    14: 'Faculdade',
    15: 'Internet',
    16: 'Investimento',
    17: 'Jogos',
    18: 'Lazer',
    19: 'Luz',
    20: 'Pet',
    21: 'Plano de Saúde',
    22: 'Presentes',
    23: 'Saúde',
    24: 'Seguro',
    25: 'Streaming',
    26: 'Supermercado',
    27: 'Telefone',
    28: 'Transporte',
  };

  static const Map<int, String> _nomesEntrada = {
    29: '13º salário',
    30: 'Aposta',
    31: 'Bolsa de estudos',
    32: 'Cashback',
    33: 'Comissão',
    34: 'Emprestado',
    35: 'Freelance',
    36: 'Investimento',
    37: 'Pensão',
    38: 'Renda Extra',
    39: 'Salário',
  };

  static List<Categoria> padroesSaida() => [
    for (final e in _nomesSaida.entries)
      Categoria(id: '${e.key}', nome: e.value, tipo: TipoLancamento.saida),
  ];

  static List<Categoria> padroesEntrada() => [
    for (final e in _nomesEntrada.entries)
      Categoria(id: '${e.key}', nome: e.value, tipo: TipoLancamento.entrada),
  ];

  static List<Categoria> todasPadroes() => [
    ...padroesSaida(),
    ...padroesEntrada(),
  ];

  /// Usado só na migração: mesma fórmula antiga de ID → novo ID numérico.
  static String _idAntigo(String prefixo, String nome) =>
      '${prefixo}_${nome.toLowerCase().replaceAll(' ', '_')}';

  static Map<String, String> idsAntigosParaNovos() => {
    for (final e in _nomesSaida.entries)
      _idAntigo('saida', e.value): '${e.key}',
    for (final e in _nomesEntrada.entries)
      _idAntigo('entrada', e.value): '${e.key}',
  };
}
