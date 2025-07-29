import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';
import 'package:wallet_safe/services/chart_service.dart'; // Importar ChartService

class PresupuestosFamiliaresChart extends StatelessWidget {
  final List<PresupuestoPersonal> presupuestosPersonales;

  const PresupuestosFamiliaresChart({
    super.key,
    required this.presupuestosPersonales,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar los presupuestos personales que tienen un origen familiar
    final List<PresupuestoPersonal> presupuestosFamiliaresFiltrados =
        presupuestosPersonales
            .where((p) => p.idPresupuestoFamiliarOrigen != null)
            .toList();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ChartService.obtenerDatosPresupuestosParaPieChart(
        presupuestosFamiliaresFiltrados,
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
              "No hay datos de presupuestos familiares para mostrar",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          );
        }

        // ¡ATENCIÓN!: Removemos el AspectRatio que envolvía todo el Column.
        // Ahora el Column determinará su altura en función de sus hijos.
        return Column(
          // mainAxisSize.min es crucial aquí para que el Column solo ocupe
          // el espacio vertical que sus hijos realmente necesitan,
          // permitiendo que el contenedor externo se adapte.
          mainAxisSize: MainAxisSize.min,
          children: [
            // El gráfico de pastel:
            // Lo envolvemos en un Flexible para que pueda tomar la mayor parte del espacio vertical.
            // Y DENTRO de este Flexible, le damos su propio AspectRatio para que siempre sea cuadrado
            // y se adapte de forma responsiva dentro del espacio flexible asignado.
            Flexible(
              flex:
                  1, // Le damos 3 partes del espacio flexible disponible al gráfico
              child: AspectRatio(
                aspectRatio:
                    1.5, // Esto hace que el gráfico sea siempre un círculo perfecto/cuadrado
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
                            radius: 70,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                    sectionsSpace: 2, // Espacio entre las rebanadas del pastel
                    centerSpaceRadius: 40, // Radio del círculo central vacío
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Implementar interactividad si es necesario
                      },
                    ),
                  ),
                ),
              ),
            ),

            //Leyenda
            Flexible(
              flex: 1,
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing:
                      12, // Espacio horizontal entre los ítems de la leyenda
                  runSpacing:
                      8, // Espacio vertical entre las líneas de la leyenda
                  children:
                      data.map((item) {
                        return _LegendItem(
                          color: item['color'] as Color,
                          text:
                              '${item['category']}: ${(item['percentage'] as double).toStringAsFixed(1)}%',
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        );
      },
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
