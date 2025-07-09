import 'package:flutter/material.dart'; // Mantenemos por TextEditingController.text, pero ya no los usaremos aquí directamente
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/ingresos_state.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/services/perfil_service.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';
import 'package:wallet_safe/models/presupuesto_familiar.dart';

// Elimina los TextEditingController de aquí
class IngresosTabController extends StateNotifier<IngresosState> {
  final PerfilService _perfilService;
  final Perfil? _perfil;
  final Function(Perfil) _updatePerfilInNotifier;
  final List<Map<String, dynamic>> _familiaresMetadata;

  static const List<String> categoriasIngresosPersonales = [
    'Salario',
    'Freelance',
    'Ventas',
    'Inversiones',
    'Alquileres',
    'Regalo',
    'Otros',
  ];

  static const List<String> categoriasPresupuestoPersonal = [
    'Comida',
    'Transporte',
    'Vivienda',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Ropa',
    'Servicios',
    'Ahorro',
    'Deudas',
    'Otros',
  ];

  static const List<String> categoriasPresupuestoFamiliar = [
    'Mercado Familiar',
    'Gastos del Hogar',
    'Educación Hijos',
    'Transporte Familiar',
    'Salud Familiar',
    'Entretenimiento Familiar',
    'Vacaciones',
    'Otros Gastos Familiares',
  ];

  static String? validateMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'El monto es requerido';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return 'Ingrese un monto válido y mayor a cero';
    }
    return null;
  }

  IngresosTabController({
    required PerfilService perfilService,
    required Perfil? perfil,
    required Function(Perfil) updatePerfilInNotifier,
    required List<Map<String, dynamic>> familiaresMetadata,
  }) : _perfilService = perfilService,
       _perfil = perfil,
       _updatePerfilInNotifier = updatePerfilInNotifier,
       _familiaresMetadata = familiaresMetadata,
       super(
         IngresosState(
           categoriaIngresoSeleccionada: categoriasIngresosPersonales.first,
           categoriaPresupuestoPersonalSeleccionada:
               categoriasPresupuestoPersonal.first,
           categoriaPresupuestoFamiliarSeleccionada:
               categoriasPresupuestoFamiliar.first,
           esAutomatico: false,
           tipoIngreso: 'Fijo',
           perfilFamiliarSeleccionadoNombre:
               familiaresMetadata.isNotEmpty
                   ? familiaresMetadata.first['nombre']
                   : null,
         ),
       );

  bool get esAutomatico => state.esAutomatico;
  String get tipoIngreso => state.tipoIngreso;
  String? get categoriaIngresoSeleccionada =>
      state.categoriaIngresoSeleccionada;
  String? get categoriaPresupuestoPersonalSeleccionada =>
      state.categoriaPresupuestoPersonalSeleccionada;
  String? get categoriaPresupuestoFamiliarSeleccionada =>
      state.categoriaPresupuestoFamiliarSeleccionada;
  String? get perfilFamiliarSeleccionadoNombre =>
      state.perfilFamiliarSeleccionadoNombre;

  List<String> get nombresPerfilesFamiliares {
    return _familiaresMetadata.map((meta) => meta['nombre'] as String).toList();
  }

  // --- Métodos de actualización de estado (se mantienen igual, o adaptamos si pasan valores) ---
  void setCategoriaIngresoSeleccionada(String? categoria) {
    state = state.copyWith(
      categoriaIngresoSeleccionada:
          categoria ?? state.categoriaIngresoSeleccionada,
    );
  }

  void setCategoriaPresupuestoPersonalSeleccionada(String? categoria) {
    state = state.copyWith(
      categoriaPresupuestoPersonalSeleccionada:
          categoria ?? state.categoriaPresupuestoPersonalSeleccionada,
    );
  }

  void setCategoriaPresupuestoFamiliarSeleccionada(String? categoria) {
    state = state.copyWith(
      categoriaPresupuestoFamiliarSeleccionada:
          categoria ?? state.categoriaPresupuestoFamiliarSeleccionada,
    );
  }

  void setEsAutomatico(bool esAutomatico) {
    state = state.copyWith(esAutomatico: esAutomatico);
  }

  void setTipoIngreso(String tipoIngreso) {
    state = state.copyWith(tipoIngreso: tipoIngreso);
  }

  void setPerfilFamiliarSeleccionadoNombre(String? nombre) {
    final selectedProfile = _familiaresMetadata.firstWhereOrNull(
      (meta) => meta['nombre'] == nombre,
    );
    state = state.copyWith(
      perfilFamiliarSeleccionadoNombre: nombre,
      perfilFamiliarSeleccionadoId:
          selectedProfile != null ? (selectedProfile['id'] as int?) : null,
    );
    debugPrint(
      'Perfil familiar seleccionado: $nombre (ID: ${state.perfilFamiliarSeleccionadoId})',
    );
  }

  // --- Métodos para registrar ingresos/presupuestos (ahora reciben los valores directamente) ---

  // Nuevo método para registrar Ingreso Personal (recibe monto y descripción)
  Future<void> registrarIngresoPersonal(
    double monto,
    String descripcion,
    String categoria,
    String tipoIngreso,
    bool esAutomatico,
  ) async {
    if (_perfil == null) {
      throw Exception(
        'No hay un perfil seleccionado para registrar el ingreso.',
      );
    }
    final int perfilId = _perfil!.id;
    debugPrint(
      'Registrando ingreso personal: $monto, $descripcion, $categoria, $tipoIngreso, $esAutomatico, para Perfil ID: $perfilId',
    );

    try {
      final response = await _perfilService.registrarIngreso(
        perfilId,
        monto,
        esAutomatico,
        tipoIngreso,
        categoria,
        descripcion,
      );

      if (response['estado'] == 'ok') {
        // Después de registrar el ingreso, recarga el perfil para reflejar los cambios
        final Perfil? updatedPerfil = await _perfilService.getPerfilById(
          perfilId,
        ); // Asumiendo este método existe
        if (updatedPerfil != null) {
          _updatePerfilInNotifier(
            updatedPerfil,
          ); // Actualiza el PerfilActivoNotifier
        } else {
          debugPrint(
            'Advertencia: Ingreso registrado, pero no se pudo recargar el perfil.',
          );
        }
        debugPrint('Ingreso personal registrado con éxito.');
      } else {
        throw Exception(
          'Error al registrar ingreso personal: ${response['mensaje']}',
        );
      }
    } catch (e) {
      debugPrint('Excepción al registrar ingreso personal: $e');
      rethrow;
    }
  }

  // Modifica los demás métodos de registro para recibir valores en lugar de usar controladores:

  Future<void> asignarPresupuestoPersonal(
    int perfilId,
    String categoria,
    double monto,
    int? asignacionId,
  ) async {
    if (_perfil == null) {
      throw Exception(
        'No hay un perfil de Titular seleccionado para asignar presupuesto personal.',
      );
    }
    final int perfilId = _perfil.id;
    debugPrint(
      'Asignando presupuesto personal: $monto, $categoria para Perfil ID: $perfilId',
    );

    try {
      final response = await _perfilService.agregarPresupuestoPersonal(
        perfilId,
        categoria,
        monto,
        asignacionId,
      );

      if (response['estado'] == 'ok') {
        final Perfil? updatedPerfil = await _perfilService.getPerfilById(
          perfilId,
        );
        if (updatedPerfil != null) {
          _updatePerfilInNotifier(updatedPerfil);
        } else {
          debugPrint(
            'Advertencia: Presupuesto personal asignado, pero no se pudo recargar el perfil.',
          );
        }
        debugPrint('Presupuesto personal asignado con éxito.');
      } else {
        throw Exception(
          'Error al asignar presupuesto personal: ${response['mensaje']}',
        );
      }
    } catch (e) {
      debugPrint('Excepción al asignar presupuesto personal: $e');
      rethrow;
    }
  }

  Future<void> asignarPresupuestoFamiliar(
    double monto,
    String categoria,
    int? perfilFamiliarId,
  ) async {
    if (_perfil == null || _perfil is! Titular) {
      throw Exception(
        'No hay un perfil de Titular para asignar presupuesto familiar.',
      );
    }
    if (perfilFamiliarId == null) {
      throw Exception('No se ha seleccionado un perfil familiar.');
    }

    final int titularId = _perfil!.id; // El ID del titular que asigna

    debugPrint(
      'Asignando presupuesto familiar: $monto, $categoria a perfil familiar ID: $perfilFamiliarId desde Titular ID: $titularId',
    );

    try {
      final response = await _perfilService.asignarPresupuestoFamiliar(
        titularId,
        perfilFamiliarId,
        monto,
        categoria,
      );

      if (response['estado'] == 'ok') {
        // ¡Importante! Recargar la Cuenta Activa, no solo el perfil.
        // Porque el presupuesto familiar está asociado a la cuenta, no directamente al perfil del titular.
        // Asumimos que tienes un mecanismo para recargar la cuenta activa.
        // Esto depende de cómo manejas la 'Cuenta' completa con sus 'perfilesMetadata'.
        // Podrías necesitar un callback similar a _updatePerfilInNotifier pero para la cuenta.
        // Por ahora, solo actualizaremos el perfil del titular si es un titular,
        // pero la distribución global del presupuesto familiar podría necesitar una recarga de la Cuenta.

        // Por ahora, solo recargamos el perfil del titular.
        final Perfil? updatedPerfil = await _perfilService.getPerfilById(
          titularId,
        );
        if (updatedPerfil != null) {
          _updatePerfilInNotifier(updatedPerfil);
        } else {
          debugPrint(
            'Advertencia: Presupuesto familiar asignado, pero no se pudo recargar el perfil del titular.',
          );
        }

        debugPrint('Presupuesto familiar asignado con éxito.');
      } else {
        throw Exception(
          'Error al asignar presupuesto familiar: ${response['mensaje']}',
        );
      }
    } catch (e) {
      debugPrint('Excepción al asignar presupuesto familiar: $e');
      rethrow;
    }
  }

  // ELIMINA EL MÉTODO dispose() de aquí.
  // Los TextEditingController ya no estarán aquí para ser dispuestos.
  /*
  @override
  void dispose() {
    montoController.dispose();
    descripcionController.dispose();
    montoPresupuestoPersonalController.dispose();
    montoPresupuestoFamiliarController.dispose();
    super.dispose();
  }
  */

  // El método reset() ahora solo limpia los estados del StateNotifier, no los controladores.
  void reset() {
    state = IngresosState(
      categoriaIngresoSeleccionada: categoriasIngresosPersonales.first,
      categoriaPresupuestoPersonalSeleccionada:
          categoriasPresupuestoPersonal.first,
      categoriaPresupuestoFamiliarSeleccionada:
          categoriasPresupuestoFamiliar.first,
      esAutomatico: false,
      tipoIngreso: 'Fijo',
      perfilFamiliarSeleccionadoNombre:
          _familiaresMetadata.isNotEmpty
              ? _familiaresMetadata.first['nombre']
              : null,
    );
  }
}

// Extensión para List para `firstWhereOrNull` (la mantienes)
extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
