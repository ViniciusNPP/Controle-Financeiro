enum TipoLancamento { entrada, saida }

class Categoria {
  final String id;
  final String nome;
  final TipoLancamento tipo;

  const Categoria({
    required this.id,
    required this.nome,
    required this.tipo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo.name,
      };

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as String,
        nome: json['nome'] as String,
        tipo: TipoLancamento.values.firstWhere(
          (t) => t.name == json['tipo'],
          orElse: () => TipoLancamento.saida,
        ),
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
