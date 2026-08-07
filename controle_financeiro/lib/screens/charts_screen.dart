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
  int _totalPaginas = 0;
  late PageController _pageController;

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
        titulo: 'Entradas',
        dados: entradasPorBalde,
        agruparPorAno: filtro.agruparPorAno,
        cor: AppColors.entrada,
      ),
      BarChartCard(
        titulo: 'Saídas',
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

    final graficosCarrossel = [
      graficos[2], // Saldo
      graficos[0], // Entradas
      graficos[1], // Saídas
      graficos[3], // Saídas específicas
      graficos[4], // Entradas específicas
    ];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraSuficiente = constraints.maxWidth >= 500;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (larguraSuficiente) ...[
              Text('Gráficos', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
            ],
            PeriodSelector(
              todasTransacoes: transacoes,
              onChanged: (f) => setState(() => _filtro = f),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, restante) {
                  const alturaMinimaGrade = 380.0; // ajuste esse número se quiser trocar
                  final alturaSuficiente = restante.maxHeight >= alturaMinimaGrade;
                  final usarGrade = larguraSuficiente && alturaSuficiente;
                  return usarGrade ? _gradeDesktop(graficos) : _carrosselMobile(graficosCarrossel);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _gradeDesktop(List<Widget> graficos) {
    const espacamento = 16.0;
    return Column(
      children: [
        Expanded(
          flex: 280,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: graficos[0]),
              const SizedBox(width: espacamento),
              Expanded(child: graficos[1]),
              const SizedBox(width: espacamento),
              Expanded(child: graficos[2]),
            ],
          ),
        ),
        const SizedBox(height: espacamento),
        Expanded(
          flex: 320,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: graficos[3]),
              const SizedBox(width: espacamento),
              Expanded(child: graficos[4]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _carrosselMobile(List<Widget> graficos) {
    _pageController = PageController(initialPage: _paginaAtual);
    _totalPaginas = graficos.length;
    
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() {
                  _paginaAtual = i;
                  // print("Página atual: $_paginaAtual");
                }),
                children: [for (final g in graficos) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: g)],
              ),
              Positioned(left: 0, child: _setaCarrossel(Icons.chevron_left_rounded, () => _navegarPagina(-1))),
              Positioned(right: 0, child: _setaCarrossel(Icons.chevron_right_rounded, () => _navegarPagina(1))),
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

  void _navegarPagina(int direcao) {
    final naPonta = direcao < 0 ? _paginaAtual == 0 : _paginaAtual == _totalPaginas - 1;
    if (naPonta) {
      final destino = direcao < 0 ? _totalPaginas - 1 : 0;
      _pageController.animateToPage(destino, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    } else if (direcao < 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

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