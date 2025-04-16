class Perfil {
  final int id;
  final String nombre;
  double presupuestoFamiliar;

  // List<Ingreso> cnIngresos = [];
  // List<Gasto> cnGastos = [];

  Perfil({
    required this.id,
    required this.nombre,
    this.presupuestoFamiliar = 0.0,
    // this.cnIngresos = const [],
    // this.cnGastos = const [],
  });
}
