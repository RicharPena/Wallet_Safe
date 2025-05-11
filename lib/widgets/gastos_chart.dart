import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wallet_safe/models/gastos.dart';
import 'package:wallet_safe/services/chart_service.dart';

class GastosChart extends StatelessWidget {
  final List<Gasto> gastos;
  final DateRange rango;

  const GastosChart({super.key, required this.gastos, required this.rango});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: FutureBuilder<Map<String, dynamic>>(
        future: ChartService.obtenerMontosAgrupados(
          datos: gastos,
          rango: rango,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final datos = snapshot.data!;
          final montos = datos['montos'] as List<double>;
          final labels = datos['labels'] as List<String>;

          if (montos.isEmpty || labels.isEmpty) {
            return const Center(
              child: Text(
                "No hay datos para presentar una gráfica",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }

          final maxY = (montos.reduce((a, b) => a > b ? a : b)) * 1.2;

          return BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: List.generate(montos.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: montos[index],
                      color: Colors.red,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            labels[index],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      final text =
                          value >= 1000000
                              ? "${(value / 1000000).toStringAsFixed(1)}M"
                              : value >= 1000
                              ? "${(value / 1000).toStringAsFixed(0)}k"
                              : value.toInt().toString();
                      return Text(text, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true),
            ),
          );
        },
      ),
    );
  }
}
