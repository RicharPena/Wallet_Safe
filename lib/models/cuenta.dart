import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/services/cuenta_service.dart';

class Cuenta {
  final int? id;
  String name;
  String email;
  final String? password;

  final List<Perfil> perfiles = [];

  static Cuenta? cuentaActiva;

  // Constructor: crea el Titular como el primer perfil
  Cuenta({this.id, required this.name, required this.email, this.password}) {
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
        id: usuario['id'],
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

  //MÉTODO PARA REGISTRARSE
  static Future<String> registrarCuentaRemota({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await CuentaService().registrar({
      'nombre': name,
      'correo': email,
      'contrasena': password,
    });

    if (response['estado'] == 'ok') {
      final cuenta = Cuenta(name: name, email: email, password: password);
      _cuentas.add(cuenta);
      return 'Registro exitoso';
    } else {
      return response['mensaje'] ?? 'Error desconocido';
    }
  }

  //MÉTODO PARA EDITAR CUENTA
  factory Cuenta.fromJson(Map<String, dynamic> json) {
    return Cuenta(
      id: int.parse(json['id'].toString()),
      name: json['nombre'],
      email: json['correo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': name, 'correo': email};
  }

  static Cuenta? obtenerCuenta(String email) {
    try {
      return _cuentas.firstWhere((c) => c.email == email);
    } catch (e) {
      return null;
    }
  }
}
