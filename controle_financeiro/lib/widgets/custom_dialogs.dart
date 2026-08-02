import 'package:controle_financeiro/models/categoria.dart';
import 'package:controle_financeiro/widgets/botoes_personalizados.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

//Widget que será reponsável por construir caixas de diálogos dos detalhes dos Lançamentos/Categorias
class DetailDialogShell extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  final Widget botaoSecundario;
  final List<Widget> botoesPrincipais;
  final double maxWidth;
  final bool editando;
  final VoidCallback onVoltar;
  final VoidCallback onCancelar;

  const DetailDialogShell({
    super.key,
    required this.titulo,
    required this.children,
    required this.botaoSecundario,
    required this.botoesPrincipais,
    required this.onVoltar,
    required this.onCancelar,
    required this.editando,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !editando,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onVoltar();
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 22),
                for (final linha in children) ...[
                  linha,
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      botaoSecundario,
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: botoesPrincipais,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão "Voltar" ou "Cancelar"
Widget botaoSecundarioDialog({
  required bool editando,
  required VoidCallback onVoltar,
  required VoidCallback onCancelar,
}) {
  if (editando) {
    return TextButton.icon(
      onPressed: onVoltar,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: const Text('Voltar'),
      style: estiloBotao(corForeGround: AppColors.textSecondary),
    );
  }
  return TextButton.icon(
    onPressed: onCancelar,
    icon: const Icon(Icons.close_rounded, size: 18),
    label: const Text('Cancelar'),
    style: estiloBotao(corForeGround: AppColors.textSecondary),
  );
}

/// Botão "Salvar" ou botões "Excluir" + "Editar"
List<Widget> botoesPrincipaisDialog({
  required bool editando,
  required bool valido,
  required VoidCallback onSalvar,
  required VoidCallback onExcluir,
  required VoidCallback onEditar,
  Color corSalvar = AppColors.entrada,
  Color corEditar = const Color(0xFF201d4d),
}) {
  if (editando) {
    return [
      ElevatedButton.icon(
        onPressed: valido ? onSalvar : null,
        icon: const Icon(Icons.save_rounded, size: 18),
        label: const Text('Salvar'),
        style: estiloBotao(corBackGround: corSalvar, isSide: true),
      ),
    ];
  }
  return [
    OutlinedButton.icon(
      onPressed: onExcluir,
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('Excluir'),
      style: estiloBotao(corForeGround: AppColors.saida, isSide: true),
    ),
    ElevatedButton.icon(
      onPressed: onEditar,
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Editar'),
      style: estiloBotao(corBackGround: corEditar, isSide: true),
    ),
  ];
}

class ValorEstatico extends StatelessWidget {
  final String texto;
  final Color? cor;

  const ValorEstatico(this.texto, {super.key, this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.disabledFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: cor ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}

class SeletorTipo extends StatelessWidget {
  final TipoLancamento tipoSelecionado;
  final ValueChanged<TipoLancamento> onSelecionar;

  const SeletorTipo({
    super.key,
    required this.tipoSelecionado,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _item(
            context,
            'Entrada',
            TipoLancamento.entrada,
            AppColors.entrada,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _item(context, 'Saída', TipoLancamento.saida, AppColors.saida),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    String label,
    TipoLancamento tipo,
    Color cor,
  ) {
    final selecionado = tipoSelecionado == tipo;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSelecionar(tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selecionado ? cor.withOpacity(0.12) : AppColors.disabledFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selecionado ? cor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selecionado ? cor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
