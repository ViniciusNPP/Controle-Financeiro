import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'dart:math' as math;

class CategoryPieChartCard extends StatefulWidget {
  final String titulo;
  final Map<String, double> dados;
  final double? alturaFixa;

  const CategoryPieChartCard({
    super.key,
    required this.titulo,
    required this.dados,
    this.alturaFixa,
  });

  @override
  State<CategoryPieChartCard> createState() => _CategoryPieChartCardState();
}

class _CategoryPieChartCardState extends State<CategoryPieChartCard> {
  int? _indiceTocado;

  // variável que define o percentual mínimo de uma fatia para mostrar seu valor dentro dela.
  static const double _limiarRotuloExternoPct = 5.0;

  List<MapEntry<String, double>> _entradasFiltradas() {
    final ordenadas = widget.dados.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = ordenadas.fold<double>(0, (a, e) => a + e.value);
    if (total == 0) return ordenadas;

    const limite = 0.95;
    final resultado = <MapEntry<String, double>>[];
    double acumulado = 0;
    double outros = 0;

    for (final entrada in ordenadas) {
      if (acumulado / total < limite) {
        resultado.add(entrada);
        acumulado += entrada.value;
      } else {
        outros += entrada.value;
      }
    }

    if (outros > 0) resultado.add(MapEntry('Outros', outros));
    return resultado;
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
    final entradas = _entradasFiltradas();
    final total = entradas.fold<double>(0, (a, e) => a + e.value);
    final indiceTocado = _indiceTocado;

    // A fatia é pequena quando total fica abaixo de _limiarRotuloExternoPct
    final tocadaEhPequena = indiceTocado != null &&
        total > 0 &&
        (entradas[indiceTocado].value / total * 100) < _limiarRotuloExternoPct;

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
                  Text(Formatters.moeda(total), style: Theme.of(context).textTheme.displayMedium),
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
                                          color: AppColors.forIndex(i),
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
                                    anguloMedioGraus: _anguloInicialGraus(entradas, total, indiceTocado) +
                                        (entradas[indiceTocado].value / total * 360) / 2,
                                    texto: Formatters.moeda(entradas[indiceTocado].value),
                                    cor: AppColors.forIndex(indiceTocado),
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
                          itemCount: entradas.length,
                          itemBuilder: (context, i) {
                            final pct = total == 0 ? 0.0 : (entradas[i].value / total) * 100;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: AppColors.forIndex(i), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entradas[i].key,
                                      style: const TextStyle(fontSize: 12.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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