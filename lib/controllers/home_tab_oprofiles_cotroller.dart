import 'package:fl_chart/fl_chart.dart';

//Por ahora esta clase tomará los nombres y generará valores aleatorios
class OProfilesController {
  static List<FlSpot> getLineSpots(String nombrePerfil) {
    // Usa una semilla derivada del nombre para generar valores distintos
    final seed = nombrePerfil.codeUnits.fold(0, (prev, e) => prev + e);

    return List.generate(7, (i) {
      final y =
          ((seed * i) % 15) -
          5; // Genera un valor pseudoaleatorio entre -5 y 10
      return FlSpot(i.toDouble(), y.toDouble());
    });
  }
}
