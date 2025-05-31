import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wallet_safe/controllers/home_tab_profiles_controller.dart';
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
  double dineroActual = 0;

  @override
  Widget build(BuildContext context) {
    final isTitular = widget.perfil.nombre == "Titular";
    final perfilesNormales =
        widget.cuenta.perfiles.where((p) => p.nombre != "Titular").toList();

    final dineroActual = calcularDineroActual(widget.perfil, currentView);

    final List<FlSpot> titularSpots =
        isTitular
            ? ProfilesController.getLineSpots(widget.perfil, currentView)
            : [];

    // Otras líneas para perfiles normales
    final otrasLineas =
        isTitular
            ? perfilesNormales.map((perfil) {
              final spots = ProfilesController.getLineSpots(
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
                spots: ProfilesController.getLineSpots(
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

  //Método auxiliar para calculo de dinero actual
  double calcularDineroActual(Perfil perfil, String vista) {
    DateTime now = DateTime.now();

    bool filtrarPorVista(DateTime fecha) {
      final hoy = DateTime(now.year, now.month, now.day);
      switch (vista) {
        case 'Hoy':
          return fecha.year == hoy.year &&
              fecha.month == hoy.month &&
              fecha.day == hoy.day;
        case 'Semana':
          final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
          final finSemana = inicioSemana.add(Duration(days: 6));
          return fecha.isAfter(
                inicioSemana.subtract(const Duration(seconds: 1)),
              ) &&
              fecha.isBefore(finSemana.add(const Duration(days: 1)));
        case 'Mes':
          return fecha.year == hoy.year && fecha.month == hoy.month;
        default:
          return true;
      }
    }

    final totalIngresos = perfil.cnIngresos
        .where((i) => filtrarPorVista(i.fecha))
        .fold(0.0, (sum, i) => sum + i.monto);

    final totalGastos = perfil.cnGastos
        .where((g) => filtrarPorVista(g.fecha))
        .fold(0.0, (sum, g) => sum + g.monto);

    return totalIngresos - totalGastos;
  }
}

// Método auxiliar para dar un color único a cada perfil
Color _colorForPerfil(Cuenta cuenta, Perfil perfil) {
  final index = cuenta.perfiles.indexOf(perfil);
  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
  return colors[index % colors.length];
}
