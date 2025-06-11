import 'package:flutter/foundation.dart'; // Importar para ChangeNotifier
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/services/cuenta_service.dart';

// 1. Extender ChangeNotifier
class Cuenta extends ChangeNotifier {
  final int? id;
  String name;
  String email;
  final String? password;

  // 2. Hacer la lista perfiles privada para controlar su mutación a través de métodos
  final List<Perfil> _perfiles = [];

  // Opcional pero recomendado: un getter para acceder a la lista inmutablemente desde fuera
  List<Perfil> get perfiles =>
      List.unmodifiable(_perfiles); // Retorna una copia no modificable

  // 3. Eliminar static Cuenta? cuentaActiva; ya que Riverpod lo gestionará.
  // static Cuenta? cuentaActiva; // ¡Eliminar o comentar!

  // Constructor: crea el Titular como el primer perfil
  Cuenta({this.id, required this.name, required this.email, this.password}) {
    _perfiles.add(Titular(id: 0, nombre: 'Titular'));
  }

  /// Obtener el titular
  Titular get titular => _perfiles.firstWhere((p) => p is Titular) as Titular;

  /// Obtener todos los perfiles tipo Familia
  List<Familia> get familiares =>
      _perfiles.whereType<Familia>().toList(growable: false);

  /// Agregar un perfil tipo Familia
  void agregarFamiliar(String nombreFamiliar) {
    // Generar un ID simple. Considera un ID más robusto si lo necesitas.
    final nuevoFamiliar = Familia(
      id: _perfiles.length + 1,
      nombre: nombreFamiliar,
    );
    _perfiles.add(nuevoFamiliar);
    // 4. ¡Notificar a los listeners del cambio!
    notifyListeners();
  }

  // Simulación de base de datos (mantener si es relevante para tus tests/mockups)
  static final List<Cuenta> _cuentas = [];

  //Guarda los datos en la base de datos
  static void registrar(Cuenta cuenta) {
    _cuentas.add(cuenta);
  }

  // MÉTODO PARA INICIAR SESION
  // Este método estático no necesita modificar la instancia de Cuenta.
  // El consumer en LoginView usará el StateNotifier para establecer la cuenta.
  static Future<Cuenta?> iniciarSesion(String correo, String contrasena) async {
    final response = await CuentaService().login(correo, contrasena);

    if (response['estado'] == 'ok') {
      final usuario = response['usuario'];
      final cuenta = Cuenta(
        id: usuario['id'],
        name: usuario['nombre'],
        email: usuario['correo'],
        password: contrasena, // Asegúrate de que el password sea necesario aquí
      );
      // ¡Eliminar o comentar! cuentaActiva = cuenta;
      return cuenta;
    } else {
      return null;
    }
  }

  // MÉTODO PARA REGISTRARSE
  // Similar a iniciarSesion, no necesita modificar la instancia de Cuenta.
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
      _cuentas.add(cuenta); // Si _cuentas es para simulación local, manténlo
      return 'Registro exitoso';
    } else {
      return response['mensaje'] ?? 'Error desconocido';
    }
  }

  // MÉTODO PARA EDITAR CUENTA
  factory Cuenta.fromJson(Map<String, dynamic> json) {
    // Cuando creas una Cuenta desde JSON, debes asegurarte de cargar los perfiles
    // si están disponibles en la respuesta del servidor.
    // Esto es un placeholder, deberías adaptar cómo se cargan los perfiles.
    final cuenta = Cuenta(
      id: int.parse(json['id'].toString()),
      name: json['nombre'],
      email: json['correo'],
    );
    // Ejemplo: Si el JSON tuviera 'perfiles':
    // if (json['perfiles'] != null) {
    //   for (var pJson in json['perfiles']) {
    //     cuenta._perfiles.add(Perfil.fromJson(pJson)); // Necesitarías Perfil.fromJson
    //   }
    // }
    return cuenta;
  }

  Map<String, dynamic> toJson() {
    // Cuando serializas a JSON, también deberías incluir los perfiles.
    // Esto es un placeholder.
    return {
      'id': id,
      'nombre': name,
      'correo': email,
      // 'perfiles': _perfiles.map((p) => p.toJson()).toList(), // Necesitarías Perfil.toJson
    };
  }

  static Cuenta? obtenerCuenta(String email) {
    try {
      return _cuentas.firstWhere((c) => c.email == email);
    } catch (e) {
      return null;
    }
  }
}
