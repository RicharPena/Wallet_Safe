class RegisterController {
  String validarRegistro({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return 'Por favor, completa todos los campos';
    }

    if (!_isValidEmail(email)) {
      return 'El correo electrónico no es válido';
    }

    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }

    // Aquí llamar a la capa de persistencia

    return 'Registro exitoso';
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}
