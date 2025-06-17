import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wallet_safe/controllers/home_tab_profiles_controller.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/controllers/graphics_helper_controller.dart';
import 'package:wallet_safe/widgets/resumen_lineal.dart';
import 'package:wallet_safe/providers/app_providers.dart';

// Extensión para firstWhereOrNull, la mantendremos aquí por ahora si es global.
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class HomeTab extends ConsumerStatefulWidget {
  final VoidCallback onLogout;

  const HomeTab({required this.onLogout, super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String currentView = 'Hoy'; // Control de vista (Hoy, Semana, Mes)

  @override
  Widget build(BuildContext context) {
    // ref.listen para cargar FamiliaViewModel
    ref.listen<Perfil?>(perfilActivoProvider, (previousPerfil, newPerfil) {
      if (newPerfil is Familia) {
        ref
            .read(familiaViewModelProvider.notifier)
            .cargarFamilia(newPerfil, context);
        debugPrint(
          'HomeTab (listener): Perfil de Familia cargado en FamiliaViewModel: ${newPerfil.nombre}',
        );
      } else {
        ref.listen<Perfil?>(perfilActivoProvider, (previousPerfil, newPerfil) {
          if (newPerfil is Familia) {
            // Pasa el BuildContext aquí a cargarFamilia
            ref
                .read(familiaViewModelProvider.notifier)
                .cargarFamilia(newPerfil, context);
            debugPrint(
              'HomeTab (listener): Perfil de Familia cargado en FamiliaViewModel: ${newPerfil.nombre}',
            );
          } else {
            ref.read(familiaViewModelProvider.notifier).resetFamilia();
            debugPrint(
              'HomeTab (listener): Perfil no es Familia, FamiliaViewModel reseteado.',
            );
          }
        });
        ref.read(familiaViewModelProvider.notifier).resetFamilia();
        debugPrint(
          'HomeTab (listener): Perfil no es Familia, FamiliaViewModel reseteado.',
        );
      }
      // NOTA: La lógica de notificación de presupuesto NO está aquí en esta versión.
    });

    final Perfil? perfilActivo = ref.watch(perfilActivoProvider);
    final AsyncValue<List<Perfil>> allPerfilesAsync = ref.watch(
      allPerfilesForGraphProvider,
    );

    if (perfilActivo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isTitular = perfilActivo.nombre == "Titular";

    // ---- INICIO DEBUGGING ADICIONAL PARA HOY ----
    debugPrint(
      'HomeTab (build): currentView: $currentView. Perfil Activo: ${perfilActivo.nombre}',
    );
    if (currentView == 'Hoy') {
      final now = DateTime.now();
      debugPrint('HomeTab (build): Fecha y hora actual del dispositivo: $now');
      debugPrint(
        'HomeTab (build): Inicio del día actual: ${DateTime(now.year, now.month, now.day)}',
      );

      perfilActivo.cnIngresos.forEach((ingreso) {
        final isToday =
            (ingreso.fecha.year == now.year &&
                ingreso.fecha.month == now.month &&
                ingreso.fecha.day == now.day);
        debugPrint(
          'HomeTab (build): Ingreso fecha: ${ingreso.fecha}, monto: ${ingreso.monto}, ¿Es hoy?: $isToday',
        );
      });

      perfilActivo.cnGastos.forEach((gasto) {
        final isToday =
            (gasto.fecha.year == now.year &&
                gasto.fecha.month == now.month &&
                gasto.fecha.day == now.day);
        debugPrint(
          'HomeTab (build): Gasto fecha: ${gasto.fecha}, monto: ${gasto.monto}, ¿Es hoy?: $isToday',
        );
      });
    }
    // ---- FIN DEBUGGING ADICIONAL PARA HOY ----

    return allPerfilesAsync.when(
      data: (allPerfilesForGraph) {
        final perfilesNormales =
            isTitular
                ? allPerfilesForGraph
                    .where((p) => p.nombre != "Titular")
                    .toList()
                : <Perfil>[];

        final dineroActual = calcularDineroActual(perfilActivo, currentView);

        final List<LineChartBarData> lines = [];

        if (isTitular) {
          final titularSpots = ProfilesController.getLineSpots(
            perfilActivo,
            currentView,
          );
          lines.add(
            LineChartBarData(
              spots: titularSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          );
        }

        if (isTitular) {
          for (final perfil in perfilesNormales) {
            final spots = ProfilesController.getLineSpots(perfil, currentView);
            lines.add(
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: _colorForPerfil(allPerfilesForGraph, perfil),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            );
          }
        } else {
          final spots = ProfilesController.getLineSpots(
            perfilActivo,
            currentView,
          );
          lines.add(
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          );
        }

        final List<FlSpot> allSpots =
            lines.expand((line) => line.spots).toList();

        final bounds = GraphHelper.getMinMax(allSpots);

        return Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onLogout,
                    ),
                    title: Text(
                      'Hola, ${perfilActivo.nombre}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (perfilActivo.nombre == "Titular")
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0, top: 10),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                    lineBarsData: lines,
                    currentView: currentView,
                  ),
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Text('Error al cargar perfiles para el gráfico: $error'),
          ),
    );
  }

  double calcularDineroActual(Perfil perfil, String vista) {
    DateTime now = DateTime.now();

    bool filtrarPorVista(DateTime fecha) {
      final hoy = DateTime(now.year, now.month, now.day);
      debugPrint(
        'HomeTab (filtrarPorVista): Analizando fecha: $fecha, hoy (sin hora): $hoy',
      );
      switch (vista) {
        case 'Hoy':
          final result =
              fecha.year == hoy.year &&
              fecha.month == hoy.month &&
              fecha.day == hoy.day;
          debugPrint(
            'HomeTab (filtrarPorVista): Vista HOY: fecha $fecha vs hoy $hoy. Resultado: $result',
          );
          return result;
        case 'Semana':
          final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
          final finSemana = inicioSemana.add(const Duration(days: 6));
          final result =
              fecha.isAfter(
                inicioSemana.subtract(const Duration(seconds: 1)),
              ) &&
              fecha.isBefore(finSemana.add(const Duration(days: 1)));
          debugPrint(
            'HomeTab (filtrarPorVista): Vista SEMANA: fecha $fecha entre $inicioSemana y $finSemana. Resultado: $result',
          );
          return result;
        case 'Mes':
          final result = fecha.year == hoy.year && fecha.month == hoy.month;
          debugPrint(
            'HomeTab (filtrarPorVista): Vista MES: fecha $fecha vs mes actual. Resultado: $result',
          );
          return result;
        default:
          debugPrint('HomeTab (filtrarPorVista): Vista DEFAULT: true');
          return true;
      }
    }

    final totalIngresos = perfil.cnIngresos
        .where((i) => filtrarPorVista(i.fecha))
        .fold(0.0, (sum, i) => sum + i.monto);
    debugPrint(
      'HomeTab (calcularDineroActual): Total Ingresos para $vista: $totalIngresos',
    );

    final totalGastos = perfil.cnGastos
        .where((g) => filtrarPorVista(g.fecha))
        .fold(0.0, (sum, g) => sum + g.monto);
    debugPrint(
      'HomeTab (calcularDineroActual): Total Gastos para $vista: $totalGastos',
    );

    return totalIngresos - totalGastos;
  }
}

Color _colorForPerfil(List<Perfil> todosLosPerfiles, Perfil perfil) {
  final index = todosLosPerfiles.indexOf(perfil);
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];
  if (index == -1) {
    return Colors.grey;
  }
  return colors[index % colors.length];
}
