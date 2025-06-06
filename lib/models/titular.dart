import 'perfil.dart';
import 'ingresos.dart';
import 'familia.dart';

class Titular extends Perfil {
  Titular({
    required super.id,
    required super.nombre,
    super.balance,
    super.cnIngresos,
  });

  /// Agrega un ingreso al titular y actualiza el presupuesto
  void agregarIngreso(Ingreso ingreso) {
    cnIngresos.add(ingreso);
    balance += ingreso.monto;
  }

  /// Asigna una cantidad de dinero a un perfil tipo Familia
  bool asignarPresupuestoAFamilia(Familia familiar, double monto) {
    if (monto <= 0) return false;
    if (monto > balance) return false;

    familiar.balance += monto;
    balance -= monto;
    return true;
  }
}
