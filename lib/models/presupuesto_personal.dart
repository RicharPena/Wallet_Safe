class PresupuestoPersonal {
  final int id; // ID propio del back
  double montoAsignado;
  final String categoria;
  final int perfilId; // El ID del perfil al que se le asigna este presupuesto

  PresupuestoPersonal({
    required this.id,
    required this.montoAsignado,
    required this.categoria,
    required this.perfilId,
  });

  // Método para actualizar el monto del presupuesto
  void actualizarMonto(double nuevoMonto) {
    if (nuevoMonto >= 0) {
      montoAsignado = nuevoMonto;
    } else {
      throw ArgumentError('El monto asignado no puede ser negativo.');
    }
  }
}
