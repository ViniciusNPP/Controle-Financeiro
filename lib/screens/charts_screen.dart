import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/period_utils.dart';
import '../widgets/period_selector.dart';
import '../widgets/chart_cards.dart';
import '../widgets/category_pie_chart.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  FiltroPeriodo? _filtro;
  int _paginaAtual = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final transacoes = finance.transacoes;
    final filtro = _filtro ?? PeriodoUtils.mes(DateTime.now());

    final entradasPorBalde = Agregador.porBalde(transacoes, filtro, TipoLancamento.entrada);
    final saidasPorBalde = Agregador.porBalde(transacoes, filtro, TipoLancamento.saida);
    final saldoPorBalde = Agregador.saldoPorBalde(transacoes, filtro);
    final saidasPorCategoria = Agregador.porCategoria(transacoes, filtro, TipoLancamento.saida);
    final entradasPorCategoria = Agregador.porCategoria(transacoes, filtro, TipoLancamento.entrada);

    final graficos = [
      BarChartCard(
        titulo: 'Entradas gerais',
        dados: entradasPorBalde,
        agruparPorAno: filtro.agruparPorAno,
        cor: AppColors.entrada,
      ),
      BarChartCard(
        titulo: 'Saídas gerais',
        dados: saidasPorBalde,
        agruparPorAno: filtro.agruparPorAno,
        cor: AppColors.saida,
      ),
      BarChartCard(
        titulo: 'Saldo',
        dados: saldoPorBalde,
        agruparPorAno: filtro.agruparPorAno,
        cor: AppColors.saldo,
        destaque: true,
      ),
      CategoryPieChartCard(titulo: 'Saídas específicas', dados: saidasPorCategoria),
      CategoryPieChartCard(titulo: 'Entradas específicas', dados: entradasPorCategoria),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop) ...[
              Text('Gráficos', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
            ],
            PeriodSelector(
              todasTransacoes: transacoes,
              onChanged: (f) => setState(() => _filtro = f),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isDesktop ? _gradeDesktop(graficos) : _carrosselMobile(graficos),
            ),
          ],
        );
      },
    );
  }

  Widget _gradeDesktop(List<Widget> graficos) {
    return SingleChildScrollView(
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SizedBox(height: 280, child: graficos[0])),
                const SizedBox(width: 16),
                Expanded(child: SizedBox(height: 280, child: graficos[1])),
                const SizedBox(width: 16),
                Expanded(child: SizedBox(height: 280, child: graficos[2])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SizedBox(height: 320, child: graficos[3])),
                const SizedBox(width: 16),
                Expanded(child: SizedBox(height: 320, child: graficos[4])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carrosselMobile(List<Widget> graficos) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _paginaAtual = i),
                children: [for (final g in graficos) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: g)],
              ),
              if (_paginaAtual > 0)
                Positioned(left: 0, child: _setaCarrossel(Icons.chevron_left_rounded, _paginaAnterior)),
              if (_paginaAtual < graficos.length - 1)
                Positioned(right: 0, child: _setaCarrossel(Icons.chevron_right_rounded, _proximaPagina)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < graficos.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _paginaAtual == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _paginaAtual == i ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _paginaAnterior() {
    _pageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  void _proximaPagina() {
    _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  /// Seta discreta: fundo translúcido, some quando não há mais pra onde ir
  /// (controlado pelo chamador via _paginaAtual), fica sutil até ser tocada.
  Widget _setaCarrossel(IconData icone, VoidCallback aoTocar) {
    return Material(
      color: Colors.black.withOpacity(0.06),
      shape: const CircleBorder(),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        customBorder: const CircleBorder(),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icone, size: 22, color: AppColors.textSecondary.withOpacity(0.8)),
        ),
      ),
    );
  }
}