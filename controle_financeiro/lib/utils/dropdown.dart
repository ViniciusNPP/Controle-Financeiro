import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lista de opções flutuante (Material + ListView de ListTile), no mesmo
/// visual usado pelo Autocomplete de categoria do FiltroBuilder. Usada tanto
/// por [dropdownEstilizado] quanto por [autocompleteEstilizado].
Widget _listaOpcoes({
  required List<String> opcoes,
  required ValueChanged<String> onSelected,
}) {
  return Align(
    alignment: Alignment.topLeft,
    child: Material(
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
    ),
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
        _listaOpcoes(opcoes: options.toList(), onSelected: onSelected),
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

class _DropdownEstilizadoState extends State<_DropdownEstilizado> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  void _alternar() {
    if (_overlay != null) {
      _fechar();
      return;
    }
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

  void _fechar() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _fechar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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