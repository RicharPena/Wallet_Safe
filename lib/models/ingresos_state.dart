import 'package:flutter/material.dart'; // Solo si necesitas TextEditingController aquí

// Clase inmutable que representa el estado completo de IngresosTab
@immutable
class IngresosState {
  final String? categoriaIngresoSeleccionada;
  final bool esAutomatico;
  final String tipoIngreso;
  final String? categoriaPresupuestoPersonalSeleccionada;
  final String? categoriaPresupuestoFamiliarSeleccionada;
  final String? perfilFamiliarSeleccionadoNombre;
  final int? perfilFamiliarSeleccionadoId;

  const IngresosState({
    this.categoriaIngresoSeleccionada,
    this.esAutomatico = false,
    this.tipoIngreso = 'Fijo',
    this.categoriaPresupuestoPersonalSeleccionada,
    this.categoriaPresupuestoFamiliarSeleccionada,
    this.perfilFamiliarSeleccionadoNombre,
    this.perfilFamiliarSeleccionadoId,
  });

  // Método copyWith para crear nuevas instancias del estado con propiedades modificadas
  IngresosState copyWith({
    String? categoriaIngresoSeleccionada,
    bool? esAutomatico,
    String? tipoIngreso,
    String? categoriaPresupuestoPersonalSeleccionada,
    String? categoriaPresupuestoFamiliarSeleccionada,
    String? perfilFamiliarSeleccionadoNombre,
    int? perfilFamiliarSeleccionadoId,
  }) {
    return IngresosState(
      categoriaIngresoSeleccionada:
          categoriaIngresoSeleccionada ?? this.categoriaIngresoSeleccionada,
      esAutomatico: esAutomatico ?? this.esAutomatico,
      tipoIngreso: tipoIngreso ?? this.tipoIngreso,
      categoriaPresupuestoPersonalSeleccionada:
          categoriaPresupuestoPersonalSeleccionada ??
          this.categoriaPresupuestoPersonalSeleccionada,
      categoriaPresupuestoFamiliarSeleccionada:
          categoriaPresupuestoFamiliarSeleccionada ??
          this.categoriaPresupuestoFamiliarSeleccionada,
      perfilFamiliarSeleccionadoNombre:
          perfilFamiliarSeleccionadoNombre ??
          this.perfilFamiliarSeleccionadoNombre,
      perfilFamiliarSeleccionadoId: // <--- ¡ASIGNA AQUÍ!
          perfilFamiliarSeleccionadoId ?? this.perfilFamiliarSeleccionadoId,
    );
  }
}
