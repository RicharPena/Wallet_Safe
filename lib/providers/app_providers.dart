import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cuenta.dart'; // Asegúrate de la ruta
import '../models/perfil.dart'; // Asegúrate de la ruta

// Provider para la instancia de Cuenta.
// Este será sobrescrito en el punto de login.
final cuentaActivaProvider = Provider<Cuenta>((ref) {
  // Por defecto, lanza un error si se accede antes de ser sobrescrito.
  // Es una buena práctica para Providers que necesitan ser inicializados.
  throw UnimplementedError(
    'cuentaActivaProvider debe ser inicializado al iniciar sesión.',
  );
});

// Provider para el Perfil seleccionado (el que está activo en HomePage).
// Este será sobrescrito en el punto de selección de perfil.
final perfilSeleccionadoProvider = Provider<Perfil>((ref) {
  throw UnimplementedError(
    'perfilSeleccionadoProvider debe ser inicializado al seleccionar un perfil.',
  );
});

// También puedes poner aquí el familiaViewModelProvider si quieres centralizar todos los providers.
// final familiaViewModelProvider =
//     StateNotifierProvider.autoDispose<FamiliaViewModel, Familia?>(
//       (ref) => FamiliaViewModel(),
//     );
// Aunque ya lo tienes en su propio archivo, lo dejo como nota.
