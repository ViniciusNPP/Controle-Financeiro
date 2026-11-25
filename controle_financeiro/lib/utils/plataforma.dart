import 'package:flutter/foundation.dart';

/// Detecção de plataforma que funciona também no navegador.
///
/// `dart:io` (`Platform.isAndroid` etc.) não existe na web: usar essas
/// propriedades aqui evita o erro "Unsupported operation: Platform._operatingSystem".
class Plataforma {
  Plataforma._();

  /// Rodando como site/PWA no navegador (iPhone, Mac, Linux, Windows...).
  static bool get ehWeb => kIsWeb;

  /// App Android nativo (APK). No navegador do Android isto é `false`.
  static bool get ehAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
