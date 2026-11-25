import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
// Web -> download/upload de arquivo; Windows/Android -> pastas e seletor nativo.
import 'sync_plataforma_web.dart' if (dart.library.io) 'sync_plataforma_io.dart';

/// Sincronização
class SyncService {
  static const _chavePasta = 'pasta_sincronizacao';
  static const _nomeArquivo = 'dados_financeiro.json';

  final SyncPlataforma _plataforma = SyncPlataforma();

  Future<String?> pastaConfigurada() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chavePasta);
  }

  Future<String?> escolherPasta() async {
    final caminho = await _plataforma.escolherPasta();
    if (caminho != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chavePasta, caminho);
    }
    return caminho;
  }

  Future<void> limparPasta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chavePasta);
  }

  /// Escrita automática e silenciosa (usada a cada alteração).
  Future<void> escreverNaPasta(DadosApp dados) async {
    final jsonStr = jsonEncode(dados.toJson());
    final pasta = await pastaConfigurada();
    if (pasta == null) return;
    try {
      await _plataforma.escreverNaPasta(pasta, _nomeArquivo, jsonStr);
    } catch (_) {}
  }

  Future<DadosApp?> lerDaPasta() async {
    final pasta = await pastaConfigurada();
    if (pasta == null) return null;
    try {
      final conteudo = await _plataforma.lerDaPasta(pasta, _nomeArquivo);
      if (conteudo == null) return null;
      return DadosApp.fromJson(jsonDecode(conteudo) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Exportação manual
  Future<bool> exportarArquivo(DadosApp dados) async {
    try {
      final jsonStr = jsonEncode(dados.toJson());
      return await _plataforma.exportar(_nomeArquivo, jsonStr);
    } catch (_) {
      return false;
    }
  }

  /// Importação manual: abre o seletor de arquivos para escolher o
  /// dados_financeiro.json salvo anteriormente na pasta compartilhada.
  Future<DadosApp?> importarArquivo() async {
    String? conteudo;
    try {
      conteudo = await _plataforma.selecionarELer();
    } catch (_) {
      throw FormatoInvalidoException('Não foi possível ler o arquivo selecionado.');
    }
    if (conteudo == null) return null; // usuário cancelou, sem erro

    if (conteudo.trim().isEmpty) {
      throw FormatoInvalidoException('O arquivo selecionado está vazio.');
    }

    late final Map<String, dynamic> json;
    try {
      json = jsonDecode(conteudo) as Map<String, dynamic>;
    } catch (_) {
      throw FormatoInvalidoException('O arquivo selecionado não é um JSON válido.');
    }

    if (!json.containsKey('categorias') || !json.containsKey('transacoes')) {
      throw FormatoInvalidoException(
        'Esse arquivo não parece ser um backup do Controle Financeiro.',
      );
    }

    try {
      return DadosApp.fromJson(json);
    } catch (_) {
      throw FormatoInvalidoException('O arquivo tem dados em um formato inesperado.');
    }
  }
}

/// Lançada quando o arquivo escolhido não é um backup válido do app.
class FormatoInvalidoException implements Exception {
  final String mensagem;
  FormatoInvalidoException(this.mensagem);
}