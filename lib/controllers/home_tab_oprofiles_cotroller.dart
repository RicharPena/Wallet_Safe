import 'package:fl_chart/fl_chart.dart';
import 'package:wallet_safe/models/perfil.dart';

class OProfilesController {
  static List<FlSpot> getLineSpots(Perfil perfil, String vista) {
    DateTime now = DateTime.now();

    late List<DateTime> fechas;
    switch (vista) {
      case 'Semana':
        fechas = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
        break;
      case 'Mes':
        fechas = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
        break;
      case 'Hoy':
      default:
        fechas = [now];
        break;
    }

    return fechas.asMap().entries.map((entry) {
      int index = entry.key;
      DateTime fecha = entry.value;

      final ingresos = perfil.cnIngresos
          .where((i) => _esMismaFecha(i.fecha, fecha))
          .fold(0.0, (sum, i) => sum + i.monto);

      final gastos = perfil.cnGastos
          .where((g) => _esMismaFecha(g.fecha, fecha))
          .fold(0.0, (sum, g) => sum + g.monto);

      final balance = ingresos - gastos;
      return FlSpot(index.toDouble(), balance);
    }).toList();
  }

  static bool _esMismaFecha(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
