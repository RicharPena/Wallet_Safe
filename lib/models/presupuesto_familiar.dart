class PresupuestoFamiliar {
  final int id; // ID propio del back
  double montoAsignado;
  final String categoria;
  final int
  idPerfilFamiliar; // El ID del perfil tipo Familia al que se le asigna
  final int idTitular; // El ID del perfil Titular que asignó este presupuesto

  PresupuestoFamiliar({
    required this.id,
    required this.montoAsignado,
    required this.categoria,
    required this.idPerfilFamiliar,
    required this.idTitular,
  });

  // Método para actualizar el monto del presupuesto familiar
  void actualizarMonto(double nuevoMonto) {
    if (nuevoMonto >= 0) {
      montoAsignado = nuevoMonto;
    } else {
      throw ArgumentError('El monto asignado no puede ser negativo.');
    }
  }
}
