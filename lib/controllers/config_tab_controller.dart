import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/services/cuenta_service.dart'; // Asumimos que tienes este servicio
import 'package:wallet_safe/services/perfil_service.dart'; // Asumimos que tienes este servicio

// Estado para ConfigTabController: Puede ser loading, data, o error.
class ConfigState {
  final Cuenta? cuenta;
  final bool isLoading;
  final String? errorMessage;

  ConfigState({this.cuenta, this.isLoading = false, this.errorMessage});

  ConfigState copyWith({
    Cuenta? cuenta,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ConfigState(
      cuenta: cuenta ?? this.cuenta,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Permite nulo para limpiar el error
    );
  }
}

class ConfigTabController extends StateNotifier<ConfigState> {
  final CuentaService _cuentaService;
  final PerfilService
  _perfilService; // Para actualizar el perfil activo si es necesario
  final void Function(Cuenta?, Perfil?)
  _clearAndSetProviders; // Callback para limpiar providers

  ConfigTabController({
    required CuentaService cuentaService,
    required PerfilService perfilService,
    required Cuenta? initialAccount, // Cuenta inicial, pasada desde el provider
    required void Function(Cuenta?, Perfil?) clearAndSetProviders,
  }) : _cuentaService = cuentaService,
       _perfilService = perfilService,
       _clearAndSetProviders = clearAndSetProviders,
       super(
         ConfigState(cuenta: initialAccount),
       ); // Inicializa el estado con la cuenta

  // Método para actualizar nombre y correo electrónico
  Future<bool> updateAccountDetails({
    required String newName,
    required String newEmail,
  }) async {
    if (state.cuenta == null) {
      state = state.copyWith(
        errorMessage: 'No hay cuenta activa para actualizar.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    ); // Estado de carga

    try {
      final Cuenta updatedCuenta = state.cuenta!.copyWith(
        name: newName,
        email: newEmail,
      );

      final bool success = await _cuentaService.editarPerfil(updatedCuenta);

      if (success) {
        state = state.copyWith(
          cuenta: updatedCuenta,
          isLoading: false,
        ); // Actualiza estado local
        // Asegúrate de que el provider de cuenta activa también se actualice en app_providers
        _clearAndSetProviders(
          updatedCuenta,
          null,
        ); // Esto es clave para propagar el cambio
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al actualizar nombre o correo.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: $e',
      );
      return false;
    }
  }

  // Método para cambiar la contraseña
  Future<bool> changePassword({required String newPassword}) async {
    if (state.cuenta == null) {
      state = state.copyWith(
        errorMessage: 'No hay cuenta activa para cambiar contraseña.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    ); // Estado de carga

    try {
      final bool success = await _cuentaService.editarPerfil(
        state.cuenta!,
        nuevaContrasena:
            newPassword, // Asumiendo que tu servicio necesita la contraseña actual
      );

      if (success) {
        state = state.copyWith(isLoading: false); // Contraseña cambiada
        // No es necesario actualizar el objeto Cuenta en el estado local, ya que la contraseña
        // no suele ser parte del objeto Cuenta visible para la UI.
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Error al cambiar contraseña. Verifique la contraseña actual.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: $e',
      );
      return false;
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    // 1. Indicar que el proceso de logout ha comenzado.
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 2. Realizar cualquier lógica asíncrona de backend (ej. invalidar token).
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Simular una operación asíncrona

      // 3. Importante: Resetear el estado del propio StateNotifier *antes* de limpiar
      //    los providers globales que podrían causar su propia disposición (autoDispose).
      //    Una vez que el controlador se dispone, no se puede llamar a `state = ...`
      //    Esta línea asegura que el controlador "finalize" su estado antes de potencialmente ser eliminado.
      state = ConfigState(cuenta: null, isLoading: false);

      // 4. Limpiar los providers globales de Riverpod que gestionan la sesión.
      //    Esta acción puede llevar a la disposición de este mismo ConfigTabController
      //    si no hay otros consumidores activos o si es un provider .autoDispose
      //    cuyas dependencias (ej. cuentaActivaProvider) han sido invalidadas.
      _clearAndSetProviders(null, null);

      // Después de esta línea, no deberíamos intentar modificar `state` nuevamente,
      // ya que el controlador podría estar ya en proceso de disposición o dispuesto.
    } catch (e) {
      // Si un error ocurre *antes* de _clearAndSetProviders, podríamos actualizar el estado.
      // Pero si el error ocurre *después* o durante la ejecución de _clearAndSetProviders,
      // es muy probable que el controlador ya esté dispuesto.
      // En un escenario de logout, el objetivo es ir a la pantalla de login.
      // Podemos registrar el error, pero no intentar actualizar el `state` del controller
      // si ya está dispuesto.
      // La navegación a la pantalla de login debería ocurrir de todos modos.
      debugPrint('Error al cerrar sesión en ConfigTabController: $e');
      // No actualizamos 'state' aquí para evitar el Bad State: Tried to use after dispose.
      // Se asume que la UI de ConfigTab navegará de todos modos.
    }
  }
}
