import 'package:controle_financeiro/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- Atalhos do Shortcuts ----
class AceitarIntent extends Intent {
  const AceitarIntent();
}

class VoltarIntent extends Intent {
  const VoltarIntent();
}

class DelIntent extends Intent {
  const DelIntent();
}

final Map<ShortcutActivator, Intent> atalhosGlobais = {
  const SingleActivator(LogicalKeyboardKey.enter): const AceitarIntent(),
  const SingleActivator(LogicalKeyboardKey.escape): const VoltarIntent(),
  const SingleActivator(LogicalKeyboardKey.delete): const DelIntent(),
};

// ---- Atalhos do Handler ----
class GlobalKeyHandler {
  Map<LogicalKeyboardKey, VoidCallback> acoes1 = {};
  Map<LogicalKeyboardKey, bool Function()> acoes2 = {};
  final BuildContext Function() obterContext;
  static const _keyevents = [KeyDownEvent, KeyRepeatEvent];

  GlobalKeyHandler({
    this.acoes1 = const {},
    this.acoes2 = const {},
    required this.obterContext,
  });

  void registrar() => HardwareKeyboard.instance.addHandler(_processar);
  void remover() => HardwareKeyboard.instance.removeHandler(_processar);

  bool _processar(KeyEvent event) {
    if (!_keyevents.any((type) => event.runtimeType == type)) return false;

    final acao1 = acoes1.isNotEmpty ? acoes1[event.logicalKey] : null;
    final acao2 = acoes2.isNotEmpty ? acoes2[event.logicalKey] : null;
    if (acao1 != null) {
      acao1();
      return true;
    }
    if (acao2 != null) return acao2();

    return false;
  }
}

bool inserirDigitoInput({
  required BuildContext context,
  required String digito,
  required GlobalKey<CurrencyInputState> valorKey,
}) {
  final isFocado = FocusManager.instance.primaryFocus?.context?.widget is EditableText;
  if (isFocado) return false;

  valorKey.currentState?.adicionarDigito(digito);
  return true;
}

bool removerDigitoInput({
  required BuildContext context,
  required GlobalKey<CurrencyInputState> valorKey,
}) {
  final isFocado = FocusManager.instance.primaryFocus?.context?.widget is EditableText;
  if (isFocado) return false;

  valorKey.currentState?.removerDigito();
  return true;
}