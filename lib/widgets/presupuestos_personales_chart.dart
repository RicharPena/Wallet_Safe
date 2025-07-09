import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';
import 'package:wallet_safe/services/chart_service.dart'; // Importar ChartService

class PresupuestosPersonalesChart extends StatelessWidget {
  final List<PresupuestoPersonal> presupuestos;

  const PresupuestosPersonalesChart({super.key, required this.presupuestos});

  @override
  Widget build(BuildContext context) {
    // Filtrar los presupuestos personales que NO tienen un origen familiar
    final List<PresupuestoPersonal> presupuestosPersonalesFiltrados =
        presupuestos
            .where((p) => p.idPresupuestoFamiliarOrigen == null)
            .toList();

    return AspectRatio(
      aspectRatio: 1.3, // Ajusta el aspecto para que el pastel se vea bien
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: ChartService.obtenerDatosPresupuestosParaPieChart(
          presupuestosPersonalesFiltrados,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final List<Map<String, dynamic>>? data = snapshot.data;

          if (data == null || data.isEmpty) {
            return const Center(
              child: Text(
                "No hay datos de presupuestos personales para mostrar",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections:
                        data.asMap().entries.map((entry) {
                          final item = entry.value;
                          return PieChartSectionData(
                            color: item['color'] as Color,
                            value: item['amount'] as double,
                            title:
                                '${(item['percentage'] as double).toStringAsFixed(1)}%',
                            radius: 70, // Tamaño de las secciones
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                    sectionsSpace: 2, // Espacio entre secciones
                    centerSpaceRadius: 40, // Radio del centro vacío
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Implementar interactividad si es necesario
                      },
                    ),
                  ),
                ),
              ),
              // Leyenda personalizada
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12, // Espacio horizontal entre ítems
                runSpacing: 8, // Espacio vertical entre líneas de ítems
                children:
                    data.map((item) {
                      return _LegendItem(
                        color: item['color'] as Color,
                        text:
                            '${item['category']}: ${(item['percentage'] as double).toStringAsFixed(1)}%',
                      );
                    }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
