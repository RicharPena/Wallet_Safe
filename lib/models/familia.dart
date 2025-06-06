import 'perfil.dart';
import 'ingresos.dart';

class Familia extends Perfil {
  Familia({
    required super.id,
    required super.nombre,
    super.balance,
    super.cnIngresos,
  });

  /// Solo puede agregar sus propios ingresos
  void agregarIngreso(Ingreso ingreso) {
    cnIngresos.add(ingreso);
    balance += ingreso.monto;
  }
}
