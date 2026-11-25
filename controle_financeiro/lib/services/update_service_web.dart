import 'update_info.dart';

/// Versão web do serviço de atualização.
///
/// No navegador não existe instalador (.exe/.apk): quem abre o site já recebe
/// sempre a versão mais recente publicada. Por isso nunca há "atualização
/// disponível" e nada é baixado ou instalado.
class UpdateService {
  static Future<UpdateInfo?> checkForUpdate() async => null;

  static Future<String?> versaoRecemAtualizada() async => null;

  static Future<void> baixarEInstalarWindows(
    UpdateInfo info,
    void Function(double progresso) onProgress,
  ) async {
    throw UnsupportedError('Atualização por instalador não existe na web.');
  }

  static Future<void> baixarEInstalarAndroid(
    UpdateInfo info,
    void Function(double progresso) onProgress,
  ) async {
    throw UnsupportedError('Atualização por instalador não existe na web.');
  }
}
