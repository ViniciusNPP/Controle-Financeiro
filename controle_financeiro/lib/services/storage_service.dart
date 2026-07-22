import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/categoria.dart';
import '../models/transacao.dart';

/// Contêiner com tudo que o app precisa persistir: categorias e transações.
/// É salvo como um único arquivo JSON dentro da pasta do projeto.
class DadosApp {
  final List<Categoria> categorias;
  final List<Transacao> transacoes;

  const DadosApp({
    required this.categorias,
    required this.transacoes,
  });

  DadosApp copyWith({
    List<Categoria>? categorias,
    List<Transacao>? transacoes,
  }) =>
      DadosApp(
        categorias: categorias ?? this.categorias,
        transacoes: transacoes ?? this.transacoes,
      );

  Map<String, dynamic> toJson() => {
        'categorias': categorias.map((c) => c.toJson()).toList(),
        'transacoes': transacoes.map((t) => t.toJson()).toList(),
      };

  factory DadosApp.fromJson(Map<String, dynamic> json) => DadosApp(
        categorias: (json['categorias'] as List<dynamic>? ?? [])
            .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
            .toList(),
        transacoes: (json['transacoes'] as List<dynamic>? ?? [])
            .map((t) => Transacao.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  factory DadosApp.vazio() => DadosApp(
        categorias: [...Categoria.padroesSaida(), ...Categoria.padroesEntrada()],
        transacoes: const [],
      );
}

class StorageService {
  static const String _fileName = 'dados_financeiro.json';

  Future<File> _localFile() async {
    final dir = Directory.current.path;
    final pastaProjeto = path.normalize(path.join(dir, 'data'));
    final pasta = Directory(pastaProjeto);
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
    } catch (_) {
      return DadosApp.vazio();
    }
  }

  Future<void> salvar(DadosApp dados) async {
    final file = await _localFile();
    await file.writeAsString(jsonEncode(dados.toJson()));
  }
}
