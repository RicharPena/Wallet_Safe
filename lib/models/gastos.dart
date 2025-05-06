class Gasto {
  final int id;
  final double monto;
  final DateTime fecha;
  final String descripcion;
  final String tipo;
  final bool automatico;

  Gasto({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.descripcion,
    required this.tipo,
    required this.automatico,
  });

  static void registrarGasto({
    required int id,
    required double monto,
    required String descripcion,
    required String categoria,
    required String tipo,
    required bool automatico,
  }) {
    final nuevoGasto = Gasto(
      id: id,
      monto: monto,
      fecha: DateTime.now(),
      descripcion: descripcion,
      tipo: tipo,
      automatico: automatico,
    );

    print('🛑 Gasto registrado: ${nuevoGasto.toMap()}');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'tipo': tipo,
      'automatico': automatico,
    };
  }
}
