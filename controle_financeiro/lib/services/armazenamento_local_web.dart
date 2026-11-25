import 'package:shared_preferences/shared_preferences.dart';

/// Armazenamento bruto no navegador (web).
///
/// Os dados ficam no `localStorage` do navegador, via `shared_preferences`,
/// sob uma única chave com o mesmo JSON do `dados_financeiro.json`.
/// Por isso o arquivo exportado no Windows/Android pode ser importado aqui
/// e vice-versa.
class ArmazenamentoLocal {
  static const String _chave = 'dados_financeiro_json';

  /// Texto salvo, ou `null` se ainda não existe.
  Future<String?> ler() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chave);
  }

  Future<void> escrever(String conteudo) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(_chave, conteudo);
    if (!ok) {
      throw Exception('O navegador não permitiu salvar os dados.');
    }
  }
}
