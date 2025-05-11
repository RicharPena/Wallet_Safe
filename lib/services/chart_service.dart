import 'package:intl/intl.dart';

enum DateRange { diario, semanal, mensual }

class ChartService {
  static Future<Map<String, dynamic>> obtenerMontosAgrupados({
    required List<dynamic> datos,
    required DateRange rango,
  }) async {
    final now = DateTime.now();
    final Map<String, double> agrupado = {};

    for (var dato in datos) {
      final fecha = dato.fecha;
      String clave;

      switch (rango) {
        case DateRange.diario:
          if (isSameDay(fecha, now)) {
            clave = DateFormat.Hm().format(fecha); // Ej: "06:00"
          } else {
            continue;
          }
          break;

        case DateRange.semanal:
          if (isSameWeek(fecha, now)) {
            clave = DateFormat.E().format(fecha); // Ej: "Mon", "Tue"
          } else {
            continue;
          }
          break;

        case DateRange.mensual:
          if (fecha.year == now.year && fecha.month == now.month) {
            final semana = ((fecha.day - 1) / 7).floor() + 1;
            clave = 'Semana $semana';
          } else {
            continue;
          }
          break;
      }

      agrupado.update(
        clave,
        (value) => value + dato.monto,
        ifAbsent: () => dato.monto,
      );
    }

    // Ordenamos claves para mostrarlas correctamente en el gráfico
    final clavesOrdenadas =
        agrupado.keys.toList()..sort((a, b) => _ordenarClaves(a, b, rango));

    final montos = clavesOrdenadas.map((k) => agrupado[k]!).toList();
    final labels = clavesOrdenadas;

    return {'montos': montos, 'labels': labels};
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameWeek(DateTime a, DateTime b) {
    final mondayA = a.subtract(Duration(days: a.weekday - 1));
    final mondayB = b.subtract(Duration(days: b.weekday - 1));
    return isSameDay(mondayA, mondayB);
  }

  static int _ordenarClaves(String a, String b, DateRange rango) {
    switch (rango) {
      case DateRange.diario:
        return _parseHora(a).compareTo(_parseHora(b));
      case DateRange.semanal:
        const dias = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return dias.indexOf(a).compareTo(dias.indexOf(b));
      case DateRange.mensual:
        return int.parse(
          a.replaceAll(RegExp(r'\D'), ''),
        ).compareTo(int.parse(b.replaceAll(RegExp(r'\D'), '')));
    }
  }

  static DateTime _parseHora(String h) {
    final parts = h.split(':').map(int.parse).toList();
    return DateTime(0, 1, 1, parts[0], parts[1]);
  }
}
