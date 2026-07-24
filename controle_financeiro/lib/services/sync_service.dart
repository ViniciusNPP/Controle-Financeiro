import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

/// Sincronização sem servidor: usa uma pasta local (normalmente dentro do
/// Google Drive ou OneDrive que o usuário já tem instalado) como "banco de
/// dados" compartilhado entre o app do computador e o do celular.
///
/// No Windows, a pasta escolhida é um caminho de arquivo normal, então dá
/// pra ler/escrever nela automaticamente, sem repetir o diálogo.
///
/// No Android, o sistema (Storage Access Framework) não permite escrever
/// repetidamente numa pasta sem reabrir um seletor — por isso, no Android,
/// a sincronização é feita por ações explícitas de "Exportar" e "Importar".
class SyncService {
  static const _chavePasta = 'pasta_sincronizacao';
  static const _nomeArquivo = 'dados_financeiro.json';

  Future<String?> pastaConfigurada() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chavePasta);
  }

  Future<String?> escolherPasta() async {
    final caminho = await FilePicker.getDirectoryPath(
      dialogTitle: 'Escolha a pasta do Google Drive / OneDrive para sincronizar',
    );
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

  /// Escrita automática e silenciosa (usada no desktop a cada alteração).
  Future<void> escreverNaPasta(DadosApp dados) async {
    final pasta = await pastaConfigurada();
    if (pasta == null) return;
    try {
      final file = File('$pasta${Platform.pathSeparator}$_nomeArquivo');
      await file.writeAsString(jsonEncode(dados.toJson()));
    } catch (_) {
      // Falha silenciosa: os dados continuam salvos localmente e a
      // tentativa de sincronizar acontece de novo na próxima alteração.
    }
  }

  Future<DadosApp?> lerDaPasta() async {
    final pasta = await pastaConfigurada();
    if (pasta == null) return null;
    try {
      final file = File('$pasta${Platform.pathSeparator}$_nomeArquivo');
      if (!await file.exists()) return null;
      final conteudo = await file.readAsString();
      return DadosApp.fromJson(jsonDecode(conteudo) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Exportação manual (usada principalmente no Android): abre a caixa de
  /// diálogo nativa de salvar arquivo, apontando para a pasta do Drive/OneDrive.
  Future<bool> exportarArquivo(DadosApp dados) async {
    try {
      final jsonStr = jsonEncode(dados.toJson());
      if (Platform.isAndroid) {
        final bytes = Uint8List.fromList(utf8.encode(jsonStr));
        final caminho = await FilePicker.saveFile(
          dialogTitle: 'Salvar dados na pasta do Drive/OneDrive',
          fileName: _nomeArquivo,
          bytes: bytes,
        );
        return caminho != null;
      } else {
        final caminho = await FilePicker.saveFile(
          dialogTitle: 'Salvar dados na pasta do Drive/OneDrive',
          fileName: _nomeArquivo,
        );
        if (caminho == null) return false;
        await File(caminho).writeAsString(jsonStr);
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  /// Importação manual: abre o seletor de arquivos para escolher o
  /// dados_financeiro.json salvo anteriormente na pasta compartilhada.
  Future<DadosApp?> importarArquivo() async {
    final resultado = await FilePicker.pickFiles(
      dialogTitle: 'Selecione o arquivo dados_financeiro.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (resultado == null) return null; // usuário cancelou, sem erro

    final arquivo = resultado.files.single;
    String? conteudo;
    try {
      if (arquivo.path != null) {
        conteudo = await File(arquivo.path!).readAsString();
      } else if (arquivo.bytes != null) {
        conteudo = utf8.decode(arquivo.bytes!);
      }
    } catch (_) {
      throw FormatoInvalidoException('Não foi possível ler o arquivo selecionado.');
    }

    if (conteudo == null || conteudo.trim().isEmpty) {
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