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

/// Campo de texto com autocomplete
Widget autocompleteEstilizado({
  Key? key,
  required List<String> opcoes,
  required String hint,
  ValueChanged<TextEditingController>? aoCriarController,
  required ValueChanged<String> onChanged,
}) {
  return Autocomplete<String>(
    key: key,
    onSelected: (opcao) => onChanged(opcao),
    optionsBuilder: (TextEditingValue value) {
      if (value.text.isEmpty) return opcoes;
      return opcoes.where(
        (o) => o.toLowerCase().contains(value.text.toLowerCase()),
      );
    },
    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
      aoCriarController?.call(controller);
      return TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(hintText: hint),
        onChanged: onChanged,
      );
    },
    optionsViewBuilder: (context, onSelected, options) =>
        _OpcoesAnimadas(opcoes: options.toList(), onSelected: onSelected),
  );
}

/// Dropdown personalizado
Widget dropdownEstilizado({
  required List<String> opcoes,
  required String? valorSelecionado,
  required ValueChanged<String> onSelecionar,
  String hint = 'Selecione...',
}) {
  return _DropdownEstilizado(
    opcoes: opcoes,
    valorSelecionado: valorSelecionado,
    onSelecionar: onSelecionar,
    hint: hint,
  );
}

class _DropdownEstilizado extends StatefulWidget {
  final List<String> opcoes;
  final String? valorSelecionado;
  final ValueChanged<String> onSelecionar;
  final String hint;

  const _DropdownEstilizado({
    required this.opcoes,
    required this.valorSelecionado,
    required this.onSelecionar,
    required this.hint,
  });

  @override
  State<_DropdownEstilizado> createState() => _DropdownEstilizadoState();
}

class _DropdownEstilizadoState extends State<_DropdownEstilizado>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  late final AnimationController _controller;
  late final Animation<double> _curva;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.dropdownAbrir,
      reverseDuration: AppMotion.dropdownFechar,
    )..addStatusListener((status) {
        // O menu só sai da tela quando a animação de fechar termina.
        if (status == AnimationStatus.dismissed) _removerOverlay();
      });
    _curva = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curvaAbrir, // abrir: easeOut
      reverseCurve: AppMotion.curvaFechar, // fechar: ease
    );
  }

  bool get _aberto =>
      _overlay != null && _controller.status != AnimationStatus.reverse;

  void _alternar() => _aberto ? _fechar() : _abrir();

  void _abrir() {
    if (_overlay == null) {
      final renderBox = context.findRenderObject() as RenderBox;
      final tamanho = renderBox.size;

      _overlay = OverlayEntry(
        builder: (_) => Positioned(
          width: tamanho.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, tamanho.height + 4),
            child: _listaOpcoes(
              opcoes: widget.opcoes,
              animacao: _curva,
              onSelected: (opcao) {
                widget.onSelecionar(opcao);
                _fechar();
              },
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlay!);
    }
    _controller.forward();
  }

  void _fechar() {
    if (_overlay == null) return;
    _controller.reverse();
  }

  void _removerOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _removerOverlay();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: HoverAnimado(
        raio: 14,
        child: GestureDetector(
          onTap: _alternar,
          child: InputDecorator(
            decoration: InputDecoration(hintText: widget.hint),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.valorSelecionado ?? widget.hint,
                    style: TextStyle(
                      color: widget.valorSelecionado != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
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

/// Lista do autocomplete com animação easeOut.
class _OpcoesAnimadas extends StatefulWidget {
  final List<String> opcoes;
  final ValueChanged<String> onSelected;

  const _OpcoesAnimadas({required this.opcoes, required this.onSelected});

  @override
  State<_OpcoesAnimadas> createState() => _OpcoesAnimadasState();
}

class _OpcoesAnimadasState extends State<_OpcoesAnimadas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curva;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.dropdownAbrir,
    );
    _curva = CurvedAnimation(parent: _controller, curve: AppMotion.curvaAbrir);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _listaOpcoes(
    opcoes: widget.opcoes,
    onSelected: widget.onSelected,
    animacao: _curva,
  );
}