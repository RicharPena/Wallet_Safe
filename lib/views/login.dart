import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importa ConsumerStatefulWidget
import 'package:wallet_safe/models/cuenta.dart'; // Mantener si la clase Cuenta se usa para el tipo
import 'package:wallet_safe/views/profiles.dart';
import 'package:wallet_safe/views/register.dart';
import 'package:wallet_safe/providers/app_providers.dart'; // ¡Importa tus providers!

// LoginView debe ser un ConsumerStatefulWidget para acceder a ref en _login
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final correo = emailController.text;
    final contrasena = passwordController.text;

    try {
      // 1. Obtener la instancia de PerfilService a través de Riverpod
      final perfilService = ref.read(perfilServiceProvider);

      // 2. Llamar al método iniciarSesion del PerfilService
      // Este método retorna un Map<String, dynamic> que incluye el estado y la Cuenta.
      final response = await perfilService.login(correo, contrasena);

      if (response['estado'] == 'ok' && response['cuenta'] != null) {
        // Asumiendo que 'cuenta' en la respuesta es un Map y puede ser convertido a una instancia de Cuenta
        final Cuenta cuenta = Cuenta.fromJson(response['cuenta']);

        // 3. Usa ref.read para obtener el notifier y actualizar la Cuenta activa globalmente.
        ref.read(cuentaActivaProvider.notifier).setCuenta(cuenta);

        // 4. Navega a ProfileViews sin permitir volver al login
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ProfileViews()),
            (route) => false, // Elimina todas las rutas anteriores
          );
        }
      } else {
        // Manejar errores de credenciales inválidas o otros errores del servidor
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['mensaje'] ?? 'Credenciales incorrectas.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Manejar errores generales (ej. de conexión a internet)
      debugPrint('Error durante el login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo o imagen de la aplicación (opcional)
            Icon(
              Icons.account_balance_wallet, // Ejemplo de ícono
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar Sesión'),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Text("o"),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
