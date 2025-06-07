import 'package:wallet_safe/models/presupuesto_personal.dart'; // Importa la nueva clase
import 'package:wallet_safe/models/presupuesto_familiar.dart'; // Importa la nueva clase
import 'perfil.dart';
import 'ingresos.dart';
import 'familia.dart';

// Contador estático para generar IDs únicos temporales
// En una aplicación real, esto lo gestionaría el backend/base de datos.
int _nextPresupuestoId = 0;
int _getNextPresupuestoId() {
  _nextPresupuestoId++;
  return _nextPresupuestoId;
}

class Titular extends Perfil {
  Titular({
    required super.id,
    required super.nombre,
    super.balance,
    super.cnIngresos,
    super.cnGastos,
    super.cnPresupuestosPersonales,
    super.cnPresupuestosFamiliares,
  });

  /// Agrega un ingreso al titular y actualiza el balance
  void agregarIngreso(Ingreso ingreso) {
    cnIngresos.add(ingreso);
    balance += ingreso.monto;
  }

  /// Asigna una cantidad de dinero a un perfil tipo Familia
  bool asignarPresupuestoAFamilia(
    Familia familiar,
    double monto,
    String categoria,
  ) {
    if (monto <= 0) {
      print('El monto a asignar debe ser positivo.');
      return false;
    }
    if (monto > balance) {
      print('El monto supera tu balance disponible.');
      return false;
    }

    // Generar un ID simple para el presupuesto familiar (esto cambiará con el backend)
    int presupuestoFamiliarId = _getNextPresupuestoId();

    //Crea el presupuesto familiar
    PresupuestoFamiliar nuevoPresupuestoFamiliar = PresupuestoFamiliar(
      id: presupuestoFamiliarId,
      montoAsignado: monto,
      categoria: categoria,
      idPerfilFamiliar: familiar.id,
      idTitular: id,
      distribuido: false, // Por defecto, no distribuido al crearse
    );

    // Asignar el presupuesto a la familia
    familiar.agregarPresupuestoFamiliar(nuevoPresupuestoFamiliar);
    // Añadir el presupuesto familiar a la lista de presupuestos familiares del titular (para seguimiento)
    cnPresupuestosFamiliares.add(nuevoPresupuestoFamiliar);

    // Restar el monto del balance del titular
    balance -= monto;
    print(
      'Presupuesto de \$$monto para ${familiar.nombre} en categoría "$categoria" asignado.',
    );
    return true;
  }

  // *** Implementación de agregarPresupuestoPersonal para Titular ***
  @override
  void agregarPresupuestoPersonal(PresupuestoPersonal presupuesto) {
    if (presupuesto.perfilId != id) {
      throw ArgumentError(
        'Este presupuesto personal no pertenece a este perfil titular.',
      );
    }
    cnPresupuestosPersonales.add(presupuesto);
  }

  // *** Implementación de agregarPresupuestoFamiliar para Titular (para registrar los que asigna) ***
  @override
  void agregarPresupuestoFamiliar(PresupuestoFamiliar presupuesto) {
    // Un titular agrega presupuestos familiares a otros, pero también los registra
    // en su propia lista para llevar un control de lo que ha asignado.
    cnPresupuestosFamiliares.add(presupuesto);
  }
}
