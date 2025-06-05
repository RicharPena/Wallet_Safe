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

  // Función auxiliar para obtener el inicio de la semana (Lunes)
  static DateTime _getStartOfWeek(DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si lineBarsData está vacío, o si todas las barras están vacías,
    // o si todas las barras solo contienen un punto (0,0) o solo ceros.
    bool noDataToShow =
        lineBarsData.isEmpty ||
        lineBarsData.every((bar) => bar.spots.isEmpty) ||
        lineBarsData.every(
          (bar) =>
              bar.spots.length == 1 &&
              bar.spots.first.x == 0 &&
              bar.spots.first.y == 0,
        ) ||
        // Condición adicional para manejar múltiples puntos, todos en cero
        lineBarsData.every((bar) => bar.spots.every((spot) => spot.y == 0));

    if (noDataToShow) {
      return const Center(
        child: Text("No hay datos para mostrar en el gráfico"),
      );
    }

    late List<LineChartBarData> chartData;
    double minX, maxX;
    Map<int, double> reverseXMap = {}; // Solo para 'Hoy'

    final int todayWeekdayIndex = DateTime.now().weekday - 1;
    // Calcular la semana actual del mes para la vista 'Mes'
    final DateTime now = DateTime.now();
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);
    final DateTime startOfCurrentWeek = _getStartOfWeek(now);
    int currentWeekIndex = 0;

    // Calcula el índice de la semana actual dentro del mes (0-indexed)
    // Se basa en cuántas semanas completas (o parciales) han pasado desde el inicio del mes
    DateTime tempWeekStart = _getStartOfWeek(startOfMonth);
    while (tempWeekStart.isBefore(startOfCurrentWeek)) {
      currentWeekIndex++;
      tempWeekStart = tempWeekStart.add(const Duration(days: 7));
    }

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
                    getDotPainter: (spot, percent, bar, index) {
                      if (index == todayWeekdayIndex) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: bar.color!, // Usa el color de la línea
                          strokeColor: Colors.white,
                          strokeWidth: 2,
                        );
                      }
                      return FlDotCirclePainter(radius: 0);
                    },
                  ), // Mostrar los puntos para cada día
                ),
              )
              .toList();
      minX = 0; // Lunes
      maxX = 6; // Domingo
    } else if (currentView == 'Mes') {
      chartData =
          lineBarsData.map((bar) {
            return bar.copyWith(
              dotData: FlDotData(
                show: true, // Habilitar la visibilidad de los puntos
                getDotPainter: (spot, percent, bar, index) {
                  // Si el índice del punto es igual al índice de la semana actual, muéstralo
                  if (index == currentWeekIndex) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: bar.color!,
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    );
                  }
                  return FlDotCirclePainter(radius: 0); // Ocultar otros puntos
                },
              ),
            );
          }).toList();

      // Calcular maxX dinámicamente basado en la cantidad de semanas
      // Asumimos que lineBarsData tiene al menos una barra con spots
      maxX =
          lineBarsData.isNotEmpty && lineBarsData[0].spots.isNotEmpty
              ? lineBarsData[0].spots.length.toDouble() - 1
              : 3; // Mínimo 4 semanas (0-3)

      minX = 0;
    } else {
      chartData = lineBarsData;
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
                      final index = value.toInt();
                      // Asegurarse de que el índice sea válido (0, 1, 2, 3, 4)
                      if (index >= 0 && index < 5) {
                        // Asume un máximo de 5 semanas visibles
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            'S${index + 1}', // S1, S2, S3, S4, S5
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
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
