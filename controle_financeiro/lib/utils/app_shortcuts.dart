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