import 'perfil.dart';
import 'ingresos.dart';
import 'familia.dart';

class Titular extends Perfil {
  Titular({
    required super.id,
    required super.nombre,
    super.presupuestoFamiliar,
    super.cnIngresos,
  });

  /// Agrega un ingreso al titular y actualiza el presupuesto
  void agregarIngreso(Ingreso ingreso) {
    cnIngresos.add(ingreso);
    presupuestoFamiliar += ingreso.monto;
  }

  /// Asigna una cantidad de dinero a un perfil tipo Familia
  bool asignarPresupuestoAFamilia(Familia familiar, double monto) {
    if (monto <= 0) return false;
    if (monto > presupuestoFamiliar) return false;

    familiar.presupuestoFamiliar += monto;
    presupuestoFamiliar -= monto;
    return true;
  }
}
