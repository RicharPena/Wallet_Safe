import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart'; // Importar PresupuestoPersonal

enum DateRange { diario, semanal, mensual }

class ChartService {
  static Future<Map<String, dynamic>> obtenerMontosAgrupados({
    required List<dynamic>
    datos, // `dynamic` para flexibilidad con Ingreso/Gasto
    required DateRange rango,
  }) async {
    final now = DateTime.now();
    final Map<String, double> agrupado = {};

    for (var dato in datos) {
      // Asegurarse de que el objeto tenga las propiedades 'fecha' y 'monto'
      // Esto es una asunción basada en tus clases Ingreso y Gasto.
      final DateTime fecha = dato.fecha;
      final double monto = dato.monto;
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

      agrupado.update(clave, (value) => value + monto, ifAbsent: () => monto);
    }

    // Ordenamos claves para mostrarlas correctamente en el gráfico
    final clavesOrdenadas =
        agrupado.keys.toList()..sort((a, b) => _ordenarClaves(a, b, rango));

    final montos = clavesOrdenadas.map((k) => agrupado[k]!).toList();
    final labels = clavesOrdenadas;

    return {'montos': montos, 'labels': labels};
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isSameWeek(DateTime date1, DateTime date2) {
    final startOfWeek1 = _getStartOfWeek(date1);
    final startOfWeek2 = _getStartOfWeek(date2);
    return isSameDay(startOfWeek1, startOfWeek2);
  }

  static DateTime _getStartOfWeek(DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    // weekday 1 = Monday, 7 = Sunday
    // Subtract days to get to the Monday of the current week.
    // Si el día es domingo (7), restar 6 para llegar al lunes anterior.
    // Si el día es lunes (1), restar 0.
    int daysToSubtract =
        normalizedDate.weekday == DateTime.sunday
            ? 6
            : normalizedDate.weekday - DateTime.monday;
    return normalizedDate.subtract(Duration(days: daysToSubtract));
  }

  static int _ordenarClaves(String a, String b, DateRange rango) {
    switch (rango) {
      case DateRange.diario:
        return _parseHora(a).compareTo(_parseHora(b));
      case DateRange.semanal:
        const dias = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return dias.indexOf(a).compareTo(dias.indexOf(b));
      case DateRange.mensual:
        // Extrae el número de la semana y lo compara
        return int.parse(
          a.replaceAll(RegExp(r'\D'), ''),
        ).compareTo(int.parse(b.replaceAll(RegExp(r'\D'), '')));
    }
  }

  static DateTime _parseHora(String h) {
    final parts = h.split(':').map(int.parse).toList();
    // Creamos una fecha ficticia solo para comparar la hora
    return DateTime(0, 1, 1, parts[0], parts[1]);
  }

  static double calcularBalanceNetoMensual(Perfil perfil) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final ingresosMes = perfil.cnIngresos
        .where(
          (i) =>
              i.fecha.isAfter(
                startOfMonth.subtract(const Duration(seconds: 1)),
              ) &&
              i.fecha.isBefore(endOfMonth.add(const Duration(seconds: 1))),
        )
        .fold(0.0, (sum, i) => sum + i.monto);

    final gastosMes = perfil.cnGastos
        .where(
          (g) =>
              g.fecha.isAfter(
                startOfMonth.subtract(const Duration(seconds: 1)),
              ) &&
              g.fecha.isBefore(endOfMonth.add(const Duration(seconds: 1))),
        )
        .fold(0.0, (sum, g) => sum + g.monto);

    return ingresosMes - gastosMes;
  }

  static int obtenerNivelPoderAdquisitivo(Perfil perfil) {
    final balanceNeto = calcularBalanceNetoMensual(perfil);

    // Define tus umbrales (estos son solo ejemplos, ajusta a tu moneda y lógica)
    if (balanceNeto <= -200000) return 1; // Muy negativo
    if (balanceNeto <= 0) return 2; // Negativo o cero
    if (balanceNeto <= 500000) return 3; // Positivo bajo
    if (balanceNeto <= 1500000) return 4; // Positivo moderado
    return 5; // Muy positivo
  }

  static String obtenerRecomendacion(int nivel) {
    switch (nivel) {
      case 1:
        return "Nivel 1: ¡Alerta roja! Tus gastos superan tus ingresos. Es crucial revisar tu presupuesto y encontrar formas de reducir gastos o aumentar ingresos.";
      case 2:
        return "Nivel 2: Estás al límite. Procura que tus ingresos superen tus gastos para evitar deudas. Pequeños cambios pueden hacer una gran diferencia.";
      case 3:
        return "Nivel 3: Buen balance. Mantienes tus finanzas estables, pero hay espacio para el ahorro. Considera destinar un porcentaje fijo de tus ingresos a un fondo de emergencia.";
      case 4:
        return "Nivel 4: ¡Excelente control! Estás generando ahorros consistentemente. Explora opciones de inversión para que tu dinero crezca aún más.";
      case 5:
        return "Nivel 5: ¡Maestro financiero! Tus finanzas son sólidas. Considera diversificar tus inversiones y planificar para metas a largo plazo, como la jubilación.";
      default:
        return "Evalúa tu situación financiera.";
    }
  }

  /// Genera una lista de colores aleatorios pero distintivos.
  static List<Color> generateDistinctColors(int count) {
    final List<Color> colors = [];
    final List<Color> baseColors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
      Colors.cyan,
      Colors.pink,
      Colors.lime,
      Colors.amber,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lightGreen,
    ];

    for (int i = 0; i < count; i++) {
      // Usamos el módulo para ciclar a través de los colores base si hay más categorías que colores.
      colors.add(baseColors[i % baseColors.length]);
    }
    return colors;
  }

  /// Nuevo método para obtener datos de presupuesto agrupados para Pie Charts
  static Future<List<Map<String, dynamic>>>
  obtenerDatosPresupuestosParaPieChart(
    List<PresupuestoPersonal> presupuestos,
  ) async {
    if (presupuestos.isEmpty) {
      return [];
    }

    final Map<String, double> agrupadosPorCategoria = {};
    double totalMonto = 0.0;

    for (var presupuesto in presupuestos) {
      agrupadosPorCategoria.update(
        presupuesto.categoria,
        (value) => value + presupuesto.montoAsignado,
        ifAbsent: () => presupuesto.montoAsignado,
      );
      totalMonto += presupuesto.montoAsignado;
    }

    if (totalMonto == 0) {
      return []; // Evitar división por cero si todos los montos son cero
    }

    final List<Map<String, dynamic>> pieChartData = [];
    final List<String> categories = agrupadosPorCategoria.keys.toList();
    // Asegurarse de que haya suficientes colores para todas las categorías
    final List<Color> colors = generateDistinctColors(categories.length);

    for (int i = 0; i < categories.length; i++) {
      final String category = categories[i];
      final double monto = agrupadosPorCategoria[category]!;
      final double percentage = (monto / totalMonto) * 100;

      pieChartData.add({
        'category': category,
        'amount': monto,
        'percentage': percentage,
        'color': colors[i],
      });
    }

    return pieChartData;
  }
}
