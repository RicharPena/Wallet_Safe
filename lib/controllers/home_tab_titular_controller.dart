import 'package:fl_chart/fl_chart.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/ingresos.dart';
import 'package:wallet_safe/models/gastos.dart';

class TitularController {
  static List<FlSpot> getLineSpots(Perfil perfil, String vista) {
    DateTime now = DateTime.now();

    late List<DateTime> fechas;
    switch (vista) {
      case 'Semana':
        fechas = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
        break;
      case 'Mes':
        fechas = List.generate(4, (i) {
          final start = now.subtract(Duration(days: (4 - i) * 7));
          return start;
        });
        break;
      case 'Hoy':
        final hoy = DateTime(now.year, now.month, now.day);
        final eventos =
            [
              ...perfil.cnIngresos.map(
                (i) => {'fecha': i.fecha, 'monto': i.monto},
              ),
              ...perfil.cnGastos.map(
                (g) => {'fecha': g.fecha, 'monto': -g.monto},
              ),
            ].where((e) {
              final f = e['fecha'] as DateTime;
              return f.year == hoy.year &&
                  f.month == hoy.month &&
                  f.day == hoy.day;
            }).toList();

        eventos.sort(
          (a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime),
        );

        double acumulado = 0;
        return eventos.map((e) {
          acumulado += e['monto'] as double;
          final fecha = e['fecha'] as DateTime;
          final minutosDesdeMedianoche = fecha.hour * 60 + fecha.minute;
          return FlSpot(minutosDesdeMedianoche.toDouble(), acumulado);
        }).toList();
      default:
        fechas = [now];
        break;
    }

    return fechas.asMap().entries.map((entry) {
      int index = entry.key;
      DateTime semanaInicio = entry.value;
      DateTime semanaFin = semanaInicio.add(const Duration(days: 6));

      final ingresos = perfil.cnIngresos
          .where(
            (i) =>
                i.fecha.isAfter(
                  semanaInicio.subtract(const Duration(seconds: 1)),
                ) &&
                i.fecha.isBefore(semanaFin.add(const Duration(days: 1))),
          )
          .fold(0.0, (sum, i) => sum + i.monto);

      final gastos = perfil.cnGastos
          .where(
            (g) =>
                g.fecha.isAfter(
                  semanaInicio.subtract(const Duration(seconds: 1)),
                ) &&
                g.fecha.isBefore(semanaFin.add(const Duration(days: 1))),
          )
          .fold(0.0, (sum, g) => sum + g.monto);

      final balance = ingresos - gastos;
      return FlSpot(index.toDouble(), balance);
    }).toList();
  }
}
