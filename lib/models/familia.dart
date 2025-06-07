import 'package:wallet_safe/models/presupuesto_personal.dart'; // Importa la nueva clase
import 'package:wallet_safe/models/presupuesto_familiar.dart'; // Importa la nueva clase
import 'perfil.dart';
import 'ingresos.dart';

class Familia extends Perfil {
  Familia({
    required super.id,
    required super.nombre,
    super.balance,
    super.cnIngresos,
    super.cnGastos,
    super.cnPresupuestosPersonales,
    super.cnPresupuestosFamiliares, //Recibe el presupuesto otorgado por el titular
  });

  /// Solo puede agregar sus propios ingresos
  void agregarIngreso(Ingreso ingreso) {
    cnIngresos.add(ingreso);
    balance += ingreso.monto;
  }

  // *** Implementación de agregarPresupuestoPersonal para Familia ***
  @override
  void agregarPresupuestoPersonal(PresupuestoPersonal presupuesto) {
    if (presupuesto.perfilId != id) {
      throw ArgumentError(
        'Este presupuesto personal no pertenece a este perfil familiar.',
      );
    }
    cnPresupuestosPersonales.add(presupuesto);
  }

  // *** Implementación de agregarPresupuestoFamiliar para Familia (solo para recibirlo) ***
  @override
  void agregarPresupuestoFamiliar(PresupuestoFamiliar presupuesto) {
    if (presupuesto.idPerfilFamiliar != id) {
      throw ArgumentError(
        'Este presupuesto familiar no está destinado para este perfil familiar.',
      );
    }
    cnPresupuestosFamiliares.add(presupuesto);
  }
}
