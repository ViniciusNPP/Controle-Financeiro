import 'package:controle_financeiro/models/categoria.dart';
import 'package:controle_financeiro/utils/app_shortcuts.dart';
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
  final VoidCallback onSalvar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final List<Widget>? children2; // página 2 (opcional)
  final int pagina;
  final ValueChanged<int>? onPagina;

  const DetailDialogShell({
    super.key,
    required this.titulo,
    required this.children,
    required this.botaoSecundario,
    required this.botoesPrincipais,
    required this.onVoltar,
    required this.onCancelar,
    required this.editando,
    required this.onSalvar,
    required this.onEditar,
    required this.onExcluir,
    this.maxWidth = 420,
    this.children2,
    this.pagina = 0,
    this.onPagina,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !editando,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onVoltar();
      },
      child: Shortcuts(
        shortcuts: atalhosGlobais,
        child: Actions(
          actions: {
            AceitarIntent: CallbackAction<AceitarIntent>(
              onInvoke: (intend) {
                if (editando) {
                  onSalvar();
                } else {
                  onEditar();
                }
                return null;
              },
            ),
            DelIntent: CallbackAction<DelIntent>(
              onInvoke: (intent) => onExcluir(),
            ),
          },
          child: Focus(
            autofocus: true,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (children2 != null && onPagina != null) ...[
                          const SizedBox(height: 8),
                          PaginadorDialog(
                            pagina: pagina,
                            total: 2,
                            onPagina: onPagina!,
                          ),
                        ],
                        const SizedBox(height: 22),
                        for (final linha
                            in (pagina == 1 && children2 != null
                                ? children2!
                                : children)) ...[
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
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão "Voltar" ou "Cancelar"
Widget botaoSecundarioDialog({
  required BuildContext context,
  required bool editando,
  required VoidCallback onVoltar,
  required VoidCallback onCancelar,
}) {
  final telaPequena = MediaQuery.sizeOf(context).width < 600;

  if (editando) {
    if (telaPequena) {
      return IconButton(
        onPressed: onVoltar,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        tooltip: 'Voltar',
        style: estiloBotao(corForeGround: AppColors.textSecondary),
      );
    }
    return TextButton.icon(
      onPressed: onVoltar,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: const Text('Voltar'),
      style: estiloBotao(corForeGround: AppColors.textSecondary),
    );
  }
  if (telaPequena) {
    return IconButton(
      onPressed: onCancelar,
      icon: const Icon(Icons.close_rounded, size: 18),
      tooltip: 'Cancelar',
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
  required BuildContext context,
  required bool editando,
  required bool valido,
  required VoidCallback onSalvar,
  required VoidCallback onExcluir,
  required VoidCallback onEditar,
  Color corSalvar = AppColors.entrada,
  Color corEditar = const Color(0xFF201d4d),
  Widget? botaoSalvarCustom,
}) {
  final telaPequena = MediaQuery.sizeOf(context).width < 600;

  if (editando) {
    return [
      botaoSalvarCustom ??
          (telaPequena
              ? IconButton(
                  onPressed: valido ? onSalvar : null,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  tooltip: 'Salvar',
                  style: estiloBotao(corBackGround: corSalvar, isSide: true),
                )
              : ElevatedButton.icon(
                  onPressed: valido ? onSalvar : null,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Salvar'),
                  style: estiloBotao(corBackGround: corSalvar, isSide: true),
                )),
    ];
  }
  return [
    telaPequena
        ? IconButton(
            onPressed: onExcluir,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            tooltip: 'Excluir',
            style: estiloBotao(corForeGround: AppColors.saida, isSide: true),
          )
        : OutlinedButton.icon(
            onPressed: onExcluir,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Excluir'),
            style: estiloBotao(corForeGround: AppColors.saida, isSide: true),
          ),
    telaPequena
        ? IconButton(
            onPressed: onEditar,
            icon: const Icon(Icons.edit_rounded, size: 18),
            tooltip: 'Editar',
            style: estiloBotao(corBackGround: corEditar, isSide: true),
          )
        : ElevatedButton.icon(
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
          child: botaoSelecionavel(
            label: 'Entrada',
            selecionado: tipoSelecionado == TipoLancamento.entrada,
            cor: AppColors.entrada,
            onTap: () => onSelecionar(TipoLancamento.entrada),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: botaoSelecionavel(
            label: 'Saída',
            selecionado: tipoSelecionado == TipoLancamento.saida,
            cor: AppColors.saida,
            onTap: () => onSelecionar(TipoLancamento.saida),
          ),
        ),
      ],
    );
  }
}

/// Setas + bolinhas para navegar entre as páginas do diálogo.
class PaginadorDialog extends StatelessWidget {
  final int pagina;
  final int total;
  final ValueChanged<int> onPagina;

  const PaginadorDialog({
    super.key,
    required this.pagina,
    required this.total,
    required this.onPagina,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          mouseCursor: SystemMouseCursors.click,
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.textSecondary,
          onPressed: pagina > 0 ? () => onPagina(pagina - 1) : null,
        ),
        for (var i = 0; i < total; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == pagina ? AppColors.primary : AppColors.disabledFill,
            ),
          ),
        IconButton(
          mouseCursor: SystemMouseCursors.click,
          icon: const Icon(Icons.chevron_right_rounded),
          color: AppColors.textSecondary,
          onPressed: pagina < total - 1 ? () => onPagina(pagina + 1) : null,
        ),
      ],
    );
  }
}