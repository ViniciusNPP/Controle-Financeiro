import 'dart:convert';
import 'dart:js_interop';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

/// Operações de arquivo no navegador.
///
/// A web não tem acesso a pastas do computador, então não existe sincronização
/// automática por pasta: só exportar (download do .json) e importar (upload).
class SyncPlataforma {
  Future<String?> escolherPasta() async => null;

  Future<void> escreverNaPasta(
    String pasta,
    String nomeArquivo,
    String conteudo,
  ) async {}

  Future<String?> lerDaPasta(String pasta, String nomeArquivo) async => null;

  /// Exportação manual: o navegador baixa o `dados_financeiro.json`.
  Future<bool> exportar(String nomeArquivo, String conteudo) async {
    final blob = web.Blob(
      <JSAny>[conteudo.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);

    final link = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = nomeArquivo
      ..style.display = 'none';
    web.document.body!.append(link);
    link.click();
    link.remove();

    // Dá tempo ao navegador de iniciar o download antes de liberar o blob.
    Future<void>.delayed(
      const Duration(seconds: 30),
      () => web.URL.revokeObjectURL(url),
    );
    return true;
  }

  /// Abre o seletor de arquivos do navegador e devolve o texto do .json.
  /// `null` = o usuário cancelou. Na web `PlatformFile.path` não existe
  /// (acessá-lo lança erro), por isso só os bytes são usados.
  Future<String?> selecionarELer() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (resultado == null) return null;

    final bytes = resultado.files.single.bytes;
    if (bytes == null) return '';
    return utf8.decode(bytes);
  }
}
