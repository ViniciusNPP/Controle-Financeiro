import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/period_utils.dart';

/// Gráfico de barras genérico usado nos 3 gráficos "gerais" (Entradas,
/// Saídas, Saldo). Quando [destaque] é true, usa o tratamento visual
/// especial em degradê (reservado para o Saldo, o número mais importante).
class BarChartCard extends StatelessWidget {
  final String titulo;
  final Map<DateTime, double> dados;
  final bool agruparPorAno;
  final Color cor;
  final double? alturaFixa;
  final bool destaque;

  const BarChartCard({
    super.key,
    required this.titulo,
    required this.dados,
    required this.agruparPorAno,
    required this.cor,
    this.alturaFixa,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final chaves = dados.keys.toList()..sort();
    final valores = chaves.map((k) => dados[k] ?? 0).toList();
    final total = valores.fold<double>(0, (a, b) => a + b);

    final minValor = valores.isEmpty ? 0.0 : valores.reduce((a, b) => a < b ? a : b);
    final maxValor = valores.isEmpty ? 0.0 : valores.reduce((a, b) => a > b ? a : b);
    final minY = minValor < 0 ? minValor * 1.2 : 0.0;
    var maxY = maxValor > 0 ? maxValor * 1.2 : 1.0;
    if (maxY <= minY) maxY = minY + 1;

    final corTexto = destaque ? Colors.white : AppColors.textPrimary;
    final corTextoSecundario = destaque ? Colors.white.withOpacity(0.75) : AppColors.textSecondary;
    final corBarra = destaque ? Colors.white : cor;

    return Container(
      padding: const EdgeInsets.all(20),
      height: alturaFixa,
      decoration: destaque
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
          Text(titulo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: corTextoSecundario)),
          const SizedBox(height: 4),
          Text(
            Formatters.moeda(total),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: corTexto),
          ),
          const SizedBox(height: 16),
          Expanded(
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
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                            Formatters.moeda(rod.toY),
                            TextStyle(
                              color: destaque ? AppColors.primary : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
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
                              if (i < 0 || i >= chaves.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  PeriodoUtils.rotuloBalde(chaves[i], agruparPorAno),
                                  style: TextStyle(fontSize: 11, color: corTextoSecundario),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < chaves.length; i++)
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
  }
}
