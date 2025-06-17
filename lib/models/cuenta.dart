class Cuenta {
  final int id;
  final String name;
  final String email;

  // La lista de perfiles que viene del backend ahora es una lista de mapas (metadatos).
  // Es final porque la lista en sí no mutará; si se añaden/eliminan perfiles,
  // se creará una nueva instancia de Cuenta con una nueva lista de metadatos.
  final List<Map<String, dynamic>> perfilesMetadata;

  // Constructor
  Cuenta({
    required this.id, // El ID de la cuenta siempre debe estar presente al crear una instancia.
    required this.name,
    required this.email,
    this.perfilesMetadata =
        const [], // Valor por defecto: lista vacía inmutable
  });

  /// Factory constructor para crear una instancia de Cuenta desde un mapa JSON.
  /// Ideal para recibir datos de la API (ej. respuesta del login).
  factory Cuenta.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> loadedPerfilesMetadata = [];
    if (json['perfiles'] != null && json['perfiles'] is List) {
      // Nos aseguramos de que 'perfiles' sea una lista de mapas
      loadedPerfilesMetadata = List<Map<String, dynamic>>.from(
        json['perfiles'],
      );
    }

    return Cuenta(
      id: int.parse(json['id'].toString()), // Asegurarse de que el ID es un int
      name: json['nombre'],
      email: json['correo'],
      perfilesMetadata: loadedPerfilesMetadata,
    );
  }

  /// Método para convertir una instancia de Cuenta a un mapa JSON.
  /// Útil para enviar datos al backend (ej. para actualizar la cuenta).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'correo': email,
      // No incluimos perfilesMetadata aquí, ya que el backend no suele
      // esperar una lista de perfiles completa al actualizar la cuenta.
      // Si la API lo requiere, se añadiría aquí.
    };
  }

  // --- Métodos Auxiliares para acceder a metadatos de perfiles ---

  /// Getter para obtener los metadatos del perfil titular (asumiendo que el primero es el titular)
  /// O, si tu backend retorna un campo 'tipo' en los metadatos, podrías filtrar por 'tipo'.
  Map<String, dynamic>? get titularMetadata {
    // Si tu backend garantiza que el titular es el primero o tiene un campo 'tipo'
    // if (perfilesMetadata.isNotEmpty && perfilesMetadata.first['tipo'] == 'Titular') {
    //   return perfilesMetadata.first;
    // }
    // Por ahora, asumimos que el primer perfil en la lista es el titular.
    return perfilesMetadata.isNotEmpty ? perfilesMetadata.first : null;
  }

  /// Getter para obtener los metadatos de los perfiles familiares
  /// (asumiendo que son todos menos el titular).
  List<Map<String, dynamic>> get familiaresMetadata {
    // Si tu backend retorna un campo 'tipo' en los metadatos, podrías filtrar por 'tipo'.
    // return perfilesMetadata.where((p) => p['tipo'] == 'Familia').toList();
    // Por ahora, asumimos que son todos excepto el primer elemento.
    return perfilesMetadata.length > 1 ? perfilesMetadata.sublist(1) : [];
  }

  /// Método para obtener los metadatos de un perfil por su ID.
  Map<String, dynamic>? getPerfilMetadataPorId(int perfilId) {
    try {
      return perfilesMetadata.firstWhere((p) => p['id'] == perfilId);
    } catch (e) {
      // No se encontró el perfil con ese ID
      return null;
    }
  }

  Cuenta copyWith({
    int? id,
    String? name,
    String? email,
    List<Map<String, dynamic>>? perfilesMetadata,
  }) {
    return Cuenta(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      perfilesMetadata: perfilesMetadata ?? this.perfilesMetadata,
    );
  }

  // --- Métodos que deben ser eliminados o movidos ---

  // Eliminar: static final List<Cuenta> _cuentas = [];
  // Ya que estamos usando un backend, no hay una simulación local de cuentas.

  // Eliminar: static void registrar(Cuenta cuenta) { _cuentas.add(cuenta); }
  // La lógica de registro es responsabilidad de CuentaService.

  // Eliminar: static Future<Cuenta?> iniciarSesion(...)
  // La lógica de inicio de sesión es responsabilidad de CuentaService.

  // Eliminar: static Future<String> registrarCuentaRemota(...)
  // La lógica de registro es responsabilidad de CuentaService.

  // Eliminar: static Cuenta? obtenerCuenta(String email)
  // La lógica de obtener una cuenta es responsabilidad de CuentaService.

  // Eliminar: Perfil? getPerfilPorId(int perfilId)
  // Esta lógica ahora la manejará PerfilActivoNotifier al cargar el Perfil completo.
  // La Cuenta solo tiene los metadatos (id, nombre).

  // Eliminar: void agregarFamiliar(String nombreFamiliar)
  // Ya que Cuenta es inmutable, no puede mutar _perfiles.
  // Agregar un familiar significaría:
  // 1. Llamar al backend para registrar el familiar.
  // 2. Recibir la nueva lista de perfilesMetadata del backend.
  // 3. Crear una *nueva instancia* de Cuenta con la lista de metadatos actualizada.
  // Esto lo manejará el CuentaActivaNotifier.
}
