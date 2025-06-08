import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/familia.dart';
import '../models/presupuesto_familiar.dart';
import '../models/presupuesto_personal.dart';

// Contador estático para generar IDs únicos temporales para los presupuestos
// En una aplicación real, esto lo gestionaría el backend/base de datos.
int _nextLocalBudgetId = 0;
int _getNextLocalBudgetId() {
  _nextLocalBudgetId++;
  return _nextLocalBudgetId;
}

// Definimos un StateNotifier para nuestro FamiliaViewModel
class FamiliaViewModel extends StateNotifier<Familia?> {
  FamiliaViewModel() : super(null);

  void cargarFamilia(Familia familia) {
    state = familia;
  }

  PresupuestoFamiliar? getPresupuestoFamiliarPendiente() {
    if (state == null) return null;
    try {
      return state!.cnPresupuestosFamiliares.firstWhere(
        (pf) => !pf.distribuido,
      );
    } catch (e) {
      return null;
    }
  }

  // Método para procesar la subdivisión de un presupuesto familiar
  void procesarPresupuestoFamiliar(
    PresupuestoFamiliar presupuestoFamiliar,
    List<Map<String, dynamic>> subdivisiones,
  ) {
    if (state == null) return;

    // Crear una copia de la familia para realizar modificaciones inmutables
    // Aunque nuestro modelo Familia es mutable, esta es una buena práctica
    // para los StateNotifiers de Riverpod para asegurar la reactividad.
    Familia familiaActualizada = Familia(
      id: state!.id,
      nombre: state!.nombre,
      balance: state!.balance,
      cnIngresos: List.from(state!.cnIngresos), // Copiar listas
      cnGastos: List.from(state!.cnGastos),
      cnPresupuestosPersonales: List.from(state!.cnPresupuestosPersonales),
      cnPresupuestosFamiliares: List.from(state!.cnPresupuestosFamiliares),
    );

    double totalDistribuido = 0;
    List<PresupuestoPersonal> nuevosPresupuestosPersonales = [];

    for (var sub in subdivisiones) {
      double montoSub = sub['monto'] as double;
      String categoriaSub = sub['categoria'] as String;

      PresupuestoPersonal nuevoPresupuesto = PresupuestoPersonal(
        id: _getNextLocalBudgetId(), // Generar un ID entero único
        montoAsignado: montoSub,
        categoria: categoriaSub,
        perfilId: familiaActualizada.id,
        idPresupuestoFamiliarOrigen:
            presupuestoFamiliar.id, // Referencia al origen
      );
      nuevosPresupuestosPersonales.add(nuevoPresupuesto);
      totalDistribuido += montoSub;
    }

    familiaActualizada.cnPresupuestosPersonales.addAll(
      nuevosPresupuestosPersonales,
    );
    familiaActualizada.balance += totalDistribuido;

    // Marcar el presupuesto familiar original como distribuido
    // Buscamos la instancia exacta del presupuesto familiar en la lista de la familia actualizada
    // para modificar su propiedad 'distribuido'.
    final index = familiaActualizada.cnPresupuestosFamiliares.indexWhere(
      (pf) => pf.id == presupuestoFamiliar.id,
    );
    if (index != -1) {
      familiaActualizada.cnPresupuestosFamiliares[index] = PresupuestoFamiliar(
        id: presupuestoFamiliar.id,
        montoAsignado: presupuestoFamiliar.montoAsignado,
        categoria: presupuestoFamiliar.categoria,
        idPerfilFamiliar: presupuestoFamiliar.idPerfilFamiliar,
        idTitular: presupuestoFamiliar.idTitular,
        distribuido: true, // Marcar como distribuido
      );
    }

    state = familiaActualizada; // Actualizar el estado con la nueva familia
    print(
      'Presupuesto familiar ${presupuestoFamiliar.id} distribuido y balance actualizado.',
    );
  }
}

// Proveedor que expone el FamiliaViewModel a la aplicación
final familiaViewModelProvider =
    StateNotifierProvider.autoDispose<FamiliaViewModel, Familia?>(
      (ref) => FamiliaViewModel(),
    );
