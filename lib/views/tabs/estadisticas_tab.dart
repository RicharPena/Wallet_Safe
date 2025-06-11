import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/widgets/gastos_chart.dart';
import 'package:wallet_safe/widgets/ingresos_chart.dart';
import 'package:wallet_safe/services/chart_service.dart';
import 'package:wallet_safe/widgets/recomendations_dialog.dart';
import 'package:wallet_safe/providers/app_providers.dart'; // Importar app_providers para acceder a los providers

// Cambiamos a ConsumerStatefulWidget para acceder a Riverpod
class EstadisticasTab extends ConsumerStatefulWidget {
  const EstadisticasTab({super.key}); // Eliminamos el parámetro 'perfil'

  @override
  ConsumerState<EstadisticasTab> createState() => _EstadisticasTabState();
}

// Cambiamos a ConsumerState
class _EstadisticasTabState extends ConsumerState<EstadisticasTab> {
  // Mantenemos _rangoSeleccionado como estado local del widget por ahora.
  // Si esta lógica crece o necesita ser compartida, podríamos moverla a un Controller/Provider.
  DateRange _rangoSeleccionado = DateRange.diario;

  @override
  Widget build(BuildContext context) {
    // Observamos el perfil seleccionado usando ref.watch
    // Cada vez que perfilSeleccionadoProvider notifique un cambio, este widget se reconstruirá.
    final Perfil? perfil = ref.watch(perfilSeleccionadoProvider);

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
                // Pasamos el perfil obtenido de Riverpod
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
                // Pasamos el perfil obtenido de Riverpod
                gastos: perfil.cnGastos,
                rango: _rangoSeleccionado,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Pasamos el perfil obtenido de Riverpod
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
