import 'package:fl_chart/fl_chart.dart';

class GraphHelper {
  static ({double minX, double maxX, double minY, double maxY}) getMinMax(
    List<FlSpot> spots,
  ) {
    double minX = spots.first.x;
    double maxX = spots.first.x;
    double minY = spots.first.y;
    double maxY = spots.first.y;

    for (final spot in spots) {
      if (spot.x < minX) minX = spot.x;
      if (spot.x > maxX) maxX = spot.x;
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }

    // Le damos un margen visual
    const double paddingX = 1.0;
    const double paddingY = 5.0;

    return (
      minX: minX - paddingX,
      maxX: maxX + paddingX,
      minY: minY - paddingY,
      maxY: maxY + paddingY,
    );
  }
}
