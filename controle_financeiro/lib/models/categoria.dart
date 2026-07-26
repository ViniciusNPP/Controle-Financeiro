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
  }) =>
      Categoria(
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

  static List<Categoria> padroesSaida() => [
        'Água',
        'Aposta',
        'Assinaturas',
        'Comida',
        'Compras',
        'Cuidados Pessoais',
        'Faculdade',
        'Internet',
        'Investimento',
        'Jogos',
        'Lazer',
        'Luz',
        'Telefone',
        'Transporte',
        'Dentista',
        'Barbeiro',
        'Emprestado',
      ]
          .map((nome) => Categoria(
                id: 'saida_${nome.toLowerCase().replaceAll(' ', '_')}',
                nome: nome,
                tipo: TipoLancamento.saida,
              ))
          .toList();

  static List<Categoria> padroesEntrada() => [
        'Salário',
        'Renda Extra',
        'Aposta',
        'Emprestado',
      ]
          .map((nome) => Categoria(
                id: 'entrada_${nome.toLowerCase().replaceAll(' ', '_')}',
                nome: nome,
                tipo: TipoLancamento.entrada,
              ))
          .toList();
}
