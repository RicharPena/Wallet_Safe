class Gasto {
  final int id;
  final double monto;
  final DateTime fecha;
  final String descripcion;
  final String categoria;
  final String tipo;
  final bool automatico;
  final int perfilId; // Mantenemos el perfilId
  final int? detalleId;

  Gasto({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.descripcion,
    required this.categoria,
    required this.tipo,
    required this.automatico,
    required this.perfilId,
    this.detalleId,
  });

  /// Factory constructor para crear una instancia de Gasto desde un mapa JSON.
  /// Ideal para recibir datos de la API.
  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: int.parse(json['id'].toString()),
      monto: double.parse(json['monto'].toString()),
      fecha: DateTime.parse(json['fecha']),
      descripcion: json['descripcion'],
      categoria: json['rubro'],
      tipo: (json['tipo'] as String?) ?? '',
      automatico: json['automatico'] == null ? false : json['automatico'] == 1,
      perfilId: int.parse(json['perfil_id'].toString()),
      detalleId:
          json['detalle_id'] != null
              ? int.parse(json['detalle_id'].toString())
              : null,
    );
  }

  /// Método para convertir una instancia de Gasto a un mapa JSON.
  /// Ideal para enviar datos a la API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'categoria': categoria,
      'tipo': tipo,
      'automatico':
          automatico ? 1 : 0, // Convertir bool a int (1 o 0) para la DB
      'perfil_id': perfilId,
      'detalle_id': detalleId,
    };
  }

  Gasto copyWith({
    int? id,
    double? monto,
    bool? automatico,
    String? tipo,
    String? rubro,
    DateTime? fecha,
    int? perfilId,
    String? descripcion,
    int? detalleId,
  }) {
    return Gasto(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      automatico: automatico ?? this.automatico,
      tipo: tipo ?? this.tipo,
      categoria: rubro ?? this.categoria,
      fecha: fecha ?? this.fecha,
      perfilId: perfilId ?? this.perfilId,
      descripcion: descripcion ?? this.descripcion,
      detalleId: detalleId ?? this.detalleId,
    );
  }
}
