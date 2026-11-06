import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lista de opções flutuante (Material + ListView de ListTile), no mesmo
/// visual usado pelo Autocomplete de categoria do FiltroBuilder. Usada tanto
/// por [dropdownEstilizado] quanto por [autocompleteEstilizado].
Widget _listaOpcoes({
  required List<String> opcoes,
  required ValueChanged<String> onSelected,
  Animation<double>? animacao,
}) {
  final lista = Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(14),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220, minWidth: 220),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: opcoes.length,
        itemBuilder: (context, i) {
          final opcao = opcoes[i];
          return ListTile(
            dense: true,
            title: Text(opcao),
            onTap: () => onSelected(opcao),
          );
        },
      ),
    ),
  );

  return Align(
    alignment: Alignment.topLeft,
    child: animacao == null
        ? lista
        : _TransicaoMenu(animacao: animacao, child: lista),
  );
}

/// Campo de texto com autocomplete. Usa overlay próprio (e não o Autocomplete
/// do Flutter) porque ele remove a lista na hora, sem dar chance de animar o fechamento.
Widget autocompleteEstilizado({
  Key? key,
  required List<String> opcoes,
  required String hint,
  ValueChanged<TextEditingController>? aoCriarController,
  required ValueChanged<String> onChanged,
}) {
  return _AutocompleteEstilizado(
    key: key,
    opcoes: opcoes,
    hint: hint,
    aoCriarController: aoCriarController,
    onChanged: onChanged,
  );
}

class _AutocompleteEstilizado extends StatefulWidget {
  final List<String> opcoes;
  final String hint;
  final ValueChanged<TextEditingController>? aoCriarController;
  final ValueChanged<String> onChanged;

  const _AutocompleteEstilizado({
    super.key,
    required this.opcoes,
    required this.hint,
    required this.aoCriarController,
    required this.onChanged,
  });

  @override
  State<_AutocompleteEstilizado> createState() =>
      _AutocompleteEstilizadoState();
}

class _AutocompleteEstilizadoState extends State<_AutocompleteEstilizado>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  late final AnimationController _animController;
  late final Animation<double> _curva;

  String? _ultimaSelecao;
  // Guarda a última lista exibida para ela não "encolher" durante o fade de saída.
  List<String> _opcoesExibidas = const [];

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
          vsync: this,
          duration: AppMotion.dropdownAbrir,
          reverseDuration: AppMotion.dropdownFechar,
        )..addStatusListener((status) {
          if (status == AnimationStatus.dismissed) _removerOverlay();
        });
    _curva = CurvedAnimation(
      parent: _animController,
      curve: AppMotion.curvaAbrir,
      reverseCurve: AppMotion.curvaFechar,
    );
    _controller.addListener(_atualizar);
    _focusNode.addListener(_atualizar);
    widget.aoCriarController?.call(_controller);
  }

  List<String> get _filtradas {
    final t = _controller.text.toLowerCase();
    if (t.isEmpty) return widget.opcoes;
    return widget.opcoes.where((o) => o.toLowerCase().contains(t)).toList();
  }

  void _atualizar() {
    if (!mounted) return;
    final filtradas = _filtradas;
    final mostrar =
        _focusNode.hasFocus &&
        _controller.text != _ultimaSelecao &&
        filtradas.isNotEmpty;
    if (mostrar) {
      _opcoesExibidas = filtradas;
      _abrir();
    } else {
      _fechar();
    }
    _overlay?.markNeedsBuild();
  }

  void _abrir() {
    if (_overlay == null) {
      final box = context.findRenderObject() as RenderBox;
      final largura = box.size.width;
      final altura = box.size.height;

      _overlay = OverlayEntry(
        builder: (_) => Positioned(
          width: largura,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, altura + 4),
            // Clicar na lista não conta como "clicar fora" do campo.
            child: TextFieldTapRegion(
              child: _listaOpcoes(
                opcoes: _opcoesExibidas,
                animacao: _curva,
                onSelected: _selecionar,
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlay!);
    }
    _animController.forward();
  }

  void _fechar() {
    if (_overlay == null) return;
    _animController.reverse();
  }

  void _removerOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _selecionar(String opcao) {
    _ultimaSelecao = opcao;
    _controller.value = TextEditingValue(
      text: opcao,
      selection: TextSelection.collapsed(offset: opcao.length),
    );
    widget.onChanged(opcao);
  }

  @override
  void dispose() {
    _controller.removeListener(_atualizar);
    _focusNode.removeListener(_atualizar);
    _removerOverlay();
    _animController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(hintText: widget.hint),
        onChanged: (texto) {
          _ultimaSelecao = null;
          widget.onChanged(texto);
        },
        onTapOutside: (_) => _focusNode.unfocus(),
      ),
    );
  }
}

/// Estrutura compartilhada de menu suspenso com estilo e posicionamento padrão.
/// Cada chamador define os itens e o conteúdo que abre o menu.
class PopupMenuEstilizado<T> extends StatelessWidget {
  final PopupMenuItemBuilder<T> itemBuilder;
  final Widget child;
  final ValueChanged<T>? onSelected;
  final bool enabled;
  final VoidCallback? onOpened;
  final VoidCallback? onCanceled;
  final PopupMenuPosition? position;
  final Offset offset;
  final ShapeBorder? shape;
  final BoxConstraints? menuConstraints;

  const PopupMenuEstilizado({
    super.key,
    required this.itemBuilder,
    required this.child,
    this.onSelected,
    this.enabled = true,
    this.onOpened,
    this.onCanceled,
    this.position = PopupMenuPosition.under,
    this.offset = const Offset(0, 4),
    this.shape,
    this.menuConstraints,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final restricao = constraints.hasBoundedWidth
            ? BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
                maxHeight: 280,
              )
            : const BoxConstraints(minWidth: 160, maxHeight: 280);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: PopupMenuButton<T>(
            enabled: enabled,
            tooltip: '',
            popUpAnimationStyle: AppMotion.estiloDropdown,
            position: position,
            offset: offset,
            shape:
                shape ??
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            constraints: menuConstraints ?? restricao,
            onOpened: onOpened,
            onCanceled: onCanceled,
            onSelected: onSelected,
            itemBuilder: itemBuilder,
            child: child,
          ),
        );
      },
    );
  }
}

PopupMenuItem<T> popupMenuItemEstilizado<T>({
  required T value,
  required Widget child,
  bool enabled = true,
  EdgeInsets? padding,
}) {
  return PopupMenuItem<T>(
    value: value,
    enabled: enabled,
    mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
    padding: padding,
    child: child,
  );
}

PopupMenuItem<T> popupMenuItemTexto<T>({
  required T value,
  required String texto,
  bool selecionado = false,
  bool habilitado = true,
  TextOverflow? overflow,
}) {
  return popupMenuItemEstilizado<T>(
    value: value,
    enabled: habilitado,
    child: Row(
      children: [
        Expanded(
          child: Text(
            texto,
            overflow: overflow,
            style: selecionado
                ? const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )
                : null,
          ),
        ),
        if (selecionado)
          const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
      ],
    ),
  );
}

/// Dropdown personalizado
Widget dropdownEstilizado({
  required List<String> opcoes,
  required String? valorSelecionado,
  required ValueChanged<String> onSelecionar,
  String hint = 'Selecione...',
  bool compacto = false,
  bool habilitado = true,
  IconData? icone,
  String? rotuloNovo,
  VoidCallback? onNovo,
}) {
  return _DropdownEstilizado(
    opcoes: opcoes,
    valorSelecionado: valorSelecionado,
    onSelecionar: onSelecionar,
    hint: hint,
    compacto: compacto,
    habilitado: habilitado,
    icone: icone,
    rotuloNovo: rotuloNovo,
    onNovo: onNovo,
  );
}

class _DropdownEstilizado extends StatefulWidget {
  final List<String> opcoes;
  final String? valorSelecionado;
  final ValueChanged<String> onSelecionar;
  final String hint;
  final bool compacto;
  final bool habilitado;
  final IconData? icone;
  final String? rotuloNovo;
  final VoidCallback? onNovo;

  const _DropdownEstilizado({
    required this.opcoes,
    required this.valorSelecionado,
    required this.onSelecionar,
    required this.hint,
    required this.compacto,
    required this.habilitado,
    required this.icone,
    required this.rotuloNovo,
    required this.onNovo,
  });

  @override
  State<_DropdownEstilizado> createState() => _DropdownEstilizadoState();
}

class _DropdownEstilizadoState extends State<_DropdownEstilizado> {
  bool _aberto = false;
  static const _novo = '\u0000novo'; // Valor reservado do item "Novo"

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.habilitado,
      child: Opacity(
        opacity: widget.habilitado ? 1 : 0.55,
        child: PopupMenuEstilizado<String>(
          onOpened: () => setState(() => _aberto = true),
          onCanceled: () => setState(() => _aberto = false),
          onSelected: (valor) {
            setState(() => _aberto = false);
            if (valor == _novo) {
              widget.onNovo?.call();
              return;
            }
            widget.onSelecionar(valor);
          },
          itemBuilder: (context) => [
            for (final o in widget.opcoes)
              popupMenuItemTexto<String>(
                value: o,
                texto: o,
                selecionado: o == widget.valorSelecionado,
                habilitado: o != widget.valorSelecionado,
              ),
            if (widget.onNovo != null) ...[
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: _novo,
                mouseCursor: SystemMouseCursors.click,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.rotuloNovo ?? 'Novo',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          child: HoverAnimado(
            raio: 14,
            cursor: SystemMouseCursors.click,
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: widget.hint,
                isDense: widget.compacto,
                fillColor: widget.habilitado ? null : AppColors.disabledFill,
                contentPadding: widget.compacto
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 14)
                    : null,
              ),
              child: Row(
                children: [
                  if (widget.icone != null) ...[
                    Icon(
                      widget.icone,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.valorSelecionado ?? widget.hint,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.compacto ? 13 : null,
                        fontWeight: widget.compacto ? FontWeight.w600 : null,
                        color: widget.valorSelecionado == null
                            ? AppColors.textSecondary
                            : (widget.compacto
                                  ? AppColors.primary
                                  : AppColors.textPrimary),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _aberto ? 0.5 : 0,
                    duration: AppMotion.fade,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: widget.compacto ? 20 : 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + leve escala saindo do topo, usando a animação recebida.
class _TransicaoMenu extends StatelessWidget {
  final Animation<double> animacao;
  final Widget child;

  const _TransicaoMenu({required this.animacao, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animacao,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(animacao),
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}
