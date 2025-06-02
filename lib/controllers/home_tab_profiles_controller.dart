import 'package:fl_chart/fl_chart.dart';
import 'package:wallet_safe/models/perfil.dart';

class ProfilesController {
  // Función auxiliar para normalizar una fecha (eliminar información de tiempo)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Función auxiliar para obtener el inicio de la semana
  static DateTime _getStartOfWeek(DateTime date) {
    DateTime normalizedDate = _normalizeDate(date);
    // Dart's weekday starts with Monday=1, Sunday=7
    // So, if today is Wednesday (3), we subtract 2 days to get Monday
    return normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  }

  // Función auxiliar para obtener el inicio del mes
  static DateTime _getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Función auxiliar para obtener el final del mes
  static DateTime _getEndOfMonth(DateTime date) {
    return DateTime(
      date.year,
      date.month + 1,
      0,
    ); // Día 0 del siguiente mes es el último día del actual
  }

  static List<FlSpot> getLineSpots(Perfil perfil, String vista) {
    DateTime now = DateTime.now();

    if (vista == 'Hoy') {
      final hoy = _normalizeDate(now);
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
            return _normalizeDate(f) == hoy;
          }).toList();

      eventos.sort(
        (a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime),
      );

      double acumulado = 0;
      if (eventos.isEmpty) {
        // Si no hay eventos hoy, mostrar un punto en el inicio del día con 0
        return [FlSpot(0, 0)];
      }

      final List<FlSpot> spots = [];
      // Asegurarse de tener un punto en 00:00 si hay transacciones
      spots.add(FlSpot(0, 0));

      for (var e in eventos) {
        acumulado += e['monto'] as double;
        final fecha = e['fecha'] as DateTime;
        final minutosDesdeMedianoche =
            (fecha.hour * 60 + fecha.minute).toDouble();
        spots.add(FlSpot(minutosDesdeMedianoche, acumulado));
      }
      return spots;
    } else if (vista == 'Semana') {
      final startOfWeek = _getStartOfWeek(now);
      final Map<DateTime, double> dailyBalances = {};

      // 1. Calcular el balance final para cada día con transacciones
      for (int i = 0; i < 7; i++) {
        final currentDay = startOfWeek.add(Duration(days: i));
        final nextDay = currentDay.add(
          const Duration(days: 1),
        ); // Para filtrar hasta el final del día

        // Obtener todos los ingresos y gastos hasta el final de este día
        final ingresosDelDia = perfil.cnIngresos
            .where(
              (i) =>
                  i.fecha.isAfter(
                    currentDay.subtract(const Duration(seconds: 1)),
                  ) &&
                  i.fecha.isBefore(nextDay),
            )
            .fold(0.0, (sum, i) => sum + i.monto);

        final gastosDelDia = perfil.cnGastos
            .where(
              (g) =>
                  g.fecha.isAfter(
                    currentDay.subtract(const Duration(seconds: 1)),
                  ) &&
                  g.fecha.isBefore(nextDay),
            )
            .fold(0.0, (sum, g) => sum + g.monto);

        final balanceHoy = ingresosDelDia - gastosDelDia;
        dailyBalances[_normalizeDate(currentDay)] = balanceHoy;
      }

      // 2. Acumular y rellenar los datos según la lógica requerida
      final List<FlSpot> spots = [];
      double currentBalance = 0;

      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final normalizedDay = _normalizeDate(day);

        if (dailyBalances.containsKey(normalizedDay)) {
          // Si hay movimientos en este día, sumar al balance actual
          currentBalance += dailyBalances[normalizedDay]!;
        }
        // Para los días futuros sin transacciones, o días pasados sin transacciones hasta el primer registro,
        // el balance actual ya tiene el último valor conocido o 0 si no hubo nada.
        spots.add(
          FlSpot(i.toDouble(), currentBalance),
        ); // X-axis index 0-6 for Mon-Sun
      }
      return spots;
    } else if (vista == 'Mes') {
      final startOfMonth = _getStartOfMonth(now);
      final endOfMonth = _getEndOfMonth(now);

      final Map<int, double> weeklyBalances = {}; // balance neto por semana
      List<DateTime> weeksInMonthStarts = []; // inicio de cada semana en el mes

      // Calcular todas las semanas que tocan este mes
      DateTime currentWeekStart = _getStartOfWeek(startOfMonth);
      while (currentWeekStart.isBefore(
        endOfMonth.add(const Duration(days: 7)),
      )) {
        // Asegurarse de capturar la última semana
        weeksInMonthStarts.add(currentWeekStart);
        currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      }

      // Filtrar para asegurar que solo consideramos semanas que realmente pertenecen a este mes
      // y obtener el balance para cada semana
      for (int i = 0; i < weeksInMonthStarts.length; i++) {
        final weekStart = weeksInMonthStarts[i];
        final weekEnd = weekStart
            .add(const Duration(days: 7))
            .subtract(const Duration(microseconds: 1)); // Fin del domingo

        // Solo consideramos las transacciones que ocurren dentro de los límites del mes actual
        final ingresosDeLaSemana = perfil.cnIngresos
            .where(
              (i) =>
                  i.fecha.isAfter(
                    weekStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  i.fecha.isBefore(weekEnd.add(const Duration(seconds: 1))) &&
                  i.fecha.month == now.month &&
                  i.fecha.year ==
                      now.year, // Asegurar que está en el mes actual
            )
            .fold(0.0, (sum, i) => sum + i.monto);

        final gastosDeLaSemana = perfil.cnGastos
            .where(
              (g) =>
                  g.fecha.isAfter(
                    weekStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  g.fecha.isBefore(weekEnd.add(const Duration(seconds: 1))) &&
                  g.fecha.month == now.month &&
                  g.fecha.year ==
                      now.year, // Asegurar que está en el mes actual
            )
            .fold(0.0, (sum, g) => sum + g.monto);

        final balanceSemanal = ingresosDeLaSemana - gastosDeLaSemana;
        weeklyBalances[i] =
            balanceSemanal; // Usamos 'i' como índice de la semana (0, 1, 2, 3...)
      }

      // 2. Acumular y rellenar los datos según la lógica requerida
      final List<FlSpot> spots = [];
      double currentBalance = 0;

      for (int i = 0; i < weeksInMonthStarts.length; i++) {
        if (weeklyBalances.containsKey(i)) {
          currentBalance += weeklyBalances[i]!;
        }
        spots.add(
          FlSpot(i.toDouble(), currentBalance),
        ); // X-axis index 0, 1, 2, 3... for weeks
      }
      return spots;
    }
    // Default o caso no manejado
    return [];
  }
}
