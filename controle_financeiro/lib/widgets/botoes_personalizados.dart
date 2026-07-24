import 'package:flutter/material.dart';

class BotoesPersonalizados extends StatelessWidget {
const BotoesPersonalizados({ super.key });

  @override
  Widget build(BuildContext context){
    return Container();
  }
}
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
    builder: (ctx) => AlertDialog(
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
            if (fecharTelaAposExcluir && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}