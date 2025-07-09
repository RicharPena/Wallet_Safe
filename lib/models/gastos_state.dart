import 'package:flutter/foundation.dart'; // Para @immutable
import 'package:wallet_safe/models/presupuesto_personal.dart';
import 'package:wallet_safe/models/presupuesto_familiar.dart';

@immutable
class GastosState {
  final bool esAutomatico;
  final String tipoGasto;
  final String? categoriaGastoSeleccionada;
  final String?
  perfilFamiliarSeleccionadoNombre; // Para el dropdown de familiares si aplica
  final PresupuestoPersonal?
  presupuestoPersonalSeleccionado; // Nuevo: Presupuesto personal seleccionado para gastar
  final PresupuestoFamiliar?
  presupuestoFamiliarSeleccionado; // Nuevo: Presupuesto familiar seleccionado para gastar

  const GastosState({
    this.esAutomatico = false,
    this.tipoGasto = 'Fijo',
    this.categoriaGastoSeleccionada,
    this.perfilFamiliarSeleccionadoNombre,
    this.presupuestoPersonalSeleccionado,
    this.presupuestoFamiliarSeleccionado,
  });

  GastosState copyWith({
    bool? esAutomatico,
    String? tipoGasto,
    String? categoriaGastoSeleccionada,
    String? perfilFamiliarSeleccionadoNombre,
    PresupuestoPersonal? presupuestoPersonalSeleccionado,
    PresupuestoFamiliar? presupuestoFamiliarSeleccionado,
  }) {
    return GastosState(
      esAutomatico: esAutomatico ?? this.esAutomatico,
      tipoGasto: tipoGasto ?? this.tipoGasto,
      categoriaGastoSeleccionada:
          categoriaGastoSeleccionada ?? this.categoriaGastoSeleccionada,
      perfilFamiliarSeleccionadoNombre:
          perfilFamiliarSeleccionadoNombre ??
          this.perfilFamiliarSeleccionadoNombre,
      // Los nuevos campos deben ser tratados como nullable para permitir "deseleccionar"
      presupuestoPersonalSeleccionado:
          presupuestoPersonalSeleccionado, // No usar ??, ya que puede ser null explícitamente
      presupuestoFamiliarSeleccionado:
          presupuestoFamiliarSeleccionado, // No usar ??, ya que puede ser null explícitamente
    );
  }
}
