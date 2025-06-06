import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wallet_safe/models/cuenta.dart';

class CuentaService {
  //final String baseUrl = 'http://10.0.2.2/proyecto_wallet_safe/controlador/broker.php'; // Para Emulador Android
  final String baseUrl =
      'http://192.168.1.63/proyecto_wallet_safe/controlador/broker.php'; // Para celular físico (cambiar IP)
  //final String baseUrl = 'http://localhost/proyecto_wallet_safe/controlador/broker.php'; // Para cargar en página web

  //MÉTODO PARA REGISTRAR
  Future<Map<String, dynamic>> registrar(Map<String, dynamic> datos) async {
    final response = await http.post(
      Uri.parse('$baseUrl?accion=registrar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );

    return _procesarRespuesta(response);
  }

  //MÉTODO PARA EL LOGIN
  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl?accion=login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );

    return _procesarRespuesta(response);
  }

  //MÉTODO PARA EDITAR PERFIL
  Future<bool> editarPerfil(Cuenta cuenta, {String? nuevaContrasena}) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}?accion=editar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': cuenta.id,
          'nombre': cuenta.name,
          'correo': cuenta.email,
          if (nuevaContrasena != null && nuevaContrasena.isNotEmpty)
            'contrasena': nuevaContrasena,
        }),
      );

      print('Raw response: ${response.body}');

      final data = jsonDecode(response.body);
      return data['estado'] == 'ok';
    } catch (e) {
      print('Error al editar perfil: $e');
      return false;
    }
  }

  //MÉTODO AUXILIAR PARA EL PROCESAMIENTO DE LA RESPUESTA
  Map<String, dynamic> _procesarRespuesta(http.Response response) {
    final body = response.body;
    debugPrint(
      'Respuesta cruda del servidor:\n$body',
    ); // debugPrint asegura que se vea

    if (response.statusCode == 200) {
      try {
        return jsonDecode(body);
      } catch (e) {
        return {
          'estado': 'error',
          'mensaje': 'Error al decodificar respuesta',
          'cuerpo': body,
        };
      }
    } else {
      return {
        'estado': 'error',
        'mensaje': 'Error de red: ${response.statusCode}',
      };
    }
  }
}
