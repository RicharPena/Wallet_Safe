import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ResumenLineChart extends StatelessWidget {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final List<LineChartBarData> lineBarsData;
  final String currentView; // 'Semana', 'Mes', etc.

  const ResumenLineChart({
    Key? key,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.lineBarsData,
    required this.currentView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (lineBarsData.isEmpty || lineBarsData.first.spots.isEmpty) {
      return const Center(
        child: Text("No hay datos para mostrar en el gráfico"),
      );
    }

    final Set<double> hoyXValues =
        currentView == 'Hoy'
            ? lineBarsData
                .expand((bar) => bar.spots)
                .map((spot) => spot.x)
                .toSet()
            : {};

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (currentView == 'Hoy') {
                      if (!hoyXValues.contains(value)) {
                        return const SizedBox.shrink();
                      }
                      final totalMin = value.toInt();
                      final hour = (totalMin ~/ 60).toString().padLeft(2, '0');
                      final min = (totalMin % 60).toString().padLeft(2, '0');
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '$hour:$min',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    } else if (currentView == 'Semana') {
                      final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                      final index = value.toInt();
                      final label = dias[index % 7];
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    } else if (currentView == 'Mes') {
                      final index = value.toInt();
                      final semana =
                          (index ~/ 7) + 1; // Cada 7 días, nueva semana
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          'S$semana',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }

                    return const SizedBox.shrink(); // Fallback
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
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            lineBarsData: lineBarsData,
          ),
        ),
      ),
    );
  }
}
