import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/services/cuenta_service.dart';

class Cuenta {
  final String name;
  final String email;
  final String password;

  final List<Perfil> perfiles = [];

  static Cuenta? cuentaActiva;

  // Constructor: crea el Titular como el primer perfil
  Cuenta({required this.name, required this.email, required this.password}) {
    perfiles.add(Titular(id: 0, nombre: 'Titular'));
  }

  /// Obtener el titular
  Titular get titular => perfiles.firstWhere((p) => p is Titular) as Titular;

  /// Obtener todos los perfiles tipo Familia
  List<Familia> get familiares =>
      perfiles.whereType<Familia>().toList(growable: false);

  /// Agregar un perfil tipo Familia
  void agregarFamiliar(String nombreFamiliar) {
    final nuevoFamiliar = Familia(id: perfiles.length, nombre: nombreFamiliar);
    perfiles.add(nuevoFamiliar);
  }

  // Simulación de base de datos
  static final List<Cuenta> _cuentas = [];

  //Guarda los datos en la base de datos
  static void registrar(Cuenta cuenta) {
    _cuentas.add(cuenta);
  }

  //MÉTODO PARA INICIAR SESION
  static Future<Cuenta?> iniciarSesion(String correo, String contrasena) async {
    final response = await CuentaService().login(correo, contrasena);

    if (response['estado'] == 'ok') {
      final usuario = response['usuario'];
      final cuenta = Cuenta(
        name: usuario['nombre'],
        email: usuario['correo'],
        password: contrasena,
      );
      cuentaActiva = cuenta;
      return cuenta;
    } else {
      return null;
    }
  }

  static Cuenta? obtenerCuenta(String email) {
    try {
      return _cuentas.firstWhere((c) => c.email == email);
    } catch (e) {
      return null;
    }
  }
}
