import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Armazenamento bruto em arquivo (Windows e Android).
///
/// Mesmo local e mesmo nome de arquivo usados antes da versão web:
/// `<ApplicationSupport>/data/dados_financeiro.json`.
class ArmazenamentoLocal {
  static const String _fileName = 'dados_financeiro.json';

  Future<File> _localFile() async {
    final dir = await getApplicationSupportDirectory();
    final pasta = Directory(path.join(dir.path, 'data'));
    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }
    return File(path.join(pasta.path, _fileName));
  }

  /// Texto salvo, ou `null` se ainda não existe.
  Future<String?> ler() async {
    final file = await _localFile();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<void> escrever(String conteudo) async {
    final file = await _localFile();
    await file.writeAsString(conteudo);
  }
}
