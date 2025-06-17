import 'package:flutter/material.dart'; // Para TextEditingController
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Para StateNotifier
import 'package:wallet_safe/services/perfil_service.dart'; // Importa tu servicio

/// Define el estado que el RegisterController manejará.
/// Usaremos un record de Dart para simplicidad.
typedef RegisterState =
    ({bool isLoading, String? errorMessage, String? successMessage});

class RegisterController extends StateNotifier<RegisterState> {
  final PerfilService _perfilService;

  // Controladores de texto gestionados por el controlador
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  RegisterController({required PerfilService perfilService})
    : _perfilService = perfilService,
      super(
        // Estado inicial
        (isLoading: false, errorMessage: null, successMessage: null),
      );

  Future<void> register() async {
    // Resetear mensajes de estado al iniciar el registro
    state = (isLoading: true, errorMessage: null, successMessage: null);

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      state = (
        isLoading: false,
        errorMessage: 'Por favor, completa todos los campos',
        successMessage: null,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      state = (
        isLoading: false,
        errorMessage: 'El correo electrónico no es válido',
        successMessage: null,
      );
      return;
    }

    if (password != confirmPassword) {
      state = (
        isLoading: false,
        errorMessage: 'Las contraseñas no coinciden',
        successMessage: null,
      );
      return;
    }

    try {
      final result = await _perfilService.registrarUsuario(
        name,
        email,
        password,
      );

      if (result['estado'] == 'ok') {
        state = (
          isLoading: false,
          errorMessage: null,
          successMessage: 'Registro exitoso',
        );
        clearFields(); // Limpiar campos al éxito
      } else {
        state = (
          isLoading: false,
          errorMessage: result['mensaje'] ?? 'Error desconocido al registrar',
          successMessage: null,
        );
      }
    } catch (e) {
      state = (
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
        successMessage: null,
      );
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void clearMessages() {
    state = (
      isLoading: state.isLoading,
      errorMessage: null,
      successMessage: null,
    );
  }

  void clearFields() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
