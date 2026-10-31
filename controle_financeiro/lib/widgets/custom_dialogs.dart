import 'package:controle_financeiro/models/categoria.dart';
import 'package:controle_financeiro/utils/app_shortcuts.dart';
import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:controle_financeiro/widgets/botoes_personalizados.dart';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:animations/animations.dart';

//Widget que será reponsável por construir caixas de diálogos dos detalhes dos Lançamentos/Categorias
class DetailDialogShell extends StatefulWidget {
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
  State<DetailDialogShell> createState() => _DetailDialogShellState();
}

class _DetailDialogShellState extends State<DetailDialogShell> {
  // true quando a página nova fica à esquerda da anterior
  bool _paginaReversa = false;

  bool get _ehCelular =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void didUpdateWidget(covariant DetailDialogShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pagina != oldWidget.pagina) {
      _paginaReversa = widget.pagina < oldWidget.pagina;
    }
  }

  /// Arrastar para a esquerda avança a página; para a direita, volta.
  void _aoArrastar(DragEndDetails detalhes) {
    final onPagina = widget.onPagina;
    if (widget.children2 == null || onPagina == null) return;
    final velocidade = detalhes.primaryVelocity ?? 0;
    if (velocidade < -300 && widget.pagina < 1) {
      onPagina(widget.pagina + 1);
    } else if (velocidade > 300 && widget.pagina > 0) {
      onPagina(widget.pagina - 1);
    }
  }

  // Alinha no topo para a página que sai não "pular" quando as alturas diferem.
  static Widget _empilharNoTopo(List<Widget> entradas) =>
      Stack(alignment: Alignment.topCenter, children: entradas);

  /// Linhas da página atual. Troca de página = shared axis horizontal.
  Widget _linhasDaPagina() {
    final linhas = (widget.pagina == 1 && widget.children2 != null)
        ? widget.children2!
        : widget.children;

    return PageTransitionSwitcher(
      reverse: _paginaReversa,
      duration: AppMotion.transicaoAba,
      layoutBuilder: _empilharNoTopo,
      transitionBuilder: (child, animation, secondaryAnimation) =>
          SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Colors.transparent,
            child: child,
          ),
      child: Column(
        key: ValueKey(widget.pagina),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final linha in linhas) ...[linha, const SizedBox(height: 16)],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temPaginas = widget.children2 != null && widget.onPagina != null;

    // Tudo o que muda ao entrar/sair do modo de edição fica aqui dentro.
    final conteudo = Column(
      key: ValueKey(widget.editando),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.titulo, style: Theme.of(context).textTheme.headlineMedium),
        if (temPaginas) ...[
          const SizedBox(height: 8),
          PaginadorDialog(
            pagina: widget.pagina,
            total: 2,
            onPagina: widget.onPagina!,
          ),
        ],
        const SizedBox(height: 22),
        _linhasDaPagina(),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              widget.botaoSecundario,
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: widget.botoesPrincipais,
              ),
            ],
          ),
        ),
      ],
    );

    return PopScope(
      canPop: !widget.editando,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onVoltar();
      },
      child: Shortcuts(
        shortcuts: atalhosGlobais,
        child: Actions(
          actions: {
            AceitarIntent: CallbackAction<AceitarIntent>(
              onInvoke: (intend) {
                if (widget.editando) {
                  widget.onSalvar();
                } else {
                  widget.onEditar();
                }
                return null;
              },
            ),
            DelIntent: CallbackAction<DelIntent>(
              onInvoke: (intent) => widget.onExcluir(),
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
                    maxWidth: widget.maxWidth,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (_ehCelular && temPaginas)
                        ? _aoArrastar
                        : null,
                    child: SingleChildScrollView(
                      // A altura do dialog acompanha a troca de conteúdo
                      child: AnimatedSize(
                        duration: AppMotion.fadeThrough,
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        // Modo de edição = fade through
                        child: PageTransitionSwitcher(
                          duration: AppMotion.fadeThrough,
                          layoutBuilder: _empilharNoTopo,
                          transitionBuilder:
                              (child, animation, secondaryAnimation) =>
                                  FadeThroughTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    fillColor: Colors.transparent,
                                    child: child,
                                  ),
                          child: conteudo,
                        ),
                      ),
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
      return ToqueElastico(
        child: IconButton(
          onPressed: onVoltar,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          tooltip: 'Voltar',
          style: estiloBotao(corForeGround: AppColors.textSecondary),
        ),
      );
    }
    return ToqueElastico(
      child: TextButton.icon(
        onPressed: onVoltar,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const Text('Voltar'),
        style: estiloBotao(corForeGround: AppColors.textSecondary),
      ),
    );
  }
  if (telaPequena) {
    return ToqueElastico(
      child: IconButton(
        onPressed: onCancelar,
        icon: const Icon(Icons.close_rounded, size: 18),
        tooltip: 'Cancelar',
        style: estiloBotao(corForeGround: AppColors.textSecondary),
      ),
    );
  }
  return ToqueElastico(
    child: TextButton.icon(
      onPressed: onCancelar,
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text('Cancelar'),
      style: estiloBotao(corForeGround: AppColors.textSecondary),
    ),
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
          ToqueElastico(
            child: telaPequena
                ? IconButton(
                    onPressed: valido ? onSalvar : null,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    tooltip: 'Salvar',
                    style: estiloBotao(
                      corBackGround: corSalvar,
                      corHover: AppColors.entradaLight,
                      isSide: true,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: valido ? onSalvar : null,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Salvar'),
                    style: estiloBotao(
                      corBackGround: corSalvar,
                      corHover: AppColors.entradaLight,
                      isSide: true,
                    ),
                  ),
          ),
    ];
  }
  return [
    ToqueElastico(
      child: telaPequena
          ? IconButton(
              onPressed: onExcluir,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              tooltip: 'Excluir',
              style: estiloBotao(
                corForeGround: AppColors.saida,
                corHover: AppColors.saidaLight,
                isSide: true,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onExcluir,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Excluir'),
              style: estiloBotao(
                corForeGround: AppColors.saida,
                corHover: AppColors.saidaLight,
                isSide: true,
              ),
            ),
    ),
    ToqueElastico(
      child: telaPequena
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
