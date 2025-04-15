class Cuenta {
  final String name;
  final String email;
  final String password;

  Cuenta({required this.name, required this.email, required this.password});

  // Simulación de base de datos
  static final List<Cuenta> _cuentas = [];

  static void registrar(Cuenta cuenta) {
    _cuentas.add(cuenta);
  }

  static bool iniciarSesion(String email, String password) {
    return _cuentas.any((c) => c.email == email && c.password == password);
  }

  //Tengamos esta por si acaso
  static Cuenta? obtenerCuenta(String email) {
    try {
      return _cuentas.firstWhere((c) => c.email == email);
    } catch (e) {
      return null;
    }
  }
}
