class PresupuestoFamiliar {
  final int id; // ID propio del back
  final double montoAsignado; // Ahora final
  final double montoTotal;
  final String categoria;
  final int
  idPerfilFamiliar; // El ID del perfil tipo Familia al que se le asigna
  final int idTitular; // El ID del perfil Titular que asignó este presupuesto
  final bool distribuido; // Ahora final

  PresupuestoFamiliar({
    required this.id,
    required this.montoAsignado,
    required this.montoTotal,
    required this.categoria,
    required this.idPerfilFamiliar,
    required this.idTitular,
    this.distribuido = false,
  });

  /// Factory constructor para crear una instancia de PresupuestoFamiliar desde un mapa JSON.
  factory PresupuestoFamiliar.fromJson(Map<String, dynamic> json) {
    return PresupuestoFamiliar(
      id: int.parse(json['id'].toString()),
      montoAsignado: double.parse(
        json['monto_asignado'].toString(),
      ), // Asumo 'monto_asignado' del backend
      montoTotal: double.parse(json['montoTotal']),
      categoria: json['rubro'],
      idPerfilFamiliar: int.parse(
        json['perfil_asignado_id'].toString(),
      ), // Asumo 'id_perfil_familiar'
      idTitular: int.parse(json['perfil_id'].toString()), // Asumo 'id_titular'
      distribuido: json['dividido'], // Manejar booleanos
    );
  }

  /// Método para convertir una instancia de PresupuestoFamiliar a un mapa JSON.
  /// Útil para enviar datos al backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monto_asignado': montoAsignado,
      'montoTotal': montoTotal,
      'categoria': categoria,
      'id_perfil_familiar': idPerfilFamiliar,
      'id_titular': idTitular,
      'distribuido': distribuido ? 1 : 0, // Convertir bool a int (1 o 0)
    };
  }

  PresupuestoFamiliar copyWith({
    int? id,
    double? montoAsignado,
    double? montoTotal, // Incluir en copyWith
    String? categoria,
    int? idPerfilFamiliar,
    int? idTitular,
    bool? distribuido,
  }) {
    return PresupuestoFamiliar(
      id: id ?? this.id,
      montoAsignado: montoAsignado ?? this.montoAsignado,
      montoTotal: montoTotal ?? this.montoTotal,
      categoria: categoria ?? this.categoria,
      idPerfilFamiliar: idPerfilFamiliar ?? this.idPerfilFamiliar,
      idTitular: idTitular ?? this.idTitular,
      distribuido: distribuido ?? this.distribuido,
    );
  }
}
