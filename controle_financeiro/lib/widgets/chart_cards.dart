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

  final void Function(DateTime data1, DateTime data2, String? categoria)? onAbrirHistorico;

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
  });

  @override
  State<BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<BarChartCard> {
  // null = "Todas" (sem filtro de categoria).
  String? _categoriaSelecionada;

  // Detecção manual de duplo clique numa barra
  static const _janelaDuploClique = Duration(milliseconds: 350);
  int? _ultimoIndiceTocado;
  DateTime? _instanteUltimoToque;

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

      final sinal = (widget.tipo == null && t.tipo == TipoLancamento.saida) ? -1 : 1;
      mapa[chave] = mapa[chave]! + t.valor * sinal;
    }
    return mapa;
  }

  void _selecionarCategoria(String? categoria) {
    if (categoria == _categoriaSelecionada) return;
    setState(() => _categoriaSelecionada = categoria);
  }

  /// Reconhece duplo clique comparando o índice tocado agora com o último, e o tempo decorrido com _janelaDuploClique.
  void _registrarToqueBarra(int indice, DateTime balde) {
    final agora = DateTime.now();
    final ultimoIndice = _ultimoIndiceTocado;
    final ultimoInstante = _instanteUltimoToque;

    final ehDuploClique = ultimoIndice == indice &&
        ultimoInstante != null &&
        agora.difference(ultimoInstante) <= _janelaDuploClique;

    if (ehDuploClique) {
      _ultimoIndiceTocado = null;
      _instanteUltimoToque = null;

      final (data1, data2) = PeriodoUtils.intervaloDoBalde(balde, widget.filtro.agruparPorAno);
      widget.onAbrirHistorico?.call(data1, data2, _categoriaSelecionada);
      return;
    }

    _ultimoIndiceTocado = indice;
    _instanteUltimoToque = agora;
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

    final minValor = valores.isEmpty ? 0.0 : valores.reduce((a, b) => a < b ? a : b);
    final maxValor = valores.isEmpty ? 0.0 : valores.reduce((a, b) => a > b ? a : b);
    final minY = minValor < 0 ? minValor * 1.2 : 0.0;
    var maxY = maxValor > 0 ? maxValor * 1.2 : 1.0;
    if (maxY <= minY) maxY = minY + 1;

    final corTexto = widget.destaque ? Colors.white : AppColors.textPrimary;
    final corTextoSecundario = widget.destaque ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary;
    final corBarra = widget.destaque ? Colors.white : widget.cor;
    final corLinhaZero = widget.destaque ? Colors.white.withValues(alpha: 0.35) : Colors.grey.withValues(alpha: 0.55);

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
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: corTextoSecundario),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.moeda(total),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(color: corTexto),
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
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                            Formatters.moeda(rod.toY),
                            TextStyle(
                              color: widget.destaque ? AppColors.primary : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        touchCallback: widget.onAbrirHistorico == null
                            ? null
                            : (event, response) {
                                if (event is! FlTapUpEvent) return;
                                final indice = response?.spot?.touchedBarGroupIndex;
                                if (indice == null || indice < 0 || indice >= chaves.length) return;
                                _registrarToqueBarra(indice, chaves[indice]);
                              },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= quantidadeBarras) return const SizedBox.shrink();
                              final rotulo = PeriodoUtils.rotuloBalde(chaves[i], widget.filtro.agruparPorAno);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  rotulo,
                                  style: TextStyle(fontSize: 11, color: corTextoSecundario),
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
                            barRods: [
                              BarChartRodData(
                                toY: valores[i],
                                color: corBarra,
                                width: chaves.length > 8 ? 10 : 20,
                                borderRadius: valores[i] >= 0
                                    ? const BorderRadius.vertical(top: Radius.circular(6))
                                    : const BorderRadius.vertical(bottom: Radius.circular(6)),
                              ),
                            ],
                          ),
                      ],
                    ),
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
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(maxHeight: 280, minWidth: 160),
      onSelected: (valor) => _selecionarCategoria(valor == _valorTodas ? null : valor),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(value: _valorTodas, child: Text('Todas')),
        for (final c in widget.categorias!) PopupMenuItem<String>(value: c.nome, child: Text(c.nome)),
      ],
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.titulo}: $rotuloAtual',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: corTexto),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 18, color: corTexto),
          ],
        ),
      )
      
    );
  }
}