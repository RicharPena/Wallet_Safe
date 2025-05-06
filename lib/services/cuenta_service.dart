import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CuentaService {
  final String baseUrl =
      'http://10.0.2.2/proyecto_wallet_safe/controlador/broker.php'; // Cambia esta URL

  Future<Map<String, dynamic>> registrar(Map<String, dynamic> datos) async {
    final response = await http.post(
      Uri.parse('$baseUrl?accion=registrar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );

    return _procesarRespuesta(response);
  }

  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl?accion=login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );

    return _procesarRespuesta(response);
  }

  Future<Map<String, dynamic>> editarPerfil(Map<String, dynamic> datos) async {
    final response = await http.post(
      Uri.parse('$baseUrl?accion=editar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );

    return _procesarRespuesta(response);
  }

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
