import 'package:controle_financeiro/widgets/month_year_navigator.dart';
import 'package:flutter/material.dart';
import '../models/transacao.dart';
import '../theme/app_theme.dart';
import '../utils/period_utils.dart';

enum _ModoPeriodo { mensal, anual }

enum _GranMensal { mes, bimestre, trimestre, semestre, todoPeriodo, personalizado }

enum _GranAnual { ano, todoPeriodo, personalizado }

class PeriodSelector extends StatefulWidget {
  final List<Transacao> todasTransacoes;
  final ValueChanged<FiltroPeriodo> onChanged;

  const PeriodSelector({super.key, required this.todasTransacoes, required this.onChanged});

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  _ModoPeriodo _modo = _ModoPeriodo.mensal;
  _GranMensal _granMensal = _GranMensal.mes;
  _GranAnual _granAnual = _GranAnual.ano;

  late DateTime _mesReferencia;
  late DateTime _mesPersonalizadoDe;
  late DateTime _mesPersonalizadoAte;
  late int _anoReferencia;
  late int _anoPersonalizadoDe;
  late int _anoPersonalizadoAte;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mesReferencia = DateTime(agora.year, agora.month);
    _mesPersonalizadoDe = DateTime(agora.year, agora.month);
    _mesPersonalizadoAte = DateTime(agora.year, agora.month);
    _anoReferencia = agora.year;
    _anoPersonalizadoDe = agora.year;
    _anoPersonalizadoAte = agora.year;
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitir());
  }

  List<DateTime> get _todasAsDatas => widget.todasTransacoes.map((t) => t.data).toList();

  void _emitir() {
    late FiltroPeriodo filtro;
    if (_modo == _ModoPeriodo.mensal) {
      switch (_granMensal) {
        case _GranMensal.mes:
          filtro = PeriodoUtils.mes(_mesReferencia);
          break;
        case _GranMensal.bimestre:
          filtro = PeriodoUtils.janelaMeses(_mesReferencia, 2);
          break;
        case _GranMensal.trimestre:
          filtro = PeriodoUtils.janelaMeses(_mesReferencia, 3);
          break;
        case _GranMensal.semestre:
          filtro = PeriodoUtils.janelaMeses(_mesReferencia, 6);
          break;
        case _GranMensal.todoPeriodo:
          filtro = PeriodoUtils.todoPeriodoMensal(_todasAsDatas);
          break;
        case _GranMensal.personalizado:
          filtro = PeriodoUtils.mesesPersonalizado(_mesPersonalizadoDe, _mesPersonalizadoAte);
          break;
      }
    } else {
      switch (_granAnual) {
        case _GranAnual.ano:
          filtro = PeriodoUtils.ano(_anoReferencia);
          break;
        case _GranAnual.todoPeriodo:
          filtro = PeriodoUtils.todoPeriodoAnual(_todasAsDatas);
          break;
        case _GranAnual.personalizado:
          filtro = PeriodoUtils.anosPersonalizado(_anoPersonalizadoDe, _anoPersonalizadoAte);
          break;
      }
    }
    widget.onChanged(filtro);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seletorModo(),
          const SizedBox(height: 12),
          _modo == _ModoPeriodo.mensal ? _chipsMensal() : _chipsAnual(),
          const SizedBox(height: 12),
          _modo == _ModoPeriodo.mensal ? _controlesMensal() : _controlesAnual(),
        ],
      ),
    );
  }

  Widget _seletorModo() {
    return Row(
      children: [
        _botaoModo('Mensal', _ModoPeriodo.mensal),
        const SizedBox(width: 8),
        _botaoModo('Anual', _ModoPeriodo.anual),
      ],
    );
  }

  Widget _botaoModo(String label, _ModoPeriodo modo) {
    final selecionado = _modo == modo;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _modo = modo);
          _emitir();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selecionado ? AppColors.primary : AppColors.disabledFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selecionado ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selecionado, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selecionado ? AppColors.primaryLight.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selecionado ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selecionado ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipsMensal() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('Mês', _granMensal == _GranMensal.mes, () => _setGran(mensal: _GranMensal.mes)),
        _chip('Bimestre', _granMensal == _GranMensal.bimestre, () => _setGran(mensal: _GranMensal.bimestre)),
        _chip('Trimestre', _granMensal == _GranMensal.trimestre, () => _setGran(mensal: _GranMensal.trimestre)),
        _chip('Semestre', _granMensal == _GranMensal.semestre, () => _setGran(mensal: _GranMensal.semestre)),
        _chip('Todo o período', _granMensal == _GranMensal.todoPeriodo, () => _setGran(mensal: _GranMensal.todoPeriodo)),
        _chip('Personalizado', _granMensal == _GranMensal.personalizado, () => _setGran(mensal: _GranMensal.personalizado)),
      ],
    );
  }

  Widget _chipsAnual() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('Ano', _granAnual == _GranAnual.ano, () => _setGran(anual: _GranAnual.ano)),
        _chip('Todo o período', _granAnual == _GranAnual.todoPeriodo, () => _setGran(anual: _GranAnual.todoPeriodo)),
        _chip('Personalizado', _granAnual == _GranAnual.personalizado, () => _setGran(anual: _GranAnual.personalizado)),
      ],
    );
  }

  void _setGran({_GranMensal? mensal, _GranAnual? anual}) {
  setState(() {
    if (mensal != null) _granMensal = mensal;
    if (anual != null) _granAnual = anual;
  });
  _emitir();
}

  Widget _controlesMensal() {
    if (_granMensal == _GranMensal.todoPeriodo) return const SizedBox.shrink();
    if (_granMensal == _GranMensal.personalizado) {
      return Row(
        children: [
          Expanded(child: _seletor('De', valorMes: _mesPersonalizadoDe, setMes: (d) => _mesPersonalizadoDe = d, abreviado: true)),
          const SizedBox(width: 12),
          Expanded(child: _seletor('Até', valorMes: _mesPersonalizadoAte, setMes: (d) => _mesPersonalizadoAte = d, abreviado: true)),
        ],
      );
    }
    return _seletor(null, valorMes: _mesReferencia, setMes: (d) => _mesReferencia = d);
  }

  Widget _controlesAnual() {
    if (_granAnual == _GranAnual.todoPeriodo) return const SizedBox.shrink();
    if (_granAnual == _GranAnual.personalizado) {
      return Row(
        children: [
          Expanded(child: _seletor('De', valorAno: _anoPersonalizadoDe, setAno: (a) => _anoPersonalizadoDe = a)),
          const SizedBox(width: 12),
          Expanded(child: _seletor('Até', valorAno: _anoPersonalizadoAte, setAno: (a) => _anoPersonalizadoAte = a)),
        ],
      );
    }
    return _seletor(null, valorAno: _anoReferencia, setAno: (a) => _anoReferencia = a);
  }

  Widget _seletor(
    String? rotulo, 
    {DateTime? valorMes, int? 
    valorAno, void Function(DateTime)? 
    setMes, void Function(int)? setAno, 
    bool abreviado = false
    }) {
      
    assert(
      (valorMes != null && setMes != null && valorAno == null && setAno == null) ||
      (valorAno != null && setAno != null && valorMes == null && setMes == null),
      'Passe exatamente um par: (valorMes + setMes) ou (valorAno + setAno), nunca os dois nem nenhum.',
    );

    final ehMes = valorMes != null;
    return MonthYearNavigator(
      granularidade: ehMes ? GranularidadeNavegador.mes : GranularidadeNavegador.ano,
      valor: ehMes ? valorMes : DateTime(valorAno!),
      rotulo: rotulo,
      abreviado: abreviado,
      onChanged: (d) {
        setState(() => ehMes ? setMes!(DateTime(d.year, d.month)) : setAno!(d.year));
        _emitir();
      },
    );
  }
}
