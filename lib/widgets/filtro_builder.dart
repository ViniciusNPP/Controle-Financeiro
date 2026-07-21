import 'package:flutter/material.dart';
import '../models/filtro_historico.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class FiltroBuilder extends StatefulWidget {
  final List<FiltroHistorico> filtrosAtivos;
  final List<String> sugestoesCategorias;
  final ValueChanged<FiltroHistorico> onAdicionar;
  final ValueChanged<String> onRemover;

  const FiltroBuilder({
    super.key,
    required this.filtrosAtivos,
    required this.sugestoesCategorias,
    required this.onAdicionar,
    required this.onRemover,
  });

  @override
  State<FiltroBuilder> createState() => _FiltroBuilderState();
}

class _FiltroBuilderState extends State<FiltroBuilder> {
  CampoFiltro _campo = CampoFiltro.categoria;
  final _campo1Controller = TextEditingController();
  final _campo2Controller = TextEditingController();
  final _data1Controller = TextEditingController();
  final _data2Controller = TextEditingController();
  TextEditingController? _autocompleteController;
  Operador _operador = Operador.igual;
  DateTime? _data1;
  DateTime? _data2;

  @override
  void dispose() {
    _campo1Controller.dispose();
    _campo2Controller.dispose();
    _data1Controller.dispose();
    _data2Controller.dispose();
    super.dispose();
  }

  void _limparCampos() {
    _campo1Controller.clear();
    _campo2Controller.clear();
    _data1Controller.clear();
    _data2Controller.clear();
    _autocompleteController?.clear();
    _data1 = null;
    _data2 = null;
    _operador = Operador.igual;
  }

  double? _parseNumero(String texto) {
    if (texto.trim().isEmpty) return null;
    final limpo = texto.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  void _adicionar() {
    final id = 'f${DateTime.now().microsecondsSinceEpoch}';
    FiltroHistorico? novo;

    if (_campo == CampoFiltro.tipo || _campo == CampoFiltro.categoria) {
      final texto = (_autocompleteController?.text ?? '').trim();
      if (texto.isEmpty) return;
      novo = FiltroHistorico(id: id, campo: _campo, texto: texto);
    } else if (_campo == CampoFiltro.valor) {
      final n1 = _parseNumero(_campo1Controller.text);
      final n2 = _parseNumero(_campo2Controller.text);
      if (n1 == null && n2 == null) return;
      novo = FiltroHistorico(id: id, campo: _campo, numero1: n1, numero2: n2, operador: _operador);
    } else {
      if (_data1 == null && _data2 == null) return;
      novo = FiltroHistorico(id: id, campo: _campo, data1: _data1, data2: _data2, operador: _operador);
    }

    widget.onAdicionar(novo);
    setState(_limparCampos);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in CampoFiltro.values) _chipCampo(c)],
          ),
          const SizedBox(height: 14),
          _campoDeEntrada(),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _adicionar,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar filtro'),
            ),
          ),
          if (widget.filtrosAtivos.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final f in widget.filtrosAtivos) _chipFiltroAtivo(f)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipCampo(CampoFiltro c) {
    final selecionado = _campo == c;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() {
          _campo = c;
          _limparCampos();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selecionado ? AppColors.primary : AppColors.disabledFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            c.rotulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selecionado ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoDeEntrada() {
    if (_campo == CampoFiltro.tipo) {
      return _autocomplete(const ['Entrada', 'Saída'], chave: const ValueKey('autocomplete_tipo'));
    }
    if (_campo == CampoFiltro.categoria) {
      return _autocomplete(widget.sugestoesCategorias, chave: const ValueKey('autocomplete_categoria'));
    }

    if (_campo == CampoFiltro.valor) {
      return _linhaComparacao(
        campo1: TextField(
          controller: _campo1Controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Igual a R\$', isDense: true),
        ),
        campo2: TextField(
          controller: _campo2Controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'R\$', isDense: true),
        ),
      );
    }

    return _linhaComparacao(
      campo1: _campoData(_data1Controller, _data1, (d) => _data1 = d),
      campo2: _campoData(_data2Controller, _data2, (d) => _data2 = d),
    );
  }

  Widget _autocomplete(List<String> opcoes, {required Key chave}) {
    return Autocomplete<String>(
      key: chave,
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return opcoes;
        return opcoes.where((o) => o.toLowerCase().contains(value.text.toLowerCase()));
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _autocompleteController = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(hintText: 'Buscar ${_campo.rotulo.toLowerCase()}...'),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
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
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final opcao = options.elementAt(i);
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
      },
    );
  }

  Widget _linhaComparacao({required Widget campo1, required Widget campo2}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: campo1),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: AppColors.disabledFill, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Operador>(
              value: _operador,
              isDense: true,
              items: [
                for (final o in Operador.values)
                  DropdownMenuItem(value: o, child: Text(' ${o.simbolo} ', style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
              onChanged: (o) => setState(() => _operador = o ?? Operador.igual),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: campo2),
      ],
    );
  }

  Widget _campoData(TextEditingController controller, DateTime? valorAtual, ValueChanged<DateTime?> onChanged) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'dd/mm/aaaa',
        isDense: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_rounded, size: 15),
          onPressed: () async {
            final escolhida = await showDatePicker(
              context: context,
              initialDate: valorAtual ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              locale: const Locale('pt', 'BR'),
            );
            if (escolhida != null) {
              controller.text = Formatters.data(escolhida);
              onChanged(escolhida);
            }
          },
        ),
      ),
      onChanged: (texto) {
        final partes = texto.split('/');
        if (partes.length == 3) {
          final d = int.tryParse(partes[0]);
          final m = int.tryParse(partes[1]);
          final a = int.tryParse(partes[2]);
          if (d != null && m != null && a != null && a > 1900 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
            onChanged(DateTime(a, m, d));
            return;
          }
        }
        onChanged(null);
      },
    );
  }

  Widget _chipFiltroAtivo(FiltroHistorico f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_rotuloFiltro(f), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(width: 6),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onRemover(f.id),
              child: const Icon(Icons.close_rounded, size: 15, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _rotuloFiltro(FiltroHistorico f) {
    switch (f.campo) {
      case CampoFiltro.tipo:
        return 'Tipo: ${f.texto}';
      case CampoFiltro.categoria:
        return 'Categoria: ${f.texto}';
      case CampoFiltro.valor:
        if (f.numero1 != null && f.numero2 != null) {
          return 'Valor entre ${Formatters.moeda(f.numero1!)} e ${Formatters.moeda(f.numero2!)}';
        }
        if (f.numero2 != null) return 'Valor ${f.operador.simbolo} ${Formatters.moeda(f.numero2!)}';
        return 'Valor = ${Formatters.moeda(f.numero1 ?? 0)}';
      case CampoFiltro.data:
        if (f.data1 != null && f.data2 != null) {
          return 'Data entre ${Formatters.data(f.data1!)} e ${Formatters.data(f.data2!)}';
        }
        if (f.data2 != null) return 'Data ${f.operador.simbolo} ${Formatters.data(f.data2!)}';
        return 'Data = ${Formatters.data(f.data1 ?? DateTime.now())}';
    }
  }
}
