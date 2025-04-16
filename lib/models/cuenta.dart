import 'package:wallet_safe/models/perfil.dart';

class Cuenta {
  final String name;
  final String email;
  final String password;
  List<Perfil> perfiles = [];

  //Variable global
  static Cuenta? cuentaActiva;

  Cuenta({
    required this.name,
    required this.email,
    required this.password,
    List<Perfil>? perfiles,
  }) : perfiles = perfiles ?? [Perfil(id: 1, nombre: 'Titular')];

  // Simulación de base de datos
  static final List<Cuenta> _cuentas = [];

  static void registrar(Cuenta cuenta) {
    _cuentas.add(cuenta);
  }

  static bool iniciarSesion(String email, String password) {
    try {
      final cuenta = _cuentas.firstWhere(
        (c) => c.email == email && c.password == password,
      );
      cuentaActiva = cuenta;
      return true;
    } catch (e) {
      return false;
    }
  }

  /*
   FALTAN LOS MÉTODOS DE CERRAR SESION Y EDITAR PERFIL
  */

  //Tengamos esta por si acaso
  static Cuenta? obtenerCuenta(String email) {
    try {
      return _cuentas.firstWhere((c) => c.email == email);
    } catch (e) {
      return null;
    }
  }
}
