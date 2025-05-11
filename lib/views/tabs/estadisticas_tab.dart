import 'package:flutter/material.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/widgets/gastos_chart.dart';
import 'package:wallet_safe/widgets/ingresos_chart.dart';
import 'package:wallet_safe/services/chart_service.dart';

class EstadisticasTab extends StatefulWidget {
  final Perfil perfil;

  const EstadisticasTab({super.key, required this.perfil});

  @override
  State<EstadisticasTab> createState() => _EstadisticasTabState();
}

class _EstadisticasTabState extends State<EstadisticasTab> {
  DateRange _rangoSeleccionado = DateRange.mensual;

  @override
  Widget build(BuildContext context) {
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
                ingresos: widget.perfil.cnIngresos,
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
                gastos: widget.perfil.cnGastos,
                rango: _rangoSeleccionado,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
