import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// showDialog com a duração de fade padrão do app
Future<T?> mostrarDialogo<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    animationStyle: AppMotion.estiloFade,
    builder: builder,
  );
}