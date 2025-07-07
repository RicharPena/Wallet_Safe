import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/controllers/familia_viewmodel.dart';
import 'package:wallet_safe/controllers/gastos_tab_controller.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/models/gastos_state.dart';
import 'package:wallet_safe/models/ingresos_state.dart';
import 'package:wallet_safe/models/cuenta.dart'; // Tu clase Cuenta (ahora inmutable)
import 'package:wallet_safe/models/perfil.dart'; // Clase Perfil (ahora inmutable)
import 'package:wallet_safe/services/perfil_service.dart'; // Servicio de perfil
import '../controllers/ingresos_tab_controller.dart' as IngresosCtrl;
import '../controllers/config_tab_controller.dart';
import 'package:wallet_safe/controllers/register_controller.dart';

// --- Providers principales de Datos (Cuenta y Perfil Seleccionado) ---

/// **StateNotifier para gestionar la Cuenta activa.**
/// Este `Notifier` permite establecer la `Cuenta` una vez que se carga de la base de datos.
/// El estado que maneja es una instancia de `Cuenta?`.
///
/// NOTA: `Cuenta` es ahora una clase inmutable. `CuentaActivaNotifier`
/// emitirá nuevas instancias de `Cuenta` cuando sus datos cambien.
class CuentaActivaNotifier extends StateNotifier<Cuenta?> {
  CuentaActivaNotifier() : super(null);

  /// Método para establecer la cuenta activa.
  /// Cuando la cuenta se establece (ej. después del login), también necesitamos
  /// los metadatos de los perfiles asociados a ella.
  void setCuenta(Cuenta cuenta) {
    state = cuenta;
  }

  /// Método para limpiar la cuenta activa (útil para el logout).
  void clearCuenta() {
    state = null;
  }
}

/// **Provider principal para la Cuenta activa.**
/// Expone el `CuentaActivaNotifier`. Desde UI/Lógica, lo leerás para acceder
/// a la `Cuenta` o para llamar a `setCuenta`/`clearCuenta`.
final cuentaActivaProvider =
    StateNotifierProvider<CuentaActivaNotifier, Cuenta?>((ref) {
      return CuentaActivaNotifier();
    });

/// **Provider para el PerfilService.**
/// Un `Provider` simple para obtener una instancia de `PerfilService`.
final perfilServiceProvider = Provider((ref) => PerfilService());

// **Provider para almacenar el ID del Perfil actualmente seleccionado por el usuario.**
// Este es un simple `StateProvider` que guarda un `int?`.
// Su valor se actualiza desde la UI (ej. en ProfileViews).
final currentSelectedPerfilIdProvider = StateProvider<int?>((ref) {
  return null; // Inicialmente no hay perfil seleccionado por ID
});

/// **StateNotifier para gestionar el Perfil actualmente activo.**
/// Este Notifier ahora manejará la carga y el estado del perfil.
/// Inicialmente, el perfil solo tendrá ID y nombre (obtenidos del login).
/// Cuando el backend implemente `obtenerPerfil`, este Notifier se encargará
/// de cargar los datos completos.
class PerfilActivoNotifier extends StateNotifier<Perfil?> {
  final Ref _ref; // Permite al Notifier acceder a otros providers

  PerfilActivoNotifier(this._ref) : super(null);

  /// Método para establecer el perfil activo por su ID.
  /// Esto se llamaría cuando el usuario selecciona un perfil en la UI.
  Future<void> setPerfilActivo(int perfilId) async {
    final PerfilService perfilService = _ref.read(perfilServiceProvider);

    final Cuenta? currentCuenta = _ref.read(cuentaActivaProvider);
    debugPrint(
      'SET_PERFIL_ACTIVO: cuentaActivaProvider es null? ${currentCuenta == null}',
    );
    if (currentCuenta != null) {
      debugPrint(
        'SET_PERFIL_ACTIVO: Nombre de la cuenta activa: ${currentCuenta.name}',
      );
      debugPrint(
        'SET_PERFIL_ACTIVO: Metadatos de perfiles de la cuenta: ${currentCuenta.perfilesMetadata}',
      );
    }

    // --- CUANDO EL BACKEND IMPLEMENTE obtenerPerfil CON TODOS LOS DATOS: ---
    final Perfil? loadedPerfil = await perfilService.getPerfilById(perfilId);
    if (loadedPerfil != null) {
      state = loadedPerfil; // Establece el perfil completo
      debugPrint(
        'SET_PERFIL_ACTIVO: perfilActivoProvider establecido a: ${loadedPerfil.nombre} (ID: ${loadedPerfil.id})',
      );
    } else {
      debugPrint(
        'SET_PERFIL_ACTIVO: Error: No se pudo cargar el perfil completo para ID: $perfilId',
      );
      state = null;
    }
  }

  /// Actualiza el estado del perfil. Esto se llamaría cuando se
  /// realicen cambios en el perfil (ej. agregar ingreso/gasto)
  /// y el `PerfilService` retorne la nueva instancia actualizada.
  void updatePerfil(Perfil newPerfil) {
    state = newPerfil;
  }

  /// Limpia el perfil activo (ej. al desloguearse).
  void clearPerfilActivo() {
    state = null;
  }
}

/// **Provider principal para el Perfil activo (instancia completa).**
/// Expone el `PerfilActivoNotifier`. Observa este provider para acceder al
/// `Perfil` seleccionado por el usuario.
final perfilActivoProvider =
    StateNotifierProvider<PerfilActivoNotifier, Perfil?>((ref) {
      return PerfilActivoNotifier(ref);
    });

/// NUEVO: Provider para obtener TODOS los perfiles (titular + familiares)
/// asociados a la cuenta activa, para su uso en gráficos y resúmenes.
final allPerfilesForGraphProvider = FutureProvider<List<Perfil>>((ref) async {
  final cuentaActiva = ref.watch(cuentaActivaProvider);
  final perfilService = ref.watch(perfilServiceProvider);

  if (cuentaActiva == null) {
    return []; // No hay cuenta activa, no hay perfiles que mostrar
  }

  final List<Perfil> allPerfiles = [];

  // Obtener el perfil titular si está disponible
  final titularPerfilMetadata = IngresosCtrl.ListExtensions(
    cuentaActiva.perfilesMetadata,
  ).firstWhereOrNull((p) => p['tipo'] == 'Titular');

  if (titularPerfilMetadata != null && titularPerfilMetadata['id'] != null) {
    final titularPerfil = await perfilService.getPerfilById(
      titularPerfilMetadata['id'] as int,
    );
    if (titularPerfil != null) {
      allPerfiles.add(titularPerfil);
    }
  }

  // Obtener los perfiles familiares
  final familiaresMetadata =
      cuentaActiva.perfilesMetadata
          .where((p) => p['tipo'] == 'Familia')
          .toList();

  for (final familiarMetadata in familiaresMetadata) {
    if (familiarMetadata['id'] != null) {
      final familiarPerfil = await perfilService.getPerfilById(
        familiarMetadata['id'] as int,
      );
      if (familiarPerfil != null) {
        allPerfiles.add(familiarPerfil);
      }
    }
  }
  return allPerfiles;
});

// --- Providers para los Controladores ---

// Nuevo: Provider para IngresosTabController
final ingresosTabControllerProvider = StateNotifierProvider.autoDispose<
  IngresosCtrl.IngresosTabController,
  IngresosState // El estado del controlador de ingresos es IngresosState
>((ref) {
  final perfilActivo = ref.watch(
    perfilActivoProvider,
  ); // Observa el perfil activo
  final cuentaActiva = ref.watch(
    cuentaActivaProvider,
  ); // Observa la cuenta activa

  // =================================================================================
  // === ¡CAMBIO CLAVE AQUÍ! Aplicar la lógica de "sublist(1)" dentro del provider ===
  // =================================================================================
  List<Map<String, dynamic>> familiaresMetadata = [];
  if (cuentaActiva != null && cuentaActiva.perfilesMetadata != null) {
    if (cuentaActiva.perfilesMetadata.length > 1) {
      // Excluir el primer elemento (Titular) y tomar el resto como Familiares
      familiaresMetadata = cuentaActiva.perfilesMetadata.sublist(1);
    }
    // Si solo hay un elemento (el titular), familiaresMetadata seguirá siendo una lista vacía, lo cual es correcto.
  }
  // =================================================================================

  // Estas debug prints de la última interacción son muy útiles, déjalas por ahora:
  debugPrint(
    '*** app_providers: ingresosTabControllerProvider instanciado/consultado ***',
  );
  debugPrint(
    '*** app_providers: familiaresMetadataParam recibido por el provider (calculado aquí): $familiaresMetadata',
  );

  return IngresosCtrl.IngresosTabController(
    perfil: perfilActivo, // Pasa el perfil inmutable directamente
    perfilService: ref.read(perfilServiceProvider), // Pasa el servicio
    updatePerfilInNotifier: (updatedPerfil) {
      // Esta callback permite al controlador actualizar el PerfilActivoNotifier
      // después de una operación (ej. registrar ingreso que cambia el balance).
      ref.read(perfilActivoProvider.notifier).updatePerfil(updatedPerfil);
    },
    familiaresMetadata:
        familiaresMetadata, // Ahora esta lista contendrá los familiares correctamente
  );
});

// GastoTabController ahora usa Perfil inmutable y un StateNotifier
final gastosTabControllerProvider = StateNotifierProvider.autoDispose<
  GastosTabController,
  GastosState // El estado del controlador de gastos podría ser un objeto de estado propio, no solo Perfil?
>((ref) {
  final perfilActivo = ref.watch(
    perfilActivoProvider,
  ); // Observa el perfil activo
  final cuentaActiva = ref.watch(
    cuentaActivaProvider,
  ); // <-- ¡LEE LA CUENTA ACTIVA!

  // Obtener los metadatos de los perfiles familiares de la cuenta activa
  final List<Map<String, dynamic>> familiaresMetadata =
      cuentaActiva != null
          ? cuentaActiva.perfilesMetadata
              .where(
                (p) => p['tipo'] == 'Familia',
              ) // Filtrar por tipo 'Familia'
              .toList()
          : [];

  return GastosTabController(
    perfil: perfilActivo, // Pasa el perfil inmutable
    perfilService: ref.read(perfilServiceProvider), // Pasa el servicio
    updatePerfilInNotifier: (updatedPerfil) {
      // Esta callback permite al controlador actualizar el PerfilActivoNotifier
      // después de una operación (ej. registrar gasto que cambia el balance).
      ref.read(perfilActivoProvider.notifier).updatePerfil(updatedPerfil);
    },
    familiaresMetadata: familiaresMetadata, // <-- ¡PASAR LOS METADATOS AQUÍ!
  );
});

final configTabControllerProvider =
    ChangeNotifierProvider.autoDispose<ConfigTabController>((ref) {
      final cuenta = ref.watch(cuentaActivaProvider);
      return ConfigTabController(
        cuentaInicial: cuenta,
        updateCuentaInNotifier: (updatedCuenta) {
          // <-- ¡AÑADIDO AQUÍ!
          ref.read(cuentaActivaProvider.notifier).setCuenta(updatedCuenta);
        },
      );
    });

/// Provider para el RegisterController.
/// Usa `autoDispose` para que los recursos se liberen cuando no se usen.
final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>((ref) {
      final perfilService = ref.read(
        perfilServiceProvider,
      ); // Reutiliza el servicio de perfil
      return RegisterController(perfilService: perfilService);
    });

final familiaViewModelProvider = StateNotifierProvider.autoDispose<
  FamiliaViewModel,
  Familia?
>((ref) {
  final perfilService = ref.read(perfilServiceProvider); // Lee el servicio

  // **** ¡ESTA LÍNEA ES CRUCIAL! ****
  // Observa el perfilActivoProvider. Cada vez que su estado (el Perfil) cambie,
  // Riverpod reconstruirá este StateNotifierProvider.
  final Perfil? currentPerfil = ref.watch(perfilActivoProvider);

  // Crea la instancia de tu ViewModel
  final viewModel = FamiliaViewModel(
    perfilService: perfilService,
    updatePerfilInNotifier: (updatedPerfil) {
      ref.read(perfilActivoProvider.notifier).updatePerfil(updatedPerfil);
    },
  );

  // **** ¡ESTA LÓGICA TAMBIÉN ES CLAVE! ****
  // Carga la familia en el ViewModel. Esto se ejecutará cada vez que
  // currentPerfil (el resultado de ref.watch) cambie.
  if (currentPerfil is Familia) {
    viewModel.cargarFamilia(currentPerfil);
  } else {
    // Si el perfil activo no es una Familia (ej. es un Titular, o nulo),
    // asegura que el estado del FamiliaViewModel sea nulo.
    viewModel.state = null;
  }

  return viewModel; // Retorna la instancia del ViewModel
});
