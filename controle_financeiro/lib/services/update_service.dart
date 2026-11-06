import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String notes;
  final String pageUrl;
  final String? downloadUrl;

  UpdateInfo({
    required this.version,
    required this.notes,
    required this.pageUrl,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const _owner = 'ViniciusNPP';
  static const _repo = 'Controle-Financeiro';

  /// Retorna dados da nova versão, ou null se não há atualização ou se falhou nunca lança exceção
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_owner/$_repo/releases/latest',
            ),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final latest = (data['tag_name'] as String).replaceFirst(
        RegExp(r'^[vV]'),
        '',
      );
      final current = (await PackageInfo.fromPlatform()).version;
      if (!_isNewer(latest, current)) return null;

      final ext = Platform.isAndroid ? '.apk' : '.exe';
      String? url;
      for (final a in (data['assets'] as List).cast<Map<String, dynamic>>()) {
        if ((a['name'] as String).toLowerCase().endsWith(ext)) {
          url = a['browser_download_url'] as String;
          break;
        }
      }

      return UpdateInfo(
        version: latest,
        notes: (data['body'] as String?) ?? '',
        pageUrl: data['html_url'] as String,
        downloadUrl: url,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isNewer(String latest, String current) {
    List<int> parse(String v) =>
        v.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final a = parse(latest), b = parse(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  // --------------------------------------------------------------------------
  // Marcador de "atualização em andamento"
  // --------------------------------------------------------------------------
  static Future<File> _arquivoPendente() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}atualizacao_pendente.txt');
  }

  static Future<void> _marcarPendente(String versao) async {
    try {
      await (await _arquivoPendente()).writeAsString(versao);
    } catch (_) {}
  }

  /// Chamar ao abrir o app. Retorna a versão se o app acabou de ser atualizado.
  static Future<String?> versaoRecemAtualizada() async {
    try {
      await _limparApkBaixado();
      final f = await _arquivoPendente();
      if (!await f.exists()) return null;
      final alvo = (await f.readAsString()).trim();
      await f.delete();
      final atual = (await PackageInfo.fromPlatform()).version;
      // Se a versão alvo ainda é maior que a atual, a instalação não ocorreu.
      return _isNewer(alvo, atual) ? null : alvo;
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Windows
  // --------------------------------------------------------------------------
  /// Baixa o instalador, executa e encerra o app. Lança exceção se falhar.
  static Future<void> baixarEInstalarWindows(
    UpdateInfo info,
    void Function(double progresso) onProgress,
  ) async {
    final url = info.downloadUrl;
    if (url == null) {
      throw Exception('Instalador .exe não encontrado na release.');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}\\ControleFinanceiro_Setup.exe');

    final client = http.Client();
    try {
      final resp = await client.send(http.Request('GET', Uri.parse(url)));
      if (resp.statusCode != 200) {
        throw Exception('Falha no download (${resp.statusCode}).');
      }
      final total = resp.contentLength ?? 0;
      var recebido = 0;

      final sink = file.openWrite();
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        recebido += chunk.length;
        if (total > 0) onProgress(recebido / total);
      }
      await sink.close();
    } finally {
      client.close();
    }

    await _marcarPendente(info.version);
    await Process.start(file.path, [
      '/SILENT',
      '/CLOSEAPPLICATIONS',
      '/RESTARTAPPLICATIONS',
    ], mode: ProcessStartMode.detached);
    exit(0);
  }

  // --------------------------------------------------------------------------
  // Android
  // --------------------------------------------------------------------------
  /// Baixa o APK dentro do app e abre a confirmação de instalação do sistema.
  static Future<void> baixarEInstalarAndroid(
    UpdateInfo info,
    void Function(double progresso) onProgress,
  ) async {
    final url = info.downloadUrl;
    if (url == null) {
      throw Exception('APK não encontrado na release.');
    }

    await _marcarPendente(info.version);

    await for (final e in OtaUpdate().execute(
      url,
      destinationFilename: 'ControleFinanceiro.apk',
    )) {
      switch (e.status) {
        case OtaStatus.DOWNLOADING:
          onProgress((double.tryParse(e.value ?? '0') ?? 0) / 100);
          break;
        case OtaStatus.INSTALLING:
          return; // o instalador do sistema assumiu
        default:
          throw Exception('Falha na atualização: ${e.status}');
      }
    }
  }

  /// Apaga o APK baixado pelo ota_update (Android).
  static Future<void> _limparApkBaixado() async {
    if (!Platform.isAndroid) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final pasta = Directory('${dir.path}/ota_update');
      if (await pasta.exists()) await pasta.delete(recursive: true);
    } catch (_) {}
  }
}
