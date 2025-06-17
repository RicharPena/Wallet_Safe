import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/gastos_state.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/services/perfil_service.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';
import 'package:wallet_safe/models/presupuesto_familiar.dart';

// Extensión para List para `firstWhereOrNull`
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

class GastosTabController extends StateNotifier<GastosState> {
  final PerfilService _perfilService;
  final Perfil? _perfil;
  final Function(Perfil) _updatePerfilInNotifier;
  final List<Map<String, dynamic>> _familiaresMetadata;

  // NO MÁS TextEditingControllers AQUÍ. Serán gestionados por el widget de la UI.

  // Listas de categorías (estáticas)
  static final List<String> categoriasGastosPersonales = [
    'Transporte',
    'Entretenimiento',
    'Servicios',
    'Salud',
    'Educación',
    'Ropa',
    'Vivienda',
    'Otros Gastos',
  ];
  static final List<String> categoriasGastosFamiliares = [
    'Comida Familiar',
    'Educación Hijos',
    'Salud Familiar',
    'Transporte Familiar',
    'Actividades Recreativas',
    'Regalos Familiares',
    'Mantenimiento del Hogar',
    'Otros Gastos Familiares',
  ];

  GastosTabController({
    required PerfilService perfilService,
    required Perfil? perfil,
    required Function(Perfil) updatePerfilInNotifier,
    required List<Map<String, dynamic>> familiaresMetadata,
  }) : _perfilService = perfilService,
       _perfil = perfil,
       _updatePerfilInNotifier = updatePerfilInNotifier,
       _familiaresMetadata = familiaresMetadata,
       super(
         GastosState(
           categoriaGastoSeleccionada:
               categoriasGastosPersonales
                   .first, // Inicializar con la primera categoría
           esAutomatico: false,
           tipoGasto: 'Fijo',
           perfilFamiliarSeleccionadoNombre: null,
           presupuestoPersonalSeleccionado: null,
           presupuestoFamiliarSeleccionado: null,
         ),
       ) {
    if (_familiaresMetadata.isNotEmpty && _perfil is Titular) {
      state = state.copyWith(
        perfilFamiliarSeleccionadoNombre: _familiaresMetadata.first['nombre'],
      );
    }
  }

  // Getters para acceder al estado
  bool get esAutomatico => state.esAutomatico;
  String get tipoGasto => state.tipoGasto;
  String? get categoriaGastoSeleccionada => state.categoriaGastoSeleccionada;
  String? get perfilFamiliarSeleccionadoNombre =>
      state.perfilFamiliarSeleccionadoNombre;
  PresupuestoPersonal? get presupuestoPersonalSeleccionado =>
      state.presupuestoPersonalSeleccionado;
  PresupuestoFamiliar? get presupuestoFamiliarSeleccionado =>
      state.presupuestoFamiliarSeleccionado;

  // Getter para obtener los nombres de los perfiles familiares para la UI
  List<String> get nombresPerfilesFamiliares {
    return _familiaresMetadata.map((f) => f['nombre'] as String).toList();
  }

  // Setters para actualizar el estado inmutable
  void setEsAutomatico(bool value) {
    state = state.copyWith(esAutomatico: value);
  }

  void setTipoGasto(String value) {
    state = state.copyWith(tipoGasto: value);
  }

  void setCategoriaSeleccionada(String? value) {
    state = state.copyWith(categoriaGastoSeleccionada: value);
  }

  void setPerfilFamiliarSeleccionadoNombre(String? value) {
    state = state.copyWith(perfilFamiliarSeleccionadoNombre: value);
  }

  void setPresupuestoPersonalSeleccionado(PresupuestoPersonal? presupuesto) {
    state = state.copyWith(presupuestoPersonalSeleccionado: presupuesto);
    // Ya no es necesario limpiar el monto de gasto aquí, lo hará el widget.
  }

  void setPresupuestoFamiliarSeleccionado(PresupuestoPersonal? presupuesto) {
    state = state.copyWith(presupuestoPersonalSeleccionado: presupuesto);
  }

  // Validadores para los campos de texto
  // NOTA: Estos validadores son genéricos y no dependen de un controlador específico.
  // Pueden permanecer aquí o moverse al widget si se prefiere una validación más local.
  String? validateMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'El monto es requerido';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return 'Ingrese un monto válido y mayor a cero';
    }
    return null;
  }

  String? validateDescripcion(String? value) {
    if (value == null || value.isEmpty) {
      return 'La descripción es requerida';
    }
    return null;
  }

  // --- Lógica de Negocio con PerfilService y actualización del estado ---

  Future<void> guardarGastoPersonal(double monto, String descripcion) async {
    final perfil = _perfil;
    if (perfil == null) {
      throw Exception(
        'Error: Perfil no disponible o sin ID para guardar gasto personal.',
      );
    }
    if (state.categoriaGastoSeleccionada == null) {
      throw Exception(
        'Error: Campos de gasto personal incompletos. Por favor, llene todos los campos.',
      );
    }

    final categoria = state.categoriaGastoSeleccionada!;
    final tipo = state.esAutomatico ? state.tipoGasto : 'Único';
    final automatico = state.esAutomatico;

    if (monto > perfil.balance) {
      throw Exception(
        'El monto del gasto excede el saldo disponible de tu perfil.',
      );
    }

    try {
      final response = await _perfilService.registrarGasto(
        perfil.id,
        monto,
        automatico,
        tipo,
        categoria,
        descripcion,
      );

      if (response['estado'] == 'ok') {
        debugPrint(
          'Gasto personal registrado con éxito: ${response['mensaje']}',
        );
        final updatedPerfil = await _perfilService.getPerfilById(perfil.id);
        if (updatedPerfil != null) {
          _updatePerfilInNotifier(updatedPerfil);
        } else {
          final newBalance = perfil.balance - monto;
          _updatePerfilInNotifier(perfil.copyWith(balance: newBalance));
        }
        // No resetear controladores de texto aquí.
      } else {
        throw Exception(
          'Error al registrar gasto personal: ${response['mensaje']}',
        );
      }
    } catch (e) {
      debugPrint('Excepción al guardar gasto personal: $e');
      rethrow;
    }
  }

  Future<void> gastarDePresupuestoPersonal(
    PresupuestoPersonal presupuestoExistente,
    double montoGasto,
    String descripcion,
  ) async {
    final perfil = _perfil;
    if (perfil == null) {
      throw Exception(
        'Error: Perfil no disponible o sin ID para gastar de presupuesto personal.',
      );
    }

    final titular = perfil;
    final presupuesto = titular.cnPresupuestosPersonales.firstWhereOrNull(
      (p) => p.id == presupuestoExistente.id,
    );

    if (presupuesto == null) {
      throw Exception(
        'Presupuesto "${presupuestoExistente.categoria}" no encontrado en el perfil.',
      );
    }

    // Validar que el monto a gastar no exceda el balance restante del presupuesto
    if (montoGasto > (presupuesto.montoTotal)) {
      throw Exception(
        'El monto del gasto excede el saldo disponible en este presupuesto.',
      );
    }

    try {
      final response = await _perfilService.registrarGastoPresupuestoPersonal(
        perfil.id,
        presupuesto.id,
        montoGasto,
        descripcion,
        presupuesto.categoria,
      );

      if (response['estado'] == 'ok') {
        debugPrint(
          'Gasto de presupuesto personal registrado con éxito: ${response['mensaje']}',
        );
        final updatedPerfil = await _perfilService.getPerfilById(perfil.id);
        if (updatedPerfil != null) {
          _updatePerfilInNotifier(updatedPerfil);
        } else {
          // Actualización optimista si no se puede recargar el perfil completo
          final updatedPresupuesto = presupuesto.copyWith(
            montoTotal:
                presupuesto.montoAsignado -
                montoGasto, //+ presupuesto.montoGastado // Acumular el gasto
          );
          final updatedPresupuestos =
              titular.cnPresupuestosPersonales
                  .map(
                    (p) =>
                        p.id == updatedPresupuesto.id ? updatedPresupuesto : p,
                  )
                  .toList();
          _updatePerfilInNotifier(
            titular.copyWith(cnPresupuestosPersonales: updatedPresupuestos),
          );
        }
        // No resetear controladores de texto aquí.
      } else {
        throw Exception(
          'Error al registrar gasto de presupuesto personal: ${response['mensaje']}',
        );
      }
    } catch (e) {
      debugPrint('Excepción al gastar de presupuesto personal: $e');
      rethrow;
    }
  }

  Future<void> gastarDePresupuestoFamiliar(
    PresupuestoPersonal presupuestoGasto,
    double montoGasto,
    String descripcion,
  ) async {
    final perfil = _perfil;
    if (perfil == null) {
      throw Exception(
        'Error: Perfil no disponible o sin ID para gastar de presupuesto familiar.',
      );
    }
    if (perfil is! Familia) {
      throw Exception(
        'Solo los perfiles de Familia pueden gastar de presupuestos familiares asignados.',
      );
    }

    final familia = perfil;

    // Aquí, en lugar de buscar en cnPresupuestosFamiliares, deberías buscar en cnPresupuestosPersonales
    // y usar el PresupuestoPersonal que te llegó como argumento.
    // El idPresupuestoFamiliarOrigen del presupuestoGasto es el que te conecta con el PresupuestoFamiliar original si lo necesitas para el backend.
    final presupuesto = familia.cnPresupuestosPersonales.firstWhereOrNull(
      (p) => p.id == presupuestoGasto.id,
    );

    if (presupuesto == null) {
      throw Exception(
        'Presupuesto familiar asignado "${presupuestoGasto.categoria}" no encontrado en la lista personal de la familia.',
      );
    }

    // Validar que el monto a gastar no exceda el balance restante del presupuesto
    // Ahora usas el montoTotal (disponible) del PresupuestoPersonal
    if (montoGasto > (presupuesto.montoTotal)) {
      throw Exception(
        'El monto del gasto excede el saldo disponible en este presupuesto familiar asignado.',
      );
    }

    try {
      // Cuando llamas al servicio, necesitas pasar el ID del PresupuestoFamiliar original,
      // que está en presupuesto.idPresupuestoFamiliarOrigen
      final response = await _perfilService.registrarGastoPresupuestoFamiliar(
        perfil.id,
        presupuesto.id, // Usar el ID de origen familiar
        montoGasto,
        descripcion,
        presupuesto.categoria,
      );

      if (response['estado'] == 'ok') {
        debugPrint(
          'Gasto de presupuesto familiar registrado con éxito: ${response['mensaje']}',
        );
        final updatedPerfil = await _perfilService.getPerfilById(perfil.id);
        if (updatedPerfil != null) {
          _updatePerfilInNotifier(updatedPerfil);
        } else {
          // Actualización optimista: Actualiza el montoTotal del PresupuestoPersonal
          final updatedPresupuesto = presupuesto.copyWith(
            montoTotal:
                presupuesto.montoAsignado -
                montoGasto, // Restar del monto total disponible
          );
          final updatedPresupuestos =
              familia.cnPresupuestosPersonales
                  .map(
                    (p) =>
                        p.id == updatedPresupuesto.id ? updatedPresupuesto : p,
                  )
                  .toList();
          _updatePerfilInNotifier(
            familia.copyWith(cnPresupuestosPersonales: updatedPresupuestos),
          );
        }
      } else {
        throw Exception(
          'Error al registrar gasto de presupuesto familiar: ${response['mensaje']}',
        );
      }
    } catch (e) {
      debugPrint('Excepción al gastar de presupuesto familiar: $e');
      rethrow;
    }
  }

  // Anteriormente 'asignarGastoFamiliar', ahora más preciso como 'asignarPresupuestoFamiliar'
  Future<void> asignarPresupuestoFamiliar(double monto) async {
    final perfil = _perfil;
    if (perfil == null) {
      throw Exception(
        'Error: Perfil Titular no disponible o sin ID para asignar presupuesto familiar.',
      );
    }

    if (perfil is! Titular) {
      throw Exception(
        'Solo el perfil Titular puede asignar presupuesto familiar.',
      );
    }

    final titular = perfil;

    if (state.categoriaGastoSeleccionada == null ||
        state.perfilFamiliarSeleccionadoNombre == null ||
        state.perfilFamiliarSeleccionadoNombre!.isEmpty) {
      throw Exception(
        'Error: Campos de asignación de presupuesto familiar incompletos o familiar no seleccionado.',
      );
    }

    final categoria = state.categoriaGastoSeleccionada!;

    final perfilFamiliarMetadata = _familiaresMetadata.firstWhereOrNull(
      (p) => p['nombre'] == state.perfilFamiliarSeleccionadoNombre,
    );

    if (perfilFamiliarMetadata == null ||
        perfilFamiliarMetadata['id'] == null) {
      throw Exception(
        'Perfil familiar no encontrado por nombre o no tiene ID.',
      );
    }
    final int idPerfilFamiliar = int.parse(
      perfilFamiliarMetadata['id'].toString(),
    );

    if (monto > titular.balance) {
      throw Exception(
        'El monto a asignar al presupuesto familiar excede el saldo disponible de tu perfil como Titular.',
      );
    }

    try {
      final response = await _perfilService.asignarPresupuestoFamiliar(
        titular.id,
        idPerfilFamiliar,
        monto,
        categoria,
      );

      if (response['estado'] == 'ok') {
        debugPrint(
          'Presupuesto familiar asignado con éxito: ${response['mensaje']}',
        );
        final updatedPerfilTitular = await _perfilService.getPerfilById(
          titular.id,
        );
        if (updatedPerfilTitular != null) {
          _updatePerfilInNotifier(updatedPerfilTitular);
        } else {
          final newBalanceTitular = titular.balance - monto;
          _updatePerfilInNotifier(titular.copyWith(balance: newBalanceTitular));
        }
        // No resetear controladores de texto aquí.
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

  void reset() {
    // Solo restablecer el estado interno del StateNotifier.
    state = GastosState(
      esAutomatico: false,
      tipoGasto: 'Fijo',
      categoriaGastoSeleccionada: categoriasGastosPersonales.first,
      perfilFamiliarSeleccionadoNombre:
          _familiaresMetadata.isNotEmpty && _perfil is Titular
              ? _familiaresMetadata.first['nombre']
              : null,
      presupuestoPersonalSeleccionado: null,
      presupuestoFamiliarSeleccionado: null,
    );
  }

  @override
  void dispose() {
    // Ya no es necesario liberar controladores aquí.
    super.dispose();
  }
}
