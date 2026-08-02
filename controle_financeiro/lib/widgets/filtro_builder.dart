import 'package:controle_financeiro/widgets/botoes_personalizados.dart';
import 'package:controle_financeiro/widgets/month_year_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/filtro_historico.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class FiltroBuilder extends StatefulWidget {
  final List<FiltroHistorico> filtrosAtivos;
  final List<String> sugestoesCategorias;
  final ValueChanged<FiltroHistorico> onAdicionar;
  final ValueChanged<String> onRemover;
  final ValueChanged<FiltroHistorico?> onFiltroRapidoChanged;

  const FiltroBuilder({
    super.key,
    required this.filtrosAtivos,
    required this.sugestoesCategorias,
    required this.onAdicionar,
    required this.onRemover,
    required this.onFiltroRapidoChanged,
  });

  @override
  State<FiltroBuilder> createState() => _FiltroBuilderState();
}

enum _ModoData { meses, anos, personalizado }

class _FiltroBuilderState extends State<FiltroBuilder> {
  CampoFiltro _campo = CampoFiltro.categoria;
  final _campo1Controller = TextEditingController();
  final _campo2Controller = TextEditingController();
  final _data1Controller = TextEditingController();
  final _data2Controller = TextEditingController();
  TextEditingController? _autocompleteController;
  String? _tipoSelecionado;
  Operador _operador = Operador.maior;
  DateTime? _data1;
  DateTime? _data2;
  _ModoData _modoData = _ModoData.meses;
  DateTime _mesFiltro = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _anoFiltro = DateTime(DateTime.now().year);

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
    _tipoSelecionado = null;
    _data1 = null;
    _data2 = null;
    _operador = Operador.maior;
  }

  double? _parseNumero(String texto) {
    if (texto.trim().isEmpty) return null;
    final limpo = texto.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  FiltroHistorico? _construirFiltro({required String id}) {
    if (_campo == CampoFiltro.tipo) {
      if (_tipoSelecionado == null) return null;
      return FiltroHistorico(id: id, campo: _campo, texto: _tipoSelecionado!);
    }
    if (_campo == CampoFiltro.categoria) {
      final texto = (_autocompleteController?.text ?? '').trim();
      if (texto.isEmpty) return null;
      return FiltroHistorico(id: id, campo: _campo, texto: texto);
    }
    if (_campo == CampoFiltro.valor) {
      final n1 = _parseNumero(_campo1Controller.text);
      final n2 = _parseNumero(_campo2Controller.text);
      if (n1 == null && n2 == null) return null;
      return FiltroHistorico(id: id, campo: _campo, numero1: n1, numero2: n2, operador: _operador);
    }

    switch (_modoData) {
      case _ModoData.meses:
        final inicio = DateTime(_mesFiltro.year, _mesFiltro.month, 1);
        final fim = DateTime(_mesFiltro.year, _mesFiltro.month + 1, 0); // último dia do mês
        return FiltroHistorico(id: id, campo: _campo, data1: inicio, data2: fim, operador: _operador);
      case _ModoData.anos:
        final inicio = DateTime(_anoFiltro.year, 1, 1);
        final fim = DateTime(_anoFiltro.year, 12, 31);
        return FiltroHistorico(id: id, campo: _campo, data1: inicio, data2: fim, operador: _operador);
      case _ModoData.personalizado:
        if (_data1 == null && _data2 == null) return null;
        return FiltroHistorico(id: id, campo: _campo, data1: _data1, data2: _data2, operador: _operador);
    }
  }

  void _emitirFiltroRapido() {
    widget.onFiltroRapidoChanged(_construirFiltro(id: '__rapido__'));
  }

  void _adicionar() {
    final novo = _construirFiltro(id: 'f${DateTime.now().microsecondsSinceEpoch}');
    if (novo == null) return;
    widget.onAdicionar(novo);
    setState(_limparCampos);
    widget.onFiltroRapidoChanged(null); // campos foram limpos, cancela o rápido
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final c in CampoFiltro.values) _chipCampo(c)],
                ),
              ),
              if (_campo == CampoFiltro.data) ...[
                const SizedBox(width: 12),
                _botaoModoData(),
              ],
            ],
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
              style: ElevatedButton.styleFrom(
                enabledMouseCursor: SystemMouseCursors.click,
              ),
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
        onTap: () {
           setState(() {
            _campo = c;
            _limparCampos();
          });
          _emitirFiltroRapido();
        },
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
      return Row(
        children: [
          Expanded(
            child: botaoSelecionavel(
              label: 'Entrada',
              selecionado: _tipoSelecionado == 'Entrada',
              cor: AppColors.entrada,
              onTap: () {
                setState(() => _tipoSelecionado = 'Entrada');
                _emitirFiltroRapido();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: botaoSelecionavel(
              label: 'Saída',
              selecionado: _tipoSelecionado == 'Saída',
              cor: AppColors.saida,
              onTap: () {
                setState(() => _tipoSelecionado = 'Saída');
                _emitirFiltroRapido();
              },
            ),
          ),
        ],
      );
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
          onChanged: (_) => _emitirFiltroRapido(),
        ),
        campo2: TextField(
          controller: _campo2Controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'R\$', isDense: true),
          onChanged: (_) => _emitirFiltroRapido(),
        ),
      );
    }

    switch (_modoData) {
      case _ModoData.meses:
        return MonthYearNavigator(
          granularidade: GranularidadeNavegador.mes,
          valor: _mesFiltro,
          onChanged: (d) {
            setState(() => _mesFiltro = DateTime(d.year, d.month));
            _emitirFiltroRapido();
          },
        );
      case _ModoData.anos:
        return MonthYearNavigator(
          granularidade: GranularidadeNavegador.ano,
          valor: _anoFiltro,
          onChanged: (d) {
            setState(() => _anoFiltro = DateTime(d.year));
            _emitirFiltroRapido();
          },
        );
      case _ModoData.personalizado:
        return _linhaComparacao(
          campo1: _campoData(_data1Controller, _data1, (d) {
            _data1 = d;
            _emitirFiltroRapido();
          }),
          campo2: _campoData(_data2Controller, _data2, (d) {
            _data2 = d;
            _emitirFiltroRapido();
          }),
          operadoresPermitidos: Operador.values,
        );
    }
  }

  void _proximoModoData() {
    setState(() {
      final valores = _ModoData.values;
      _modoData = valores[(valores.indexOf(_modoData) + 1) % valores.length];
      _limparCampos();
    });
    _emitirFiltroRapido();
  }

  void _modoDataAnterior() {
    setState(() {
      final valores = _ModoData.values;
      final i = valores.indexOf(_modoData);
      _modoData = valores[(i - 1 + valores.length) % valores.length];
      _limparCampos();
    });
    _emitirFiltroRapido();
  }

  String get _rotuloModoData {
    switch (_modoData) {
      case _ModoData.meses:
        return 'Meses';
      case _ModoData.anos:
        return 'Anos';
      case _ModoData.personalizado:
        return 'Personalizado';
    }
  }

  Widget _botaoModoData() {
    return Tooltip(
      message: 'Clique para mudar · botão direito para voltar',
      child: GestureDetector(
        onSecondaryTap: _modoDataAnterior,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          onTap: _proximoModoData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: AppTheme.cardDecoration(),
            child: Text(
              _rotuloModoData,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ),
      ),
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
          onChanged: (_) => _emitirFiltroRapido(),
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

  Widget _linhaComparacao({
    required Widget campo1,
    required Widget campo2,
    List<Operador>? operadoresPermitidos,
  }) {
    final operadores = operadoresPermitidos ?? Operador.values;
    final valorDropdown = operadores.contains(_operador) ? _operador : operadores.first;
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
              value: valorDropdown,
              isDense: true,
              items: [
                for (final o in operadores)
                  DropdownMenuItem(value: o, child: Text(' ${o.simbolo} ', style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
              onChanged: (o) {
                setState(() => _operador = o ?? operadores.first);
                _emitirFiltroRapido();
              },
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
      keyboardType: TextInputType.number,
      inputFormatters: [_DataInputFormatter()],
      decoration: InputDecoration(
        hintText: 'dd/mm/aaaa',
        isDense: true,
        suffixIcon: IconButton(
          mouseCursor: SystemMouseCursors.click,
          icon: const Icon(Icons.calendar_today_rounded, size: 15),
          onPressed: () async {
            final escolhida = await showDatePicker(
              context: context,
              initialDate: valorAtual ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              locale: const Locale('pt', 'BR'), 
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    textButtonTheme: TextButtonThemeData(
                      style: estiloBotao(corForeGround: const Color(0xFF2e2a6e)),
                    ),
                    iconButtonTheme: IconButtonThemeData(style: estiloBotao()),
                  ),
                  child: child!,
                );
              },
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

/// Formata a digitação da data automaticamente
class _DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length > 8) digitos = digitos.substring(0, 8);

    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digitos[i]);
    }

    final formatado = buffer.toString();
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}