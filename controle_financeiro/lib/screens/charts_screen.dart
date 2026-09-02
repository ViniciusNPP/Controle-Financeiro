import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/filtro_historico.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/navegacao_historico.dart';
import '../utils/period_utils.dart';
import '../widgets/period_selector.dart';
import '../widgets/chart_cards.dart';
import '../widgets/category_pie_chart.dart';

class ChartsScreen extends StatefulWidget {
  /// Chamado quando o usuário pede para ver aqueles lançamentos no Histórico.
  final void Function(List<FiltroHistorico> filtros)? onAbrirHistorico;

  const ChartsScreen({super.key, this.onAbrirHistorico});

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

  /// Monta os FiltroHistorico a partir do período inteiro atualmente selecionado nos Gráficos e dispara a navegação.
  void _abrirHistoricoPizza(FiltroPeriodo filtro, String categoria, TipoLancamento tipo) {
    final onAbrirHistorico = widget.onAbrirHistorico;
    if (onAbrirHistorico == null) return;

    final ultimoDiaIncluido = filtro.fimExclusivo.subtract(const Duration(days: 1));
    onAbrirHistorico(filtrosHistoricoDoGrafico(
      data1: filtro.inicio,
      data2: ultimoDiaIncluido,
      tipo: tipo,
      categoria: categoria,
    ));
  }

  /// Monta os FiltroHistorico a partir de um balde específico
  void _abrirHistoricoBarra(DateTime data1, DateTime data2, TipoLancamento tipo, String? categoria) {
    final onAbrirHistorico = widget.onAbrirHistorico;
    if (onAbrirHistorico == null) return;

    onAbrirHistorico(filtrosHistoricoDoGrafico(
      data1: data1,
      data2: data2,
      tipo: tipo,
      categoria: categoria,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final transacoes = finance.transacoes;
    final filtro = _filtro ?? PeriodoUtils.mes(DateTime.now());

    final saidasPorCategoria = Agregador.porCategoria(transacoes, filtro, TipoLancamento.saida);
    final entradasPorCategoria = Agregador.porCategoria(transacoes, filtro, TipoLancamento.entrada);
    final categoriasEntrada = finance.categoriasPorTipo(TipoLancamento.entrada);
    final categoriasSaida = finance.categoriasPorTipo(TipoLancamento.saida);

    final graficos = [
      BarChartCard(
        titulo: 'Entradas',
        transacoes: transacoes,
        filtro: filtro,
        cor: AppColors.entrada,
        tipo: TipoLancamento.entrada,
        categorias: categoriasEntrada,
        onAbrirHistorico: (data1, data2, categoria) =>
            _abrirHistoricoBarra(data1, data2, TipoLancamento.entrada, categoria),
      ),
      BarChartCard(
        titulo: 'Saídas',
        transacoes: transacoes,
        filtro: filtro,
        cor: AppColors.saida,
        tipo: TipoLancamento.saida,
        categorias: categoriasSaida,
        onAbrirHistorico: (data1, data2, categoria) =>
            _abrirHistoricoBarra(data1, data2, TipoLancamento.saida, categoria),
      ),
      BarChartCard(
        titulo: 'Saldo',
        transacoes: transacoes,
        filtro: filtro,
        cor: AppColors.saldo,
        destaque: true,
      ),
      CategoryPieChartCard(
        titulo: 'Saídas específicas (R\$)',
        dados: saidasPorCategoria,
        onAbrirHistorico: (categoria) => _abrirHistoricoPizza(filtro, categoria, TipoLancamento.saida),
      ),
      CategoryPieChartCard(
        titulo: 'Entradas específicas (R\$)',
        dados: entradasPorCategoria,
        onAbrirHistorico: (categoria) => _abrirHistoricoPizza(filtro, categoria, TipoLancamento.entrada),
      ),
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
                  const alturaMinimaGrade = 340.0; // ajuste esse número se quiser trocar
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
      color: Colors.black.withValues(alpha:0.06),
      shape: const CircleBorder(),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        customBorder: const CircleBorder(),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icone, size: 22, color: AppColors.textSecondary.withValues(alpha:0.8)),
        ),
      ),
    );
  }
}