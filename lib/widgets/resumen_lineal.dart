import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ResumenLineChart extends StatelessWidget {
  final double minY;
  final double maxY;
  final List<LineChartBarData> lineBarsData;
  final String currentView; // 'Hoy', 'Semana', 'Mes', etc.

  const ResumenLineChart({
    Key? key,
    required this.minY,
    required this.maxY,
    required this.lineBarsData,
    required this.currentView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (lineBarsData.isEmpty ||
        lineBarsData.every((bar) => bar.spots.isEmpty)) {
      return const Center(
        child: Text("No hay datos para mostrar en el gráfico"),
      );
    }

    late List<LineChartBarData> chartData;
    double minX, maxX;
    Map<int, double> reverseXMap = {}; // Solo para 'Hoy'

    if (currentView == 'Hoy') {
      final allSpots = lineBarsData.expand((bar) => bar.spots).toList();
      final uniqueSortedSpots =
          allSpots.map((spot) => spot.x).toSet().toList()
            ..sort((a, b) => a.compareTo(b));

      final Map<double, int> xMap = {
        for (int i = 0; i < uniqueSortedSpots.length; i++)
          uniqueSortedSpots[i]: i,
      };
      reverseXMap = {for (var entry in xMap.entries) entry.value: entry.key};

      chartData =
          lineBarsData.map((bar) {
            final newSpots =
                bar.spots
                    .map((spot) => FlSpot(xMap[spot.x]!.toDouble(), spot.y))
                    .toList();
            return bar.copyWith(spots: newSpots);
          }).toList();

      minX = 0;
      maxX = reverseXMap.length.toDouble() - 1;
    } else if (currentView == 'Semana') {
      // Los datos ya vienen procesados de ProfilesController.
      // Simplemente usa los lineBarsData directamente.
      chartData =
          lineBarsData
              .map(
                (bar) => bar.copyWith(
                  dotData: FlDotData(
                    show: true,
                  ), // Mostrar los puntos para cada día
                ),
              )
              .toList();
      minX = 0; // Lunes
      maxX = 6; // Domingo
    } else {
      // Vista 'Mes' u otras: sin modificar X
      chartData = lineBarsData;
      // Calcula minX y maxX si no hay datos o son nulos
      final allX = chartData.expand((bar) => bar.spots).map((e) => e.x);
      minX = allX.isEmpty ? 0 : allX.reduce((a, b) => a < b ? a : b);
      maxX = allX.isEmpty ? 0 : allX.reduce((a, b) => a > b ? a : b);
    }

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
                  interval: 1, // Muestra cada día
                  getTitlesWidget: (value, meta) {
                    if (currentView == 'Hoy') {
                      final originalX = reverseXMap[value.toInt()];
                      if (originalX == null) return const SizedBox.shrink();

                      final hour = (originalX ~/ 60).toInt();
                      final minute = (originalX % 60).toInt();
                      final label =
                          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                      const step = 1; // Ajusta según la densidad deseada
                      if (value % step != 0) return const SizedBox.shrink();

                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    } else if (currentView == 'Semana') {
                      final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                      final index = value.toInt();
                      if (index >= 0 && index < dias.length) {
                        final label = dias[index];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    } else if (currentView == 'Mes') {
                      // Mantén tu lógica existente o modifícala si es necesario
                      final index = value.toInt();
                      final semana =
                          (index ~/ 7) + 1; // Esto es una aproximación
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          'S$semana',
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
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            lineBarsData: chartData,
          ),
        ),
      ),
    );
  }
}
