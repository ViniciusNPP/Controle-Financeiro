import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Operações de arquivo do Windows e do Android (lógica original do app).
class SyncPlataforma {
  Future<String?> escolherPasta() {
    return FilePicker.getDirectoryPath(
      dialogTitle: 'Escolha a pasta do Google Drive / OneDrive para sincronizar',
    );
  }

  Future<void> escreverNaPasta(
    String pasta,
    String nomeArquivo,
    String conteudo,
  ) async {
    final file = File('$pasta${Platform.pathSeparator}$nomeArquivo');
    await file.writeAsString(conteudo);
  }

  /// Conteúdo do arquivo na pasta, ou `null` se ele não existe.
  Future<String?> lerDaPasta(String pasta, String nomeArquivo) async {
    final file = File('$pasta${Platform.pathSeparator}$nomeArquivo');
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// Exportação manual. `false` se o usuário cancelou.
  Future<bool> exportar(String nomeArquivo, String conteudo) async {
    if (Platform.isAndroid) {
      final bytes = Uint8List.fromList(utf8.encode(conteudo));
      final caminho = await FilePicker.saveFile(
        dialogTitle: 'Salvar dados na pasta do Drive/OneDrive',
        fileName: nomeArquivo,
        bytes: bytes,
      );
      return caminho != null;
    }
    final caminho = await FilePicker.saveFile(
      dialogTitle: 'Salvar dados na pasta do Drive/OneDrive',
      fileName: nomeArquivo,
    );
    if (caminho == null) return false;
    await File(caminho).writeAsString(conteudo);
    return true;
  }

  /// Abre o seletor de arquivos e devolve o texto do arquivo escolhido.
  /// `null` = o usuário cancelou. Lança exceção se não conseguir ler.
  Future<String?> selecionarELer() async {
    final resultado = await FilePicker.pickFiles(
      dialogTitle: 'Selecione o arquivo dados_financeiro.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (resultado == null) return null;

    final arquivo = resultado.files.single;
    if (arquivo.path != null) return File(arquivo.path!).readAsString();
    if (arquivo.bytes != null) return utf8.decode(arquivo.bytes!);
    return '';
  }
}
