import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wallet_safe/controllers/home_tab_titular_controller.dart';
import 'package:wallet_safe/controllers/home_tab_oprofiles_cotroller.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/controllers/graphics_helper_controller.dart';
import 'package:wallet_safe/widgets/resumen_lineal.dart';

class HomeTab extends StatefulWidget {
  final Perfil perfil;
  final Cuenta cuenta;
  final VoidCallback onLogout;

  const HomeTab({
    required this.cuenta,
    required this.perfil,
    required this.onLogout,
    super.key,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String currentView = 'Hoy'; // Control de vista (Hoy, Semana, Mes)
  double dineroActual = 23450.00; // También podría venir de tu lógica

  @override
  Widget build(BuildContext context) {
    final isTitular = widget.perfil.nombre == "Titular";
    final perfilesNormales =
        widget.cuenta.perfiles.where((p) => p.nombre != "Titular").toList();

    final List<FlSpot> titularSpots =
        isTitular
            ? TitularController.getLineSpots(widget.perfil, currentView)
            : [];

    // Otras líneas para perfiles normales
    final otrasLineas =
        isTitular
            ? perfilesNormales.map((perfil) {
              final spots = OProfilesController.getLineSpots(
                perfil,
                currentView,
              );
              return LineChartBarData(
                spots: spots,
                isCurved: true,
                color: _colorForPerfil(widget.cuenta, perfil),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              );
            }).toList()
            : [
              LineChartBarData(
                spots: OProfilesController.getLineSpots(
                  widget.perfil,
                  currentView,
                ),
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ];

    final titularLine =
        isTitular
            ? [
              LineChartBarData(
                spots: titularSpots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ]
            : [];

    // Extraer todos los FlSpot para calcular los bounds del gráfico
    final List<FlSpot> allSpots =
        [
          ...titularLine,
          ...otrasLineas,
        ].expand((line) => line.spots).cast<FlSpot>().toList();

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
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: widget.onLogout,
                ),
                title: Text(
                  'Hola, ${widget.perfil.nombre}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (widget.perfil.nombre == "Titular")
                Container(
                  margin: const EdgeInsets.only(bottom: 16.0, top: 10),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: const Text(
                    'Bienvenido, aquí tienes un resumen de lo que está aconteciendo el día de hoy.',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ),

              // Dinero actual
              Text(
                '\$${dineroActual.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ResumenLineChart(
                minX: bounds.minX,
                maxX: bounds.maxX,
                minY: bounds.minY,
                maxY: bounds.maxY,
                lineBarsData: [...titularLine, ...otrasLineas],
                currentView: currentView,
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

// Método auxiliar para dar un color único a cada perfil
Color _colorForPerfil(Cuenta cuenta, Perfil perfil) {
  final index = cuenta.perfiles.indexOf(perfil);
  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
  return colors[index % colors.length];
}
