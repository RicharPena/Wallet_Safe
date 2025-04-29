import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wallet_safe/controllers/home_tab_titular_controller.dart';
import 'package:wallet_safe/controllers/home_tab_oprofiles_cotroller.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/controllers/graphics_helper_controller.dart';

class HomeTab extends StatefulWidget {
  final Perfil perfil;
  const HomeTab({required this.perfil, super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String currentView = 'Hoy'; // Control de vista (Hoy, Semana, Mes)
  double dineroActual = 23450.00; // También podría venir de tu lógica

  @override
  Widget build(BuildContext context) {
    final titularSpots = TitularController.getLineSpots();
    final perfilSpots = PerfilController.getLineSpots();

    // Combinar todos los puntos para obtener límites correctos
    final allSpots = [...titularSpots, ...perfilSpots];
    final bounds = GraphHelper.getMinMax(allSpots);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 Nombre del usuario
              AppBar(
                title: Text(
                  'Hola, ${widget.perfil.nombre}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 💰 Dinero actual
              Text(
                '\$${dineroActual.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: LineChart(
                  LineChartData(
                    minX: bounds.minX,
                    maxX: bounds.maxX,
                    minY: bounds.minY,
                    maxY: bounds.maxY,
                    titlesData: FlTitlesData(show: false),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: titularSpots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: perfilSpots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),

              // Botones de vista
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    ['Hoy', 'Semana', 'Mes'].map((vista) {
                      final isSelected = currentView == vista;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ChoiceChip(
                          label: Text(vista),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              currentView = vista;
                              // Aquí luego puedes llamar a métodos que actualicen los datos
                            });
                          },
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
