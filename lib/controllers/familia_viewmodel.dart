import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/perfil.dart';
import '../models/familia.dart';
import '../models/presupuesto_familiar.dart';
import '../models/presupuesto_personal.dart';
import '../services/perfil_service.dart'; // Importamos el servicio

// Definimos un StateNotifier para nuestro FamiliaViewModel
class FamiliaViewModel extends StateNotifier<Familia?> {
  final PerfilService _perfilService; // Inyectamos el servicio
  final Function(Perfil)
  _updatePerfilInNotifier; // Callback para actualizar el PerfilActivoNotifier

  FamiliaViewModel({
    required PerfilService perfilService,
    required Function(Perfil) updatePerfilInNotifier,
  }) : _perfilService = perfilService,
       _updatePerfilInNotifier = updatePerfilInNotifier,
       super(null);

  void cargarFamilia(Familia familia) {
    state = familia;
    debugPrint('FamiliaViewModel: Familia cargada: ${familia.nombre}');
    debugPrint(
      'FamiliaViewModel: Presupuestos familiares en la familia cargada: ${familia.cnPresupuestosFamiliares.length}',
    );
    if (familia.cnPresupuestosFamiliares.isEmpty) {
      debugPrint(
        'FamiliaViewModel: La lista cnPresupuestosFamiliares ESTÁ VACÍA.',
      );
    }
    // Puedes incluso imprimir el contenido si no es muy grande
    for (var p in familia.cnPresupuestosFamiliares) {
      debugPrint(
        '  - Presupuesto Familiar: ${p.categoria}, Monto: ${p.montoAsignado}, Distribuido: ${p.distribuido}',
      );
    }
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

  void resetFamilia() {
    state = null;
    debugPrint('FamiliaViewModel: Estado reseteado (Familia = null).');
  }

  List<PresupuestoPersonal> get presupuestosPersonalesDeFamiliares {
    if (state == null) return [];
    return state!.cnPresupuestosPersonales
        .where((pp) => pp.idPresupuestoFamiliarOrigen != null)
        .toList();
  }

  // Método para procesar la subdivisión de un presupuesto familiar
  Future<void> procesarPresupuestoFamiliar(
    PresupuestoFamiliar presupuestoFamiliar,
    List<Map<String, dynamic>> subdivisiones,
  ) async {
    if (state == null) return;

    // Crear una copia de la familia para realizar las modificaciones
    Familia familiaActualizada = state!.copyWith();
    List<PresupuestoPersonal> nuevosPresupuestosPersonales = [];
    double totalDistribuido = 0;

    for (var sub in subdivisiones) {
      final String categoriaSub =
          sub['categoria']; // Corregido: 'categoria' en notificacion_presupuesto.dart
      final double montoSub = sub['monto'];
      final int perfilIdAsignado =
          state!.id; // El perfil destino es la familia actual
      final int asignacionId =
          presupuestoFamiliar
              .id; // El ID del presupuesto familiar es el asignacion_id

      // Registrar el detalle del presupuesto en el backend
      final response = await _perfilService.agregarPresupuestoPersonal(
        perfilIdAsignado,
        categoriaSub,
        montoSub,
        asignacionId,
      );

      if (response['estado'] == 'ok' && response['detalle_id'] != null) {
        final int detalleId = int.parse(response['detalle_id'].toString());
        final double montoTotal = double.parse(
          response['montoTotal'].toString(),
        );

        final nuevoPresupuesto = PresupuestoPersonal(
          id: detalleId, // Usamos el ID devuelto por el backend
          montoAsignado: montoSub,
          montoTotal: montoTotal, //Para que después se construya
          categoria: categoriaSub,
          perfilId: perfilIdAsignado,
          idPresupuestoFamiliarOrigen:
              presupuestoFamiliar.id, // Referencia al origen
        );
        nuevosPresupuestosPersonales.add(nuevoPresupuesto);
        totalDistribuido += montoSub;
      } else {
        // Manejar el error si el registro del detalle falla
        print(
          'Error al registrar detalle de presupuesto: ${response['mensaje']}',
        );
        // Si falla un detalle, podrías decidir si quieres revertir los anteriores
        // o simplemente continuar y mostrar un mensaje de error parcial.
        // Por ahora, simplemente imprimimos el error y continuamos.
      }
    }

    // Actualizar los presupuestos personales de la familia
    familiaActualizada = familiaActualizada.copyWith(
      cnPresupuestosPersonales: [
        ...familiaActualizada.cnPresupuestosPersonales,
        ...nuevosPresupuestosPersonales,
      ],
    );

    // Actualizar el balance de la familia con el total distribuido
    // Esto asume que el monto distribuido de un presupuesto familiar se suma al balance de la familia.
    // Si el balance ya se maneja en el backend al registrar los detalles, esto podría ser redundante o necesitar ajuste.
    familiaActualizada = familiaActualizada.copyWith(
      balance: familiaActualizada.balance + totalDistribuido,
    );

    // Marcar el presupuesto familiar original como distribuido
    // Asumiendo que no hay una acción específica en PerfilService para "marcar como distribuido"
    // y que la distribución se considera completa una vez que los detalles se registran.
    // Si necesitas una llamada al backend para esto, deberías implementarla en PerfilService.
    final index = familiaActualizada.cnPresupuestosFamiliares.indexWhere(
      (pf) => pf.id == presupuestoFamiliar.id,
    );
    if (index != -1) {
      familiaActualizada.cnPresupuestosFamiliares[index] = PresupuestoFamiliar(
        id: presupuestoFamiliar.id,
        montoAsignado: presupuestoFamiliar.montoAsignado,
        montoTotal: presupuestoFamiliar.montoTotal,
        categoria: presupuestoFamiliar.categoria,
        idPerfilFamiliar: presupuestoFamiliar.idPerfilFamiliar,
        idTitular: presupuestoFamiliar.idTitular,
        distribuido: true, // Marcar como distribuido
      );
      print(
        'Presupuesto familiar ${presupuestoFamiliar.id} marcado como distribuido localmente.',
      );
    }

    state = familiaActualizada; // Actualizar el estado con la nueva familia

    // Después de cualquier operación que cambie el perfil, recarga o actualiza el perfil activo
    // Esto es crucial para que la UI se actualice con los nuevos presupuestos y balance.
    final updatedPerfil = await _perfilService.getPerfilById(
      state!.id,
    ); // Obtener el perfil familiar actualizado
    if (updatedPerfil != null) {
      _updatePerfilInNotifier(updatedPerfil);
      print('Perfil familiar actualizado en el notifier.');
    } else {
      print(
        'Error al recargar el perfil actualizado después de la distribución.',
      );
    }
  }
}
