import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/services/config_service.dart';

class PerfilService {
  final String baseUrl = ConfigService.baseUrl;

  // --- Métodos para Autenticación y Obtención de Perfiles ---

  /// Registra un nuevo usuario (cuenta).
  Future<Map<String, dynamic>> registrarUsuario(
    String nombre,
    String correo,
    String contrasena,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?accion=registrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'contrasena': contrasena,
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en registrarUsuario: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  /// Inicia sesión y retorna los metadatos de la cuenta y sus perfiles asociados.
  /// La respuesta del backend de `login` debería ser:
  /// `{"estado": "ok", "mensaje": "Login correcto", "id": 1, "nombre": "NombreCuenta", "perfiles": [{"id": 101, "nombre": "PerfilTitular"}, {"id": 102, "nombre": "PerfilFamiliar"}]}`
  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?accion=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
      );
      final decodedResponse = _procesarRespuesta(response);

      if (decodedResponse['estado'] == 'ok') {
        return decodedResponse;
      } else {
        return decodedResponse;
      }
    } catch (e) {
      debugPrint('Error en login: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  /// Obtiene los datos completos de un perfil (Titular o Familiar) por su ID.
  /// Se espera que el backend retorne un JSON que pueda ser mapeado a Perfil, Titular o Familia.
  ///
  /// **Debe coincidir con la implementación de `obtenerPerfilCompleto` en `broker.php` y `CuentaControlador`.**
  Future<Perfil?> getPerfilById(int perfilId) async {
    try {
      final response = await http.post(
        // Ahora es POST
        Uri.parse('$baseUrl?accion=perfilCompleto'), // Acción actualizada
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'perfil_id': perfilId,
        }), // Envía perfil_id en el cuerpo
      );
      final decodedResponse = _procesarRespuesta(response);

      if (decodedResponse['estado'] == 'ok' &&
          decodedResponse['perfil'] != null) {
        // Creamos una copia mutable del mapa 'perfil' para asegurarnos de que se pueda manipular.
        // Aunque ya no añadimos 'tipo_perfil', esto sigue siendo una buena práctica.
        Map<String, dynamic> perfilData = Map<String, dynamic>.from(
          decodedResponse['perfil'],
        );

        // *** ¡ELIMINADO! La lógica para asignar 'tipo_perfil' ya no es necesaria aquí ***
        // Perfil.fromJson ahora leerá 'titular' directamente del JSON.

        // Añadir las listas del nivel superior del JSON al mapa 'perfilData'.
        // Estas claves DEBEN COINCIDIR con las que el backend envía
        // y con las que los constructores fromJson de Titular/Familia esperan.
        perfilData['ingresos'] = decodedResponse['ingresos'] ?? [];
        perfilData['gastos'] = decodedResponse['gastos'] ?? [];
        perfilData['presupuestos'] =
            decodedResponse['presupuestos'] ?? []; // Presupuestos Familiares
        perfilData['detalles_presupuesto'] =
            decodedResponse['detalles_presupuesto'] ??
            []; // Presupuestos Personales

        // Ahora, el 'perfilData' contiene todos los datos necesarios para Perfil.fromJson
        return Perfil.fromJson(perfilData);
      } else {
        debugPrint(
          'Error al obtener perfil por ID: ${decodedResponse['mensaje']}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Excepción al obtener perfil por ID: $e');
      return null;
    }
  }

  /// **NUEVO MÉTODO:** Obtiene una lista de objetos Perfil completos
  /// a partir de una lista de metadatos de perfiles.
  /// Ideal para obtener todos los perfiles de una cuenta para el gráfico.
  Future<List<Perfil>> getAllPerfilesForAccount(
    List<Map<String, dynamic>> perfilesMetadata,
  ) async {
    List<Perfil> allPerfiles = [];
    for (var metadata in perfilesMetadata) {
      try {
        final int perfilId = metadata['id'];
        final Perfil? perfilCompleto = await getPerfilById(
          perfilId,
        ); // Usa el método existente
        if (perfilCompleto != null) {
          allPerfiles.add(perfilCompleto);
        }
      } catch (e) {
        debugPrint(
          'Error al cargar perfil ${metadata['nombre']} (ID: ${metadata['id']}) para el gráfico: $e',
        );
      }
    }
    return allPerfiles;
  }

  /// Crea un nuevo perfil (Titular o Familiar).
  /// Esto probablemente se usa después del login para añadir un nuevo perfil a la cuenta.
  Future<Map<String, dynamic>> crearPerfil(
    String nombre,
    int cuentaId,
    String tipo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?accion=perfil'), // Acción para crear perfil
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'cuenta_id': cuentaId,
          'tipo_perfil': tipo, // Añade el tipo de perfil si es necesario
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en crearPerfil: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  // --- Métodos para Ingresos ---

  /// Registra un nuevo ingreso.
  Future<Map<String, dynamic>> registrarIngreso(
    int perfilId,
    double monto,
    bool automatico,
    String tipo,
    String rubro,
    String descripcion,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?accion=registrarIngreso'), // Acción en broker.php
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'perfil_id': perfilId,
          'monto': monto,
          'automatico': automatico ? 1 : 0, // PHP puede esperar 1 o 0
          'tipo': tipo,
          'rubro': rubro,
          'descripcion': descripcion,
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en registrarIngreso: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  // --- Métodos para Gastos ---

  /// Registra un nuevo gasto.
  Future<Map<String, dynamic>> registrarGasto(
    int perfilId,
    double monto,
    bool automatico,
    String tipo,
    String rubro,
    String descripcion,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?accion=registrarGasto'), // Acción en broker.php
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'perfil_id': perfilId,
          'monto': monto,
          'automatico': automatico ? 1 : 0, // PHP puede esperar 1 o 0
          'tipo': tipo,
          'rubro': rubro,
          'descripcion': descripcion,
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en registrarGasto: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  // --- Métodos para Presupuestos ---

  /// Agrega un presupuesto personal.
  /// Mapea a la acción `registrarDetalle` en `broker.php` y `bdDetallePresupuesto.php`.
  /// `asignacion_id` debería ser null para presupuestos personales.
  Future<Map<String, dynamic>> agregarPresupuestoPersonal(
    int perfilId, // Perfil destino (al que se le asigna)
    String categoria, // Es el mismo rubro
    double montoAsignado, // Es el mismo monto y es lo que SE NOS FUE ASIGNADO
    int? asignacionId, // Es el perfil
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?accion=registrarDetalle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'asignacion_id':
              asignacionId, // Es un presupuesto personal, no viene de asignación
          'perfil_id': perfilId,
          'rubro': categoria,
          'monto': montoAsignado,
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en agregarPresupuestoPersonal: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  /// Asigna un presupuesto familiar desde el titular a un familiar.
  /// Mapea a la acción `registrarAsignacion` en `broker.php` y `bdAsignaciones.php`.
  Future<Map<String, dynamic>> asignarPresupuestoFamiliar(
    int idPerfilTitular,
    int idPerfilFamiliar,
    double monto,
    String categoria,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl?accion=registrarAsignacion',
        ), // <--- Acción en broker.php
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'perfil_id': idPerfilTitular, // El perfil que asigna
          'perfil_asignado_id': idPerfilFamiliar, // El perfil que recibe
          'monto_asignado': monto,
          'rubro': categoria,
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en asignarPresupuestoFamiliar: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  /// Registra un gasto contra un presupuesto personal existente.
  /// **Esta acción `registrarGastoPresupuestoPersonal` debe existir en `broker.php`**
  /// Y debe usar un método de tu clase `BDGastos` o una nueva `BDPresupuestos` que actualice
  /// el monto gastado de un presupuesto específico y el balance del perfil.
  Future<Map<String, dynamic>> registrarGastoPresupuestoPersonal(
    int perfilId,
    int presupuestoPersonalId,
    double montoGasto,
    String descripcion,
    String categoria,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl?accion=registrarGasto',
        ), // **Necesita esta acción en broker.php**
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'perfil_id': perfilId,
          'detalle_id': presupuestoPersonalId,
          'monto': montoGasto,
          'descripcion': descripcion,
          'rubro': categoria,
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en registrarGastoPresupuestoPersonal: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  /// Registra un gasto contra un presupuesto familiar existente.
  /// **Esta acción `registrarGastoPresupuestoFamiliar` debe existir en `broker.php`**
  /// Y debe usar un método de tu clase `BDGastos` o `BDAsignaciones` que actualice
  /// el monto gastado del presupuesto familiar y el balance del familiar.
  /// FALTA CORREGIR ESTE MÉTODO / SIN FUNCIONALIDAD ACTUAL EN LA BD
  Future<Map<String, dynamic>> registrarGastoPresupuestoFamiliar(
    int perfilFamiliarId,
    int presupuestoFamiliarId,
    double montoGasto,
    String descripcion,
    String categoria,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl?accion=registrarGasto',
        ), // **Necesita esta acción en broker.php**
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'perfil_id': perfilFamiliarId,
          'detalle_id': presupuestoFamiliarId,
          'monto': montoGasto,
          'descripcion': descripcion,
          'rubro': categoria,
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en registrarGastoPresupuestoFamiliar: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> eliminarPresupuestoPersonal(
    int perfilId,
    int presupuestoId,
  ) async {
    debugPrint(
      'Llamando a eliminarPresupuestoPersonal en PerfilService. Simulando backend...',
    );
    await Future.delayed(const Duration(milliseconds: 700)); // Simula latencia

    // Aquí deberías tener una llamada HTTP real a tu backend
    // Uri.parse('$baseUrl?accion=eliminarPresupuestoPersonal'),
    // body: jsonEncode({'perfil_id': perfilId, 'presupuesto_id': presupuestoId}),

    // Simulación de respuesta exitosa
    return {
      'estado': 'ok',
      'mensaje':
          'Presupuesto personal con ID $presupuestoId eliminado (simulado).',
    };
  }

  /// Edita un perfil existente.
  Future<Map<String, dynamic>> editarPerfil(
    int id,
    String? nombre,
    String? correo,
    String? contrasena,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?accion=editar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          if (nombre != null) 'nombre': nombre,
          if (correo != null) 'correo': correo,
          if (contrasena != null) 'contrasena': contrasena,
        }),
      );
      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error en editarPerfil: $e');
      return {'estado': 'error', 'mensaje': 'Error de conexión: $e'};
    }
  }

  // --- Método Auxiliar para Procesar Respuestas ---

  Map<String, dynamic> _procesarRespuesta(http.Response response) {
    final body = response.body;
    debugPrint('Respuesta cruda del servidor: ${response.request?.url}\n$body');

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(body);
        // PHP devuelve 'estado' y 'mensaje'.
        // Asegúrate de que el 'estado' sea 'ok' para considerar éxito.
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {
            'estado': 'error',
            'mensaje': 'Formato de respuesta inesperado del servidor.',
            'cuerpo': body,
          };
        }
      } catch (e) {
        debugPrint('Error al decodificar JSON: $e, Body: $body');
        return {
          'estado': 'error',
          'mensaje': 'Error al decodificar respuesta JSON',
          'cuerpo': body,
        };
      }
    } else {
      debugPrint(
        'Error de red: ${response.statusCode} - ${response.reasonPhrase}',
      );
      return {
        'estado': 'error',
        'mensaje':
            'Error de red: ${response.statusCode} - ${response.reasonPhrase}',
        'cuerpo': body,
      };
    }
  }
}
