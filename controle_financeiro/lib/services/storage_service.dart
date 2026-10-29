import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/categoria.dart';
import '../models/recorrencia.dart';
import '../models/transacao.dart';

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
  static const String _fileName = 'dados_financeiro.json';

  Future<File> _localFile() async {
    final dir = await getApplicationSupportDirectory();
    final pasta = Directory(path.join(dir.path, 'data'));
    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }
    return File(path.join(pasta.path, _fileName));
  }

  Future<DadosApp> carregar() async {
    try {
      final file = await _localFile();
      if (!await file.exists()) {
        final dados = DadosApp.vazio();
        await salvar(dados);
        return dados;
      }
      final conteudo = await file.readAsString();
      return DadosApp.fromJson(jsonDecode(conteudo) as Map<String, dynamic>);
    } catch (e, st) {
      print('Erro ao carregar dados: $e\n$st');
      return DadosApp.vazio();
    }
  }

  Future<void> salvar(DadosApp dados) async {
    try {
      final file = await _localFile();
      await file.writeAsString(jsonEncode(dados.toJson()));
    } catch (e, st) {
      print('Erro ao salvar dados: $e\n$st');
      rethrow;
    }
  }
}