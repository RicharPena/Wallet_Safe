import 'package:flutter/material.dart'; // Mantenemos por debugPrint, pero no por TextEditingController
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/services/cuenta_service.dart';
import 'package:wallet_safe/models/perfil.dart'; // Asegúrate de importar Perfil

class ConfigTabController extends ChangeNotifier {
  final CuentaService _cuentaService;

  // ¡ELIMINAMOS LOS TEXTEDITINGCONTROLLER DE AQUÍ!
  // final TextEditingController nombreController = TextEditingController();
  // final TextEditingController correoController = TextEditingController();

  Cuenta? _cuentaActiva;

  final void Function(Cuenta?, Perfil?) _clearAndSetProviders;

  ConfigTabController({
    required CuentaService cuentaService,
    required Cuenta? cuentaInicial,
    required void Function(Cuenta?, Perfil?) clearAndSetProviders,
  }) : _cuentaService = cuentaService,
       _cuentaActiva = cuentaInicial,
       _clearAndSetProviders = clearAndSetProviders {
    // Ya no inicializamos controllers aquí
    // _loadInitialData(); // Este método ya no es necesario aquí
  }

  // Ahora, el controlador solo provee los datos actuales de la cuenta
  Cuenta? get cuentaActiva => _cuentaActiva;

  // Método unificado para guardar cambios de perfil (nombre/correo/contraseña)
  // Ahora recibe directamente los valores de nombre, correo y nuevaContrasena
  Future<bool> guardarCambios({
    required String nuevoNombre,
    required String nuevoCorreo,
    String? nuevaContrasena,
  }) async {
    if (_cuentaActiva == null) {
      debugPrint("Error: No hay cuenta activa para guardar cambios.");
      return false;
    }

    // Crear una nueva instancia de Cuenta con los datos proporcionados
    final cuentaParaActualizar = _cuentaActiva!.copyWith(
      name: nuevoNombre,
      email: nuevoCorreo,
    );

    final bool success = await _cuentaService.editarPerfil(
      cuentaParaActualizar,
      nuevaContrasena:
          nuevaContrasena, // Pasamos la nueva contraseña aquí si existe
    );

    if (success) {
      // Si la edición en el backend fue exitosa, actualizamos el estado local
      // y notificamos a Riverpod con la nueva instancia inmutable de Cuenta.
      _cuentaActiva = cuentaParaActualizar; // Actualiza la referencia local
      _clearAndSetProviders(cuentaParaActualizar, null); // SOLO LA CUENTA AQUÍ

      notifyListeners();
      debugPrint(
        'Cambios de cuenta (nombre/correo/contraseña) guardados con éxito.',
      );
      return true;
    } else {
      debugPrint('Error al guardar cambios a través de editarPerfil.');
      return false;
    }
  }

  // MÉTODO PARA CERRAR SESIÓN Y LIMPIAR TODOS LOS ESTADOS RELEVANTES
  void logout() {
    debugPrint(
      'ConfigTabController: Realizando logout y limpiando providers...',
    );
    _cuentaActiva = null; // Borrar la cuenta activa localmente
    // Llamar al callback para limpiar los providers de Riverpod
    _clearAndSetProviders(null, null); // Limpiar Cuenta y Perfil
    // Ya no limpiamos controllers aquí
    debugPrint('ConfigTabController: Logout completado y providers limpiados.');
  }

  @override
  void dispose() {
    debugPrint('ConfigTabController dispuesto.');
    super.dispose();
  }
}
