import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/categoria.dart';
import '../models/transacao.dart';

/// Conta local do usuário (email + hash da senha).
/// Não existe backend, então isto funciona como uma "trava" local,
/// não como uma autenticação de verdade — ver observação no README.
class ContaLocal {
  final String email;
  final String senhaHash;

  const ContaLocal({required this.email, required this.senhaHash});

  Map<String, dynamic> toJson() => {'email': email, 'senhaHash': senhaHash};

  factory ContaLocal.fromJson(Map<String, dynamic> json) => ContaLocal(
        email: json['email'] as String,
        senhaHash: json['senhaHash'] as String,
      );
}

/// Contêiner com tudo que o app precisa persistir: a conta, as categorias
/// e as transações. É salvo como um único arquivo JSON, tanto localmente
/// quanto na pasta compartilhada usada para sincronizar entre aparelhos.
class DadosApp {
  final ContaLocal? conta;
  final List<Categoria> categorias;
  final List<Transacao> transacoes;

  const DadosApp({
    this.conta,
    required this.categorias,
    required this.transacoes,
  });

  DadosApp copyWith({
    ContaLocal? conta,
    List<Categoria>? categorias,
    List<Transacao>? transacoes,
  }) =>
      DadosApp(
        conta: conta ?? this.conta,
        categorias: categorias ?? this.categorias,
        transacoes: transacoes ?? this.transacoes,
      );

  Map<String, dynamic> toJson() => {
        'conta': conta?.toJson(),
        'categorias': categorias.map((c) => c.toJson()).toList(),
        'transacoes': transacoes.map((t) => t.toJson()).toList(),
      };

  factory DadosApp.fromJson(Map<String, dynamic> json) => DadosApp(
        conta: json['conta'] != null
            ? ContaLocal.fromJson(json['conta'] as Map<String, dynamic>)
            : null,
        categorias: (json['categorias'] as List<dynamic>? ?? [])
            .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
            .toList(),
        transacoes: (json['transacoes'] as List<dynamic>? ?? [])
            .map((t) => Transacao.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  factory DadosApp.vazio() => DadosApp(
        conta: null,
        categorias: [...Categoria.padroesSaida(), ...Categoria.padroesEntrada()],
        transacoes: const [],
      );
}

class StorageService {
  static const String _fileName = 'dados_financeiro.json';

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
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
