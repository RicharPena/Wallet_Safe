class Ingreso {
  final int id;
  final double monto;
  final DateTime fecha;
  final String descripcion;
  final String categoria;
  final String tipo;
  final bool automatico;
  final int perfilId; // Añadir el ID del perfil al que pertenece este ingreso

  Ingreso({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.descripcion,
    required this.categoria,
    required this.tipo,
    required this.automatico,
    required this.perfilId, // Ahora el Ingreso sabe a qué perfil pertenece
  });

  /// Factory constructor para crear una instancia de Ingreso desde un mapa JSON.
  /// Ideal para recibir datos de la API.
  factory Ingreso.fromJson(Map<String, dynamic> json) {
    return Ingreso(
      id: int.parse(json['id'].toString()), // Asegúrate de parsear el ID
      monto: double.parse(
        json['monto'].toString(),
      ), // Asegúrate de parsear a double
      fecha: DateTime.parse(
        json['fecha'],
      ), // Parsear la fecha de String a DateTime
      descripcion: json['descripcion'],
      categoria: json['rubro'],
      tipo: json['tipo'],
      automatico: json['automatico'] == 1, // Manejar booleanos
      perfilId: int.parse(json['perfil_id'].toString()),
    );
  }

  /// Método para convertir una instancia de Ingreso a un mapa JSON.
  /// Ideal para enviar datos a la API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monto': monto,
      'fecha': fecha.toIso8601String(), // Formato ISO 8601 para la fecha
      'descripcion': descripcion,
      'categoria': categoria,
      'tipo': tipo,
      'automatico':
          automatico ? 1 : 0, // Convertir bool a int (1 o 0) para la DB
      'perfil_id': perfilId, // Incluir el ID del perfil al que pertenece
    };
  }

  Ingreso copyWith({
    int? id,
    double? monto,
    bool? automatico,
    String? tipo,
    String? rubro,
    DateTime? fecha,
    int? perfilId,
    String? descripcion,
  }) {
    return Ingreso(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      automatico: automatico ?? this.automatico,
      tipo: tipo ?? this.tipo,
      categoria: rubro ?? this.categoria,
      fecha: fecha ?? this.fecha,
      perfilId: perfilId ?? this.perfilId,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}
