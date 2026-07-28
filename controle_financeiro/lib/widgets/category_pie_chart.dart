import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

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

  @override
  Widget build(BuildContext context) {
    final entradas = widget.dados.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entradas.fold<double>(0, (a, e) => a + e.value);

    return Container(
      padding: const EdgeInsets.all(20),
      height: widget.alturaFixa,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(Formatters.moeda(total), style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 12),
          Expanded(
            child: entradas.isEmpty
                ? Center(
                    child: Text('Sem lançamentos no período', style: Theme.of(context).textTheme.bodyMedium),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 8,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                final indiceSobPonteiro = response?.touchedSection?.touchedSectionIndex;
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
                                  radius: i == _indiceTocado ? 58 : 50,
                                  showTitle: i == _indiceTocado,
                                  title: Formatters.moeda(entradas[i].value),
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
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