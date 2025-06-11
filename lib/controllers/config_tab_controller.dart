import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/services/cuenta_service.dart';

// Importante: Mezclamos con ChangeNotifier para que Riverpod pueda escucharlo
class ConfigTabController with ChangeNotifier {
  final CuentaService _cuentaService = CuentaService();

  // Controladores de texto para los campos del formulario
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final TextEditingController confirContrasenaController =
      TextEditingController();

  // La cuenta activa que será gestionada por este controlador
  final Cuenta?
  _cuentaActiva; // La hacemos privada para usar getter y setter si es necesario

  // Constructor que recibe la cuenta activa
  ConfigTabController({required Cuenta? cuentaInicial})
    : _cuentaActiva = cuentaInicial {
    // Inicializamos los controladores con los datos de la cuenta al crear el controlador
    if (_cuentaActiva != null) {
      nombreController.text =
          _cuentaActiva.name; // Usa '!' porque ya verificaste que no es null
      correoController.text = _cuentaActiva.email; // Usa '!'
    } else {
      // Si la cuenta es null, asegúrate de que los controladores estén vacíos
      nombreController.clear();
      correoController.clear();
    }
    // Las contraseñas no se precargan por seguridad

    // Si la 'Cuenta' misma es un ChangeNotifier y queremos que el controlador reaccione
    // a cambios externos en la cuenta, podríamos añadir un listener aquí:
    // _cuentaActiva.addListener(notifyListeners);
    // Sin embargo, para este caso, las actualizaciones de la cuenta se inician desde este controlador.
  }

  // Getter para acceder a la cuenta activa desde la UI si es necesario
  Cuenta? get cuentaActiva => _cuentaActiva;

  // Método para actualizar la cuenta usando tu CuentaService
  Future<bool> actualizarCuenta(String? nuevaContrasena) async {
    // Las propiedades de la cuenta se actualizan antes de llamar al servicio
    _cuentaActiva?.name = nombreController.text.trim();
    _cuentaActiva?.email = correoController.text.trim();

    final bool success = await _cuentaService.editarPerfil(
      _cuentaActiva!, // Pasamos la instancia de la cuenta que está siendo editada
      nuevaContrasena: nuevaContrasena,
    );

    if (success) {
      // Notificamos a los listeners que el estado de la cuenta (indirectamente) ha cambiado.
      // Esto es crucial para que cualquier widget que observe este controlador (o la cuenta a través de él)
      // se reconstruya y muestre los datos actualizados.
      notifyListeners();
    }
    return success;
  }

  // Método para limpiar los campos de contraseña después de una operación
  void clearPasswordFields() {
    contrasenaController.clear();
    confirContrasenaController.clear();
    notifyListeners(); // Notifica que los campos han sido limpiados
  }

  @override
  void dispose() {
    // ¡Muy importante! Liberar los recursos de los TextEditingControllers
    nombreController.dispose();
    correoController.dispose();
    contrasenaController.dispose();
    confirContrasenaController.dispose();

    // Si hubiéramos añadido un listener a _cuentaActiva, lo removeríamos aquí:
    // _cuentaActiva.removeListener(notifyListeners);

    super.dispose(); // Llama al método dispose de ChangeNotifier
  }
}
