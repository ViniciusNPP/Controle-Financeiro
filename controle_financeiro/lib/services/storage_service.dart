import 'dart:convert';
import '../models/categoria.dart';
import '../models/recorrencia.dart';
import '../models/transacao.dart';
// Web -> localStorage; Windows/Android -> arquivo (escolhido em tempo de compilação).
import 'armazenamento_local_web.dart'
    if (dart.library.io) 'armazenamento_local_io.dart';

class DadosApp {
  final List<Categoria> categorias;
  final List<Transacao> transacoes;
  final List<LancamentoRecorrente> recorrentes;

  const DadosApp({
    required this.categorias,
    required this.transacoes,
    this.recorrentes = const [],
  });

  DadosApp copyWith({
    List<Categoria>? categorias,
    List<Transacao>? transacoes,
    List<LancamentoRecorrente>? recorrentes,
  }) =>
      DadosApp(
        categorias: categorias ?? this.categorias,
        transacoes: transacoes ?? this.transacoes,
        recorrentes: recorrentes ?? this.recorrentes,
      );

  Map<String, dynamic> toJson() => {
        'categorias': categorias.map((c) => c.toJson()).toList(),
        'transacoes': transacoes.map((t) => t.toJson()).toList(),
        'recorrentes': recorrentes.map((r) => r.toJson()).toList(),
      };

  factory DadosApp.fromJson(Map<String, dynamic> json) => DadosApp(
        categorias: (json['categorias'] as List<dynamic>? ?? [])
            .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
            .toList(),
        transacoes: (json['transacoes'] as List<dynamic>? ?? [])
            .map((t) => Transacao.fromJson(t as Map<String, dynamic>))
            .toList(),
        // Chave nova: JSON salvo por versões anteriores do app não tem essa
        // lista, então o default de '[]' mantém a carga retrocompatível.
        recorrentes: (json['recorrentes'] as List<dynamic>? ?? [])
            .map((r) => LancamentoRecorrente.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  factory DadosApp.vazio() => DadosApp(
        categorias: [...Categoria.padroesSaida(), ...Categoria.padroesEntrada()],
        transacoes: const [],
        recorrentes: const [],
      );
}

class StorageService {
  final ArmazenamentoLocal _armazenamento = ArmazenamentoLocal();

  Future<DadosApp> carregar() async {
    try {
      final conteudo = await _armazenamento.ler();
      if (conteudo == null) {
        final dados = DadosApp.vazio();
        await salvar(dados);
        return dados;
      }
      return DadosApp.fromJson(jsonDecode(conteudo) as Map<String, dynamic>);
    } catch (e, st) {
      print('Erro ao carregar dados: $e\n$st');
      return DadosApp.vazio();
    }
  }

  Future<void> salvar(DadosApp dados) async {
    try {
      await _armazenamento.escrever(jsonEncode(dados.toJson()));
    } catch (e, st) {
      print('Erro ao salvar dados: $e\n$st');
      rethrow;
    }
  }
}
