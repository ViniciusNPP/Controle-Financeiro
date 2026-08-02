import 'package:controle_financeiro/theme/app_theme.dart';
import 'package:controle_financeiro/utils/app_shortcuts.dart';
import 'package:flutter/material.dart';

enum Ground {
  foreground,
  background
}

ButtonStyle estiloBotao({
  Color corForeGround = const Color(0xFFece6f0),
  Color corBackGround = const Color(0xFFece6f0),
  bool isSide = false,
}) {
  return ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(corForeGround),
      backgroundColor: WidgetStatePropertyAll(corBackGround),
      side: WidgetStatePropertyAll(
        BorderSide(color: isSide ? (corForeGround == Color(0xFFece6f0) ? corBackGround : corForeGround) : Color(0xFFece6f0))
      ),
      shadowColor: WidgetStatePropertyAll(Color(0xFFece6f0)),
      mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
      ),
    );
}

/// Mostra um diálogo de confirmação de exclusão padrão do app.

/// [context] contexto da tela que está chamando o diálogo.
/// [titulo] título do AlertDialog.
/// [mensagem] texto explicativo mostrado ao usuário.
/// [corBotaoExcluir] cor de fundo do botão "Excluir".
/// [aoConfirmar] função assíncrona chamada quando o usuário confirma a exclusão.
/// [fecharTelaAposExcluir] se true, além de fechar o diálogo, também fecha a tela atual.
Future<void> confirmarExclusao({
  required BuildContext context,
  required String titulo,
  required String mensagem,
  required Color corBotaoExcluir,
  required Future<void> Function() aoConfirmar,
  bool fecharTelaAposExcluir = true,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Shortcuts(
      shortcuts: atalhosGlobais,
      child: Actions(
        actions: {
          AceitarIntent: CallbackAction<AceitarIntent> (onInvoke: (intent) {
            aoConfirmar();
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (ctx.mounted) Navigator.of(context).pop();
            return null;
          })
        },
        child: Focus(
          autofocus: true,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(titulo),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: estiloBotao(corForeGround: Color(0xFF2e2a6e)),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: estiloBotao(corBackGround: corBotaoExcluir),
                onPressed: () async {
                  await aoConfirmar();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (ctx.mounted) Navigator.of(context).pop();
                },
                child: const Text('Excluir'),
              ),
            ],
          ),
        )
      ),
    ),
  );
}

Widget botaoSelecionavel({
  required String label,
  required bool selecionado,
  required Color cor,
  required VoidCallback onTap,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? cor.withOpacity(0.12) : AppColors.disabledFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selecionado ? cor : Colors.transparent, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: selecionado ? cor : AppColors.textSecondary),
        ),
      ),
    ),
  );
}