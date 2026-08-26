import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'dart:math' as math;

class CategoryPieChartCard extends StatefulWidget {
  final String titulo;
  final Map<String, double> dados;
  final double? alturaFixa;

  /// Chamado quando o usuário aciona long-press/clique direito numa
  /// categoria da legenda, pedindo para ver aquele lançamentos no Histórico.
  /// Recebe o nome exato da categoria clicada.
  final ValueChanged<String>? onAbrirHistorico;

  const CategoryPieChartCard({
    super.key,
    required this.titulo,
    required this.dados,
    this.alturaFixa,
    this.onAbrirHistorico,
  });

  @override
  State<CategoryPieChartCard> createState() => _CategoryPieChartCardState();
}

class _CategoryPieChartCardState extends State<CategoryPieChartCard> {
  int? _indiceTocado;

  // Controla se os filhos de "Outros" estão visíveis na legenda/gráfico
  bool _outrosExpandido = false;

  // Nomes de categorias ocultas
  final Set<String> _categoriasOcultas = {};
  Map<String, double>? _ultimoDados;

  // variável que define o percentual mínimo de uma fatia para mostrar seu valor dentro dela.
  static const double _limiarRotuloExternoPct = 5.0;

  /// Categorias principais + "Outros" agregado (se houver)
  List<MapEntry<String, double>> _entradasFiltradas() {
    final ordenadas = widget.dados.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = ordenadas.fold<double>(0, (a, e) => a + e.value);
    if (total == 0) return ordenadas;

    const limite = 0.95;
    final principais = <MapEntry<String, double>>[];
    final restantes = <MapEntry<String, double>>[];
    double acumulado = 0;

    for (final entrada in ordenadas) {
      if (acumulado / total < limite) {
        principais.add(entrada);
        acumulado += entrada.value;
      } else {
        restantes.add(entrada);
      }
    }

    if (restantes.length == 1) {
      principais.add(restantes.first);
    } else if (restantes.length > 1) {
      final outros = restantes.fold<double>(0, (a, e) => a + e.value);
      principais.add(MapEntry('Outros', outros));
    }

    return principais;
  }

  /// As categorias que ficaram agrupadas dentro de "Outros"
  List<MapEntry<String, double>> _filhosDeOutros() {
    final ordenadas = widget.dados.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = ordenadas.fold<double>(0, (a, e) => a + e.value);
    if (total == 0) return [];

    const limite = 0.95;
    final restantes = <MapEntry<String, double>>[];
    double acumulado = 0;

    for (final entrada in ordenadas) {
      if (acumulado / total < limite) {
        acumulado += entrada.value;
      } else {
        restantes.add(entrada);
      }
    }

    return restantes.length > 1 ? restantes : [];
  }

  /// Entradas que alimentam o PieChart
  List<MapEntry<String, double>> _entradasGrafico(
    List<MapEntry<String, double>> principaisComOutros,
    List<MapEntry<String, double>> filhos,
  ) {
    if (!_outrosExpandido || filhos.isEmpty) return principaisComOutros;
    return [
      for (final e in principaisComOutros)
        if (e.key != 'Outros') e,
      ...filhos,
    ];
  }

  /// Oculta as categorias somente se visiveisAtualmente > 2
  bool _alternarOculta(String nome, {required int visiveisAtualmente}) {
    if (_categoriasOcultas.contains(nome)) {
      _categoriasOcultas.remove(nome);
      return true;
    }
    if (visiveisAtualmente <= 2) return false;
    _categoriasOcultas.add(nome);
    return true;
  }

  /// Ponte entre _alternarOculta() e setState()
  bool _tentarAlternarOculta(String nome, {required int visiveisAtualmente}) {
    final aplicado = _alternarOculta(nome, visiveisAtualmente: visiveisAtualmente);
    if (aplicado) setState(() {});
    return aplicado;
  }

  double _anguloInicialGraus(List<MapEntry<String, double>> entradas, double total, int indice) {
    var angulo = 0.0;
    for (var i = 0; i < indice; i++) {
      angulo += (entradas[i].value / total) * 360;
    }
    return angulo;
  }

  @override
  Widget build(BuildContext context) {
    // Exibi as categorias ocultas
    if (!identical(_ultimoDados, widget.dados)) {
      _categoriasOcultas.clear();
      _outrosExpandido = false;
      _ultimoDados = widget.dados;
    }

    final entradasLegenda = _entradasFiltradas();
    final filhosOutros = _filhosDeOutros();
    // Fecha outros na troca de período se necessário
    if (filhosOutros.isEmpty && _outrosExpandido) _outrosExpandido = false;

    // Base para o gráfico: principais + filhos (se expandido)
    final outrosOculto = _categoriasOcultas.contains('Outros');
    final principaisVisiveis = entradasLegenda.where((e) => !_categoriasOcultas.contains(e.key)).toList();
    final entradasGraficoComOcultas =
        outrosOculto ? principaisVisiveis : _entradasGrafico(principaisVisiveis, filhosOutros);
    final entradas = entradasGraficoComOcultas.where((e) => !_categoriasOcultas.contains(e.key)).toList();

    // Ordem canônica de cores
    final ordemCores = _entradasGrafico(entradasLegenda, filhosOutros);
    Color corDe(String nome) {
      final i = ordemCores.indexWhere((e) => e.key == nome);
      return AppColors.forIndex(i < 0 ? 0 : i);
    }

    // Total "real"
    final totalReal = entradasLegenda.fold<double>(0, (a, e) => a + e.value);
    // Total só das visíveis
    final totalVisivel = entradas.fold<double>(0, (a, e) => a + e.value);
    final indiceTocado = _indiceTocado;

    // A fatia é pequena quando total fica abaixo de _limiarRotuloExternoPct
    final tocadaEhPequena = indiceTocado != null &&
        totalVisivel > 0 &&
        (entradas[indiceTocado].value / totalVisivel * 100) < _limiarRotuloExternoPct;

    return Container(
      padding: const EdgeInsets.all(20),
      height: widget.alturaFixa,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 62,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.titulo, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(Formatters.moeda(totalReal), style: Theme.of(context).textTheme.displayMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 218,
            child: entradas.isEmpty
                ? Center(
                    child: Text('Sem lançamentos no período', style: Theme.of(context).textTheme.bodyMedium),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 8,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final ladoMenor = constraints.maxWidth < constraints.maxHeight
                                ? constraints.maxWidth
                                : constraints.maxHeight;
                            // Teto do clamp aumentado (era 140.0) para o raio continuar
                            // crescendo em telas maiores, em vez de travar cedo.
                            final raioBase = (ladoMenor / 2 * 0.9).clamp(24.0, 220.0);
                            final raioCentro = raioBase * 0.38;
                            final raioNormal = raioBase * 0.53;
                            final raioSelecionado = raioBase * 0.62;
                            final fontSizeTitulo = (raioSelecionado * 0.21).clamp(9.0, 13.0);
                            final distanciaRadialExtra = (raioBase * 0.11).clamp(10.0, 26.0);
                            final distanciaHorizontal = (raioBase * 0.17).clamp(16.0, 40.0);

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: raioCentro,
                                    pieTouchData: PieTouchData(
                                      touchCallback: (event, response) {
                                        final indiceBruto = response?.touchedSection?.touchedSectionIndex;
                                        final indiceSobPonteiro = (indiceBruto != null && indiceBruto >= 0) ? indiceBruto : null;
                                        if (event is FlTapUpEvent) {
                                          setState(() {
                                            _indiceTocado = (indiceSobPonteiro != null && indiceSobPonteiro == _indiceTocado)
                                                ? null
                                                : indiceSobPonteiro;
                                          });
                                          return;
                                        }
                                        if (event is FlTapCancelEvent) return;
                                        setState(() {
                                          _indiceTocado = event.isInterestedForInteractions ? indiceSobPonteiro : null;
                                        });
                                      },
                                    ),
                                    sections: [
                                      for (var i = 0; i < entradas.length; i++)
                                        PieChartSectionData(
                                          value: entradas[i].value,
                                          color: corDe(entradas[i].key),
                                          radius: i == _indiceTocado ? raioSelecionado : raioNormal,
                                          // Se a fatia for pequena, não mostra o título dentro dela (vai pro rótulo externo).
                                          showTitle: i == _indiceTocado && !tocadaEhPequena,
                                          title: Formatters.moeda(entradas[i].value),
                                          titleStyle: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: fontSizeTitulo,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (tocadaEhPequena)
                                  _RotuloExternoPizza(
                                    tamanho: Size(constraints.maxWidth, constraints.maxHeight),
                                    raio: raioSelecionado,
                                    distanciaRadialExtra: distanciaRadialExtra,
                                    distanciaHorizontal: distanciaHorizontal,
                                    anguloMedioGraus: _anguloInicialGraus(entradas, totalVisivel, indiceTocado) +
                                        (entradas[indiceTocado].value / totalVisivel * 360) / 2,
                                    texto: Formatters.moeda(entradas[indiceTocado].value),
                                    cor: corDe(entradas[indiceTocado].key),
                                    fontSize: fontSizeTitulo,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        flex: 6,
                        child: ListView.builder(
                          // Cada categoria principal (que não seja "Outros") vira 1
                          // item; "Outros" vira 1 item + 1 por filho quando expandido.
                          itemCount: entradasLegenda.length + (_outrosExpandido ? filhosOutros.length : 0),
                          itemBuilder: (context, i) {
                            if (i < entradasLegenda.length) {
                              final entrada = entradasLegenda[i];
                              final ehOutros = entrada.key == 'Outros' && filhosOutros.isNotEmpty;
                              return _ItemLegenda(
                                key: ValueKey(entrada.key),
                                nome: entrada.key,
                                valor: entrada.value,
                                total: totalReal,
                                cor: corDe(entrada.key),
                                expansivel: ehOutros,
                                expandido: _outrosExpandido,
                                oculta: _categoriasOcultas.contains(entrada.key),
                                onTap: ehOutros ? () => setState(() => _outrosExpandido = !_outrosExpandido) : null,
                                onDoubleTap: () =>
                                    _tentarAlternarOculta(entrada.key, visiveisAtualmente: entradas.length),
                                onAbrirHistorico: (widget.onAbrirHistorico == null || ehOutros)
                                    ? null
                                    : () => widget.onAbrirHistorico!(entrada.key),
                              );
                            }

                            final filho = filhosOutros[i - entradasLegenda.length];
                            return _ItemLegenda(
                              key: ValueKey(filho.key),
                              nome: filho.key,
                              valor: filho.value,
                              total: totalReal,
                              cor: corDe(filho.key),
                              indentado: true,
                              oculta: _categoriasOcultas.contains(filho.key),
                              onDoubleTap: () =>
                                  _tentarAlternarOculta(filho.key, visiveisAtualmente: entradas.length),
                              onAbrirHistorico:
                                  widget.onAbrirHistorico == null ? null : () => widget.onAbrirHistorico!(filho.key),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

}

class _ItemLegenda extends StatefulWidget {
  final String nome;
  final double valor;
  final double total;
  final Color cor;
  final bool indentado;
  final bool expansivel;
  final bool expandido;
  final bool oculta;
  final VoidCallback? onTap;

  /// Tenta alternar oculto/visível. Deve devolver `true` se a ação foi aplicada, ou `false` se foi recusada
  final bool Function()? onDoubleTap;

  /// Acionado por long-press (toque) ou clique direito (mouse) — pede para
  /// abrir o Histórico já filtrado por essa categoria.
  final VoidCallback? onAbrirHistorico;

  const _ItemLegenda({
    super.key,
    required this.nome,
    required this.valor,
    required this.total,
    required this.cor,
    this.indentado = false,
    this.expansivel = false,
    this.expandido = false,
    this.oculta = false,
    this.onTap,
    this.onDoubleTap,
    this.onAbrirHistorico,
  });

  @override
  State<_ItemLegenda> createState() => _ItemLegendaState();
}

class _ItemLegendaState extends State<_ItemLegenda> with SingleTickerProviderStateMixin {
  static const _duracaoErro = Duration(milliseconds: 500);
  late final AnimationController _controladorErro = AnimationController(vsync: this, duration: _duracaoErro);

  @override
  void dispose() {
    _controladorErro.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final onDoubleTap = widget.onDoubleTap;
    if (onDoubleTap == null) return;
    final aplicado = onDoubleTap();
    if (!aplicado) {
      _controladorErro.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.total == 0 ? 0.0 : (widget.valor / widget.total) * 100;
    // Categoria oculta: nome, círculo e % ficam translúcidos
    final opacidade = widget.oculta ? 0.35 : 1.0;

    final linha = AnimatedBuilder(
      animation: _controladorErro,
      builder: (context, child) {
        final t = _controladorErro.value;
        // Pisca: sobe pra vermelho na primeira metade, volta na segunda.
        final intensidadeVermelho = t <= 0.5 ? (t / 0.5) : (1 - (t - 0.5) / 0.5);
        final corTexto = Color.lerp(AppColors.textPrimary, Colors.red, intensidadeVermelho)!;
        // Treme: pequena oscilação horizontal amortecida ao longo dos 500ms.
        final tremor = math.sin(t * math.pi * 6) * (1 - t) * 4;

        return Transform.translate(
          offset: Offset(tremor, 0),
          child: Padding(
            padding: EdgeInsets.only(left: widget.indentado ? 18 : 0, top: 4, bottom: 4),
            child: Opacity(
              opacity: opacidade,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: widget.cor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.nome,
                      style: TextStyle(fontSize: 12.5, color: corTexto),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.expansivel) ...[
                    Icon(
                      widget.expandido ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.onTap == null && widget.onDoubleTap == null && widget.onAbrirHistorico == null) return linha;
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(8),
      onTap: widget.onTap,
      onDoubleTap: _handleDoubleTap,
      onLongPress: widget.onAbrirHistorico,
      onSecondaryTap: widget.onAbrirHistorico,
      child: linha,
    );
  }
}

/// Resumo: Desenha uma linha guia e o valor fora do gráfico.
class _RotuloExternoPizza extends StatelessWidget {
  final Size tamanho;
  final double raio;
  final double distanciaRadialExtra;
  final double distanciaHorizontal;
  final double anguloMedioGraus;
  final String texto;
  final Color cor;
  final double fontSize;

  const _RotuloExternoPizza({
    required this.tamanho,
    required this.raio,
    required this.distanciaRadialExtra,
    required this.distanciaHorizontal,
    required this.anguloMedioGraus,
    required this.texto,
    required this.cor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final centro = Offset(tamanho.width / 2, tamanho.height / 2);
    final anguloRad = anguloMedioGraus * (math.pi / 180);
    final cosA = math.cos(anguloRad);
    final sinA = math.sin(anguloRad);
    final direcao = Offset(cosA, sinA);

    // "Cotovelo": um pouco mais pra fora, na mesma direção radial da fatia.
    // distanciaRadialExtra agora escala com o raioBase (calculado no pai).
    final pCotovelo = centro + direcao * (raio + distanciaRadialExtra);
    // Trecho final, sempre horizontal, pra direita ou esquerda dependendo do lado da fatia.
    // distanciaHorizontal também escala com o raioBase.
    final ladoDireito = cosA >= 0;
    final pFinal = pCotovelo + Offset(ladoDireito ? distanciaHorizontal : -distanciaHorizontal, 0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: pFinal.dy - (fontSize / 2) - 2,
          left: ladoDireito ? pFinal.dx + 4 : null,
          right: ladoDireito ? null : tamanho.width - pFinal.dx + 4,
          child: Text(
            texto,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: cor),
          ),
        ),
      ],
    );
  }
}