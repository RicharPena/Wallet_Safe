import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/controllers/gastos_tab_controller.dart';
import '../models/cuenta.dart';
import '../models/perfil.dart';
import '../controllers/ingresos_tab_controller.dart';
import '../controllers/config_tab_controller.dart';

// --- StateNotifiers para la Cuenta y el Perfil ---

// StateNotifier para gestionar la Cuenta activa
class CuentaActivaNotifier extends StateNotifier<Cuenta?> {
  // El estado inicial es null, indicando que no hay cuenta logueada
  CuentaActivaNotifier() : super(null);

  // Método para establecer la cuenta activa
  void setCuenta(Cuenta cuenta) {
    state = cuenta;
  }

  // Método para limpiar la cuenta activa (útil para el logout)
  void clearCuenta() {
    state = null;
  }
}

// Provider que expone el StateNotifier de la Cuenta activa
final cuentaActivaProvider =
    StateNotifierProvider<CuentaActivaNotifier, Cuenta?>((ref) {
      return CuentaActivaNotifier();
    });

// StateNotifier para gestionar el Perfil seleccionado
class PerfilSeleccionadoNotifier extends StateNotifier<Perfil?> {
  // El estado inicial es null, indicando que no hay perfil seleccionado
  PerfilSeleccionadoNotifier() : super(null);

  // Método para establecer el perfil seleccionado
  void setPerfil(Perfil? perfil) {
    state = perfil;
  }

  // Método para limpiar el perfil seleccionado (útil para el logout o cambio de cuenta)
  void clearPerfil() {
    state = null;
  }
}

// Provider que expone el StateNotifier del Perfil seleccionado
final perfilSeleccionadoProvider =
    StateNotifierProvider<PerfilSeleccionadoNotifier, Perfil?>((ref) {
      return PerfilSeleccionadoNotifier();
    });

// --- Providers para los Controladores (mantienen su lógica) ---

// Nuevo: Provider para IngresosTabController
// Este provider depende de cuentaActivaProvider y perfilSeleccionadoProvider
final ingresosTabControllerProvider = StateNotifierProvider.autoDispose<
  IngresosTabController,
  bool
>((ref) {
  // Observa los providers de Cuenta y Perfil.
  // Cuando estos cambien, el ingresosTabControllerProvider se invalidará y recreará.
  final cuenta = ref.watch(cuentaActivaProvider);
  final perfil = ref.watch(perfilSeleccionadoProvider);

  // Es crucial manejar el caso donde cuenta o perfil son null si los controladores
  // no están diseñados para manejarlos. Idealmente, tus controladores
  // deberían poder iniciar con valores null o manejarlos internamente.
  // Si no, podrías lanzar un error o devolver un controlador "vacío" temporalmente.
  // Por ahora, asumimos que no serán null cuando se usen en los tabs principales.

  if (cuenta == null || perfil == null) {
    // Aquí puedes retornar un IngresosTabController que sepa manejar la ausencia de cuenta/perfil.
    // Una opción es pasar null a su constructor y que el controlador maneje eso.
    // Asumiendo que IngresosTabController tiene un constructor que acepta nulls para cuenta y perfil.
    return IngresosTabController(
      cuenta: null,
      perfil: null,
    ); // o new IngresosTabController.empty() si tienes uno
  }

  // Se pasa la cuenta y el perfil al constructor del controlador
  return IngresosTabController(cuenta: cuenta, perfil: perfil);
});

final gastosTabControllerProvider = ChangeNotifierProvider.autoDispose<
  GastosTabController
>((ref) {
  // Observa los providers de Cuenta y Perfil, similar a IngresosTabController
  final cuenta = ref.watch(cuentaActivaProvider);
  final perfil = ref.watch(perfilSeleccionadoProvider);

  if (cuenta == null || perfil == null) {
    return GastosTabController(cuenta: null, perfil: null);
  }

  return GastosTabController(cuenta: cuenta, perfil: perfil);
});

final configTabControllerProvider = ChangeNotifierProvider.autoDispose<
  ConfigTabController
>((ref) {
  // Observa la cuenta activa. Cuando la cuenta cambie, este controlador se recreará.
  final cuenta = ref.watch(cuentaActivaProvider);

  if (cuenta == null) {
    return ConfigTabController(cuentaInicial: null);
  }
  return ConfigTabController(cuentaInicial: cuenta);
});
