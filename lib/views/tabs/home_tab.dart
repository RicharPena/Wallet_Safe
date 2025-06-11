import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wallet_safe/controllers/home_tab_profiles_controller.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/controllers/graphics_helper_controller.dart';
import 'package:wallet_safe/widgets/resumen_lineal.dart';
import 'package:wallet_safe/providers/app_providers.dart';

// Extensión para firstWhereOrNull, la mantendremos aquí por ahora si es global.
// Si solo se usa en HomeTab, podrías moverla dentro del archivo si prefieres.
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// 1. Cambia a ConsumerStatefulWidget
class HomeTab extends ConsumerStatefulWidget {
  final VoidCallback onLogout;

  const HomeTab({required this.onLogout, super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

// 3. Cambia a ConsumerState
class _HomeTabState extends ConsumerState<HomeTab> {
  String currentView = 'Hoy'; // Control de vista (Hoy, Semana, Mes)
  // dineroActual ya no necesita ser una variable de estado aquí,
  // se calculará en el build con los datos reactivos.

  @override
  Widget build(BuildContext context) {
    // 3. Obtén la cuenta y el perfil desde los providers
    final Cuenta? cuentaActiva = ref.watch(cuentaActivaProvider);
    final Perfil? perfilActivo = ref.watch(perfilSeleccionadoProvider);

    if (cuentaActiva == null || perfilActivo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Usa perfilActivo en lugar de widget.perfil
    final isTitular = perfilActivo.nombre == "Titular";

    // Usa cuentaActiva en lugar de widget.cuenta para acceder a otros perfiles
    final perfilesNormales =
        cuentaActiva.perfiles.where((p) => p.nombre != "Titular").toList();

    // Llama a calcularDineroActual con perfilActivo
    final dineroActual = calcularDineroActual(perfilActivo, currentView);

    final List<FlSpot> titularSpots =
        isTitular
            ? ProfilesController.getLineSpots(perfilActivo, currentView)
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
                // 4. Actualiza _colorForPerfil para usar cuentaActiva
                color: _colorForPerfil(cuentaActiva, perfil),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              );
            }).toList()
            : [
              LineChartBarData(
                spots: ProfilesController.getLineSpots(
                  perfilActivo, // Usa perfilActivo
                  currentView,
                ),
                isCurved: true,
                color: Colors.green, // Color para el perfil no titular
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
                  icon: const Icon(Icons.arrow_back), // Usa const si no cambia
                  onPressed: widget.onLogout,
                ),
                title: Text(
                  'Hola, ${perfilActivo.nombre}', // Usa perfilActivo
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (perfilActivo.nombre == "Titular") // Usa perfilActivo
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

  // Método auxiliar para cálculo de dinero actual
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
          final finSemana = inicioSemana.add(const Duration(days: 6));
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
// Este método ahora recibe la Cuenta para poder iterar sobre sus perfiles.
Color _colorForPerfil(Cuenta cuenta, Perfil perfil) {
  final index = cuenta.perfiles.indexOf(perfil);
  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
  return colors[index % colors.length];
}
