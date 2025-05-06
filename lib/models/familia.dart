import 'perfil.dart';
import 'ingresos.dart';

class Familia extends Perfil {
  Familia({
    required super.id,
    required super.nombre,
    super.presupuestoFamiliar,
    super.cnIngresos,
  });

  /// Solo puede agregar sus propios ingresos
  void agregarIngreso(Ingreso ingreso) {
    cnIngresos.add(ingreso);
    presupuestoFamiliar += ingreso.monto;
  }
}
