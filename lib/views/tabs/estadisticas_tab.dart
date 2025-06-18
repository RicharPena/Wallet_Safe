import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/widgets/gastos_chart.dart';
import 'package:wallet_safe/widgets/ingresos_chart.dart';
import 'package:wallet_safe/services/chart_service.dart';
import 'package:wallet_safe/widgets/recomendations_dialog.dart';
import 'package:wallet_safe/providers/app_providers.dart';
import 'package:wallet_safe/widgets/presupuestos_personales_chart.dart'; // Importar el nuevo widget
import 'package:wallet_safe/widgets/presupuestos_familiares_chart.dart'; // Importar el nuevo widget

// Cambiamos a ConsumerStatefulWidget para acceder a Riverpod
class EstadisticasTab extends ConsumerStatefulWidget {
  const EstadisticasTab({super.key});

  @override
  ConsumerState<EstadisticasTab> createState() => _EstadisticasTabState();
}

class _EstadisticasTabState extends ConsumerState<EstadisticasTab> {
  DateRange _rangoSeleccionado = DateRange.diario;

  @override
  Widget build(BuildContext context) {
    final Perfil? perfil = ref.watch(perfilActivoProvider);

    debugPrint('EstadisticasTab: Perfil Activo ID: ${perfil?.id}');
    debugPrint('EstadisticasTab: Perfil Activo Nombre: ${perfil?.nombre}');
    debugPrint(
      'EstadisticasTab: # Ingresos en Perfil: ${perfil?.cnIngresos.length}',
    );
    debugPrint(
      'EstadisticasTab: # Gastos en Perfil: ${perfil?.cnGastos.length}',
    );
    debugPrint(
      'EstadisticasTab: # Presupuestos Personales en Perfil: ${perfil?.cnPresupuestosPersonales.length}',
    );
    debugPrint(
      'EstadisticasTab: # Presupuestos Familiares en Perfil (via personales con origen): ${perfil?.cnPresupuestosPersonales.where((p) => p.idPresupuestoFamiliarOrigen != null).length}',
    );

    if (perfil == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando perfil...'),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Ver por:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                DropdownButton<DateRange>(
                  value: _rangoSeleccionado,
                  items: const [
                    DropdownMenuItem(
                      value: DateRange.diario,
                      child: Text("Hoy"),
                    ),
                    DropdownMenuItem(
                      value: DateRange.semanal,
                      child: Text("Semana"),
                    ),
                    DropdownMenuItem(
                      value: DateRange.mensual,
                      child: Text("Mes"),
                    ),
                  ],
                  onChanged: (nuevo) {
                    if (nuevo != null) {
                      setState(() {
                        _rangoSeleccionado = nuevo;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("📈 Ingresos", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IngresosChart(
                ingresos: perfil.cnIngresos,
                rango: _rangoSeleccionado,
              ),
            ),
            const SizedBox(height: 20),
            Text("📉 Gastos", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: GastosChart(
                gastos: perfil.cnGastos,
                rango: _rangoSeleccionado,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "📊 Presupuestos Personales",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: PresupuestosPersonalesChart(
                presupuestos: perfil.cnPresupuestosPersonales,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "👨‍👩‍👧‍👦 Presupuestos Familiares (Distribuidos)",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: PresupuestosFamiliaresChart(
                presupuestosPersonales: perfil.cnPresupuestosPersonales,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {
                  FinancialInsightDialog.show(context, perfil);
                },
                icon: const Icon(Icons.info_outline),
                label: const Text("Ver Nivel Financiero"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
