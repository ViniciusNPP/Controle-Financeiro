import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/categoria.dart';
import '../models/transacao.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/period_utils.dart';

class BarChartCard extends StatefulWidget {
  final String titulo;
  final List<Transacao> transacoes;
  final FiltroPeriodo filtro;
  final Color cor;
  final double? alturaFixa;
  final bool destaque;
  final TipoLancamento? tipo;
  final List<Categoria>? categorias;
  final String? categoriaInicial;
  final ValueChanged<String?>? onCategoriaChanged;

  final void Function(DateTime data1, DateTime data2, String? categoria)?
  onAbrirHistorico;

  const BarChartCard({
    super.key,
    required this.titulo,
    required this.transacoes,
    required this.filtro,
    required this.cor,
    this.alturaFixa,
    this.destaque = false,
    this.tipo,
    this.categorias,
    this.onAbrirHistorico,
    this.categoriaInicial,
    this.onCategoriaChanged,
  });

  @override
  State<BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<BarChartCard> {
  // null = "Todas" (sem filtro de categoria).
  late String? _categoriaSelecionada = widget.categoriaInicial;
  bool _seletorAberto = false;

  // Detecção manual de duplo clique numa barra
  static const _janelaDuploClique = Duration(milliseconds: 350);
  int? _ultimoIndiceTocado;
  DateTime? _instanteUltimoToque;
  DateTime? _baldeFixado;
  DateTime? _baldeHover; // barra sob o mouse

  bool get _temSeletor => widget.tipo != null && widget.categorias != null;

  /// Soma, por balde (mês ou ano, conforme widget.filtro), as transações relevantes
  Map<DateTime, double> _dadosAgregados() {
    final baldes = PeriodoUtils.baldes(widget.filtro);
    final mapa = {for (final b in baldes) b: 0.0};
    final categoria = _categoriaSelecionada;

    for (final t in widget.transacoes) {
      if (widget.tipo != null && t.tipo != widget.tipo) continue;
      if (!widget.filtro.contem(t.data)) continue;
      if (categoria != null && t.categoriaNome != categoria) continue;

      final chave = widget.filtro.agruparPorAno
          ? DateTime(t.data.year)
          : PeriodoUtils.primeiroDiaDoMes(t.data);
      if (!mapa.containsKey(chave)) continue;

      final sinal = (widget.tipo == null && t.tipo == TipoLancamento.saida)
          ? -1
          : 1;
      mapa[chave] = mapa[chave]! + t.valor * sinal;
    }
    return mapa;
  }

  void _selecionarCategoria(String? categoria) {
    if (categoria == _categoriaSelecionada) return;
    setState(() => _categoriaSelecionada = categoria);
    widget.onCategoriaChanged?.call(categoria);
  }

  /// Clique simples: fixa/solta o valor da barra. Duplo clique: abre o Histórico.
  void _registrarToqueBarra(int indice, DateTime balde) {
    final agora = DateTime.now();
    final ultimoIndice = _ultimoIndiceTocado;
    final ultimoInstante = _instanteUltimoToque;

    // Sem onAbrirHistorico (gráfico de Saldo) não existe duplo clique.
    final ehDuploClique =
        widget.onAbrirHistorico != null &&
        ultimoIndice == indice &&
        ultimoInstante != null &&
        agora.difference(ultimoInstante) <= _janelaDuploClique;

    if (ehDuploClique) {
      _ultimoIndiceTocado = null;
      _instanteUltimoToque = null;

      final (data1, data2) = PeriodoUtils.intervaloDoBalde(
        balde,
        widget.filtro.agruparPorAno,
      );
      widget.onAbrirHistorico!(data1, data2, _categoriaSelecionada);
      return;
    }

    _ultimoIndiceTocado = indice;
    _instanteUltimoToque = agora;
    // Clicar de novo na mesma barra solta o valor; em outra barra, move a fixação.
    setState(() {
      _baldeHover =
          null; // o clique tem efeito imediato, mesmo com o mouse em cima
      _baldeFixado = _baldeFixado == balde ? null : balde;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se a categoria selecionada deixou de existir volta para "Todas"
    if (_categoriaSelecionada != null &&
        widget.categorias != null &&
        !widget.categorias!.any((c) => c.nome == _categoriaSelecionada)) {
      _categoriaSelecionada = null;
    }

    final dados = _dadosAgregados();
    final chaves = dados.keys.toList()..sort();
    final valores = chaves.map((k) => dados[k] ?? 0).toList();
    final total = valores.fold<double>(0, (a, b) => a + b);

    final quantidadeBarras = valores.length;

    // Posição da barra fixada (-1 = nenhuma)
    final posicaoFixada = _baldeFixado == null
        ? -1
        : chaves.indexOf(_baldeFixado!);
    if (_baldeFixado != null && posicaoFixada < 0) _baldeFixado = null;

    final posicaoHover = _baldeHover == null
        ? -1
        : chaves.indexOf(_baldeHover!);

    final minValor = valores.isEmpty
        ? 0.0
        : valores.reduce((a, b) => a < b ? a : b);
    final maxValor = valores.isEmpty
        ? 0.0
        : valores.reduce((a, b) => a > b ? a : b);
    final minY = minValor < 0 ? minValor * 1.2 : 0.0;
    var maxY = maxValor > 0 ? maxValor * 1.2 : 1.0;
    if (maxY <= minY) maxY = minY + 1;

    final corTexto = widget.destaque ? Colors.white : AppColors.textPrimary;
    final corTextoSecundario = widget.destaque
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.textSecondary;
    final corBarra = widget.destaque ? Colors.white : widget.cor;
    final corLinhaZero = widget.destaque
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.grey.withValues(alpha: 0.55);

    final chaveFade = Object.hash(
      widget.filtro.inicio,
      widget.filtro.fimExclusivo,
      widget.filtro.agruparPorAno,
      _categoriaSelecionada,
    );
    final larguraBarra = chaves.length > 8 ? 10.0 : 20.0;
    // Barra branca (Saldo) não tem como clarear, então escurece um pouco.
    final corBarraHover = widget.destaque
        ? Colors.white.withValues(alpha: 0.8)
        : Color.lerp(corBarra, Colors.white, 0.2)!;

    final Widget conteudo = Container(
      padding: const EdgeInsets.all(20),
      height: widget.alturaFixa,
      decoration: widget.destaque
          ? BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF423DA0)],
              ),
              borderRadius: BorderRadius.circular(20),
            )
          : AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 80,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _temSeletor
                      ? _cabecalhoComSeletor(corTextoSecundario)
                      : Text(
                          widget.titulo,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: corTextoSecundario,
                          ),
                        ),
                  const SizedBox(height: 4),
                  TrocaFade(
                    chave: chaveFade,
                    child: Text(
                      Formatters.moeda(total),
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(color: corTexto),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 160,
            child: chaves.isEmpty
                ? Center(
                    child: Text(
                      'Sem lançamentos no período',
                      style: TextStyle(color: corTextoSecundario, fontSize: 13),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      minY: minY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 0,
                            color: corLinhaZero,
                            strokeWidth: 1,
                            dashArray: [6, 4],
                          ),
                        ],
                      ),
                      barTouchData: BarTouchData(
                        handleBuiltInTouches: false,
                        mouseCursorResolver: (event, response) =>
                            response?.spot == null
                            ? MouseCursor.defer
                            : SystemMouseCursors.click,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                              BarTooltipItem(
                                Formatters.moeda(rod.toY),
                                TextStyle(
                                  color: widget.destaque
                                      ? AppColors.primary
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                        ),
                        touchCallback: (event, response) {
                          final indice = response?.spot?.touchedBarGroupIndex;
                          final valido =
                              indice != null &&
                              indice >= 0 &&
                              indice < chaves.length;

                          // Mouse passando por cima: mostra o valor temporariamente.
                          if (event is FlPointerHoverEvent ||
                              event is FlPointerEnterEvent ||
                              event is FlPointerExitEvent) {
                            final novo =
                                (event is FlPointerExitEvent || !valido)
                                ? null
                                : chaves[indice];
                            if (novo != _baldeHover) {
                              setState(() => _baldeHover = novo);
                            }
                            return;
                          }

                          // Clique simples: fixa/solta. Duplo clique: abre o Histórico.
                          if (event is FlTapUpEvent && valido) {
                            _registrarToqueBarra(indice, chaves[indice]);
                          }
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= quantidadeBarras)
                                return const SizedBox.shrink();
                              final rotulo = PeriodoUtils.rotuloBalde(
                                chaves[i],
                                widget.filtro.agruparPorAno,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  rotulo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: corTextoSecundario,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < quantidadeBarras; i++)
                          BarChartGroupData(
                            x: i,
                            showingTooltipIndicators:
                                (i == posicaoFixada || i == posicaoHover)
                                ? [0]
                                : const [],
                            barRods: [
                              BarChartRodData(
                                toY: valores[i],
                                color: i == posicaoHover
                                    ? corBarraHover
                                    : corBarra,
                                width: i == posicaoHover
                                    ? larguraBarra * 1.2
                                    : larguraBarra,
                                borderRadius: valores[i] >= 0
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      )
                                    : const BorderRadius.vertical(
                                        bottom: Radius.circular(6),
                                      ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    duration: AppMotion.hover,
                    curve: Curves.ease,
                  ),
          ),
        ],
      ),
    );

    return conteudo;
  }

  static const _valorTodas = '__todas__';

  Widget _cabecalhoComSeletor(Color corTexto) {
    final rotuloAtual = _categoriaSelecionada ?? 'Todas';
    return PopupMenuButton<String>(
      tooltip: '',
      popUpAnimationStyle: AppMotion.estiloDropdown,
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(maxHeight: 280, minWidth: 160),
      onOpened: () => setState(() => _seletorAberto = true),
      onCanceled: () => setState(() => _seletorAberto = false),
      onSelected: (valor) {
        setState(() => _seletorAberto = false);
        _selecionarCategoria(valor == _valorTodas ? null : valor);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(value: _valorTodas, child: Text('Todas')),
        for (final c in widget.categorias!)
          PopupMenuItem<String>(value: c.nome, child: Text(c.nome)),
      ],
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.titulo}: $rotuloAtual ${_seletorAberto ? '▴' : '▾'}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: corTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
