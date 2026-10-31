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

/// Dropdown personalizado
Widget dropdownEstilizado({
  required List<String> opcoes,
  required String? valorSelecionado,
  required ValueChanged<String> onSelecionar,
  String hint = 'Selecione...',
  bool compacto = false,
}) {
  return _DropdownEstilizado(
    opcoes: opcoes,
    valorSelecionado: valorSelecionado,
    onSelecionar: onSelecionar,
    hint: hint,
    compacto: compacto,
  );
}

class _DropdownEstilizado extends StatefulWidget {
  final List<String> opcoes;
  final String? valorSelecionado;
  final ValueChanged<String> onSelecionar;
  final String hint;
  final bool compacto;

  const _DropdownEstilizado({
    required this.opcoes,
    required this.valorSelecionado,
    required this.onSelecionar,
    required this.hint,
    required this.compacto,
  });

  @override
  State<_DropdownEstilizado> createState() => _DropdownEstilizadoState();
}

class _DropdownEstilizadoState extends State<_DropdownEstilizado> {
  bool _aberto = false;

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
          child: PopupMenuButton<String>(
            tooltip: '',
            popUpAnimationStyle: AppMotion.estiloDropdown,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            constraints: restricao,
            onOpened: () => setState(() => _aberto = true),
            onCanceled: () => setState(() => _aberto = false),
            onSelected: (valor) {
              setState(() => _aberto = false);
              widget.onSelecionar(valor);
            },
            itemBuilder: (context) => [
              for (final o in widget.opcoes)
                PopupMenuItem<String>(
                  value: o,
                  child: Text(
                    o,
                    style: o == widget.valorSelecionado
                        ? const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ),
            ],
            child: HoverAnimado(
              raio: 14,
              cursor: SystemMouseCursors.click,
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: widget.hint,
                  isDense: widget.compacto,
                  contentPadding: widget.compacto
                      ? const EdgeInsets.symmetric(horizontal: 12, vertical: 14)
                      : null,
                ),
                child: Row(
                  children: [
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
        );
      },
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
