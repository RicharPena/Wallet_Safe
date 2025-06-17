class PresupuestoPersonal {
  final int id; // ID propio del back
  final double montoAsignado; // Ahora final
  final double montoTotal;
  final String categoria;
  final int perfilId; // El ID del perfil al que se le asigna este presupuesto
  final int? idPresupuestoFamiliarOrigen;

  PresupuestoPersonal({
    required this.id,
    required this.montoAsignado,
    required this.montoTotal,
    required this.categoria,
    required this.perfilId,
    this.idPresupuestoFamiliarOrigen,
  });

  /// Factory constructor para crear una instancia de PresupuestoPersonal desde un mapa JSON.
  factory PresupuestoPersonal.fromJson(Map<String, dynamic> json) {
    return PresupuestoPersonal(
      id: int.parse(json['id'].toString()),
      montoAsignado: double.parse(
        json['monto'].toString(),
      ), // Asumo 'monto_asignado' del backend
      categoria: json['rubro'],
      perfilId: int.parse(
        json['perfil_id'].toString(),
      ), // Asumo 'perfil_id' del backend
      idPresupuestoFamiliarOrigen:
          json['asignacion_id'] != null
              ? int.parse(json['asignacion_id'].toString())
              : null,
      montoTotal: double.parse(json['montoTotal'].toString()),
    );
  }

  /// Método para convertir una instancia de PresupuestoPersonal a un mapa JSON.
  /// Útil para enviar datos al backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monto_asignado': montoAsignado,
      'montoTotal': montoTotal,
      'categoria': categoria,
      'perfil_id': perfilId,
      'id_presupuesto_familiar_origen': idPresupuestoFamiliarOrigen,
    };
  }

  PresupuestoPersonal copyWith({
    int? id,
    double? montoAsignado,
    double? montoTotal, // Incluir en copyWith
    String? categoria,
    int? perfilId,
    int? idPresupuestoFamiliarOrigen,
  }) {
    return PresupuestoPersonal(
      id: id ?? this.id,
      montoAsignado: montoAsignado ?? this.montoAsignado,
      montoTotal: montoTotal ?? this.montoTotal,
      categoria: categoria ?? this.categoria,
      perfilId: perfilId ?? this.perfilId,
      idPresupuestoFamiliarOrigen:
          idPresupuestoFamiliarOrigen ?? this.idPresupuestoFamiliarOrigen,
    );
  }
}
