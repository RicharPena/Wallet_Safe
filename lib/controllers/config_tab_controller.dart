// lib/controllers/config_tab_controller.dart
import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/services/cuenta_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigTabController extends ChangeNotifier {
  final CuentaService _cuentaService = CuentaService();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final TextEditingController confirContrasenaController =
      TextEditingController();

  Cuenta? _cuentaActiva;

  final void Function(Cuenta) _updateCuentaInNotifier;

  ConfigTabController({
    required Cuenta? cuentaInicial,
    required void Function(Cuenta) updateCuentaInNotifier,
  }) : _cuentaActiva = cuentaInicial,
       _updateCuentaInNotifier = updateCuentaInNotifier {
    if (_cuentaActiva != null) {
      nombreController.text = _cuentaActiva!.name;
      correoController.text = _cuentaActiva!.email;
    } else {
      nombreController.clear();
      correoController.clear();
    }
  }

  Cuenta? get cuentaActiva => _cuentaActiva;

  Future<bool> guardarCambios(String? nuevaContrasena) async {
    if (_cuentaActiva == null) {
      debugPrint("Error: No hay cuenta activa para guardar cambios.");
      return false;
    }

    final String nuevoNombre = nombreController.text.trim();
    final String nuevoCorreo = correoController.text.trim();

    // Crear una *nueva instancia* de Cuenta con los datos que se intentan guardar
    // Esto es crucial porque _cuentaActiva es inmutable.
    final cuentaParaActualizar = _cuentaActiva!.copyWith(
      name: nuevoNombre,
      email: nuevoCorreo,
    );

    // Llama a tu método existente `editarPerfil` de CuentaService
    // Ahora le pasamos la instancia de `Cuenta` que queremos actualizar
    // y la posible nueva contraseña.
    final bool success = await _cuentaService.editarPerfil(
      cuentaParaActualizar, // Le pasamos la nueva instancia de Cuenta
      nuevaContrasena: nuevaContrasena, // La contraseña va aparte
    );

    if (success) {
      // Si la edición en el backend fue exitosa, actualizamos el estado local
      // y notificamos a Riverpod con la nueva instancia inmutable de Cuenta.
      _cuentaActiva = cuentaParaActualizar; // Actualiza la referencia local
      _updateCuentaInNotifier(cuentaParaActualizar); // Notifica a Riverpod

      notifyListeners();
      return true;
    } else {
      // Si hubo un error en el backend, los campos locales y la cuenta de Riverpod
      // no se modifican, y se indica el fallo.
      debugPrint('Error al guardar cambios a través de editarPerfil.');
      return false;
    }
  }

  void clearPasswordFields() {
    contrasenaController.clear();
    confirContrasenaController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    contrasenaController.dispose();
    confirContrasenaController.dispose();
    super.dispose();
  }
}
