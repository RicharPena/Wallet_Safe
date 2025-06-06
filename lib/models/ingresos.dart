class Ingreso {
  final int id;
  final double monto;
  final DateTime fecha;
  final String descripcion;
  final String categoria; // Pendiente por cambiar y debatir
  final String tipo;
  final bool automatico;

  Ingreso({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.descripcion,
    required this.categoria,
    required this.tipo,
    required this.automatico,
  });

  /// Simula guardar un ingreso para un perfil específico (puedes usar perfil.id, por ejemplo)
  static void registrarIngreso({
    required int id,
    required double monto,
    required String descripcion,
    required String categoria,
    required String tipo,
    required bool automatico,
  }) {
    final nuevoIngreso = Ingreso(
      id: id,
      monto: monto,
      fecha: DateTime.now(),
      descripcion: descripcion,
      categoria: categoria,
      tipo: tipo,
      automatico: automatico,
    );

    // Aquí irá la lógica para guardar el ingreso (p. ej. en base de datos)
    // Por ahora, imprimimos
    print('✅ Ingreso registrado: ${nuevoIngreso.toMap()}');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'categoria': categoria,
      'tipo': tipo,
      'automatico': automatico,
    };
  }
}
