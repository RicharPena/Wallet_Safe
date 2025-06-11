import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importa ConsumerStatefulWidget
import 'package:wallet_safe/models/cuenta.dart';
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
      final cuenta = await Cuenta.iniciarSesion(correo, contrasena);

      if (cuenta != null) {
        // Usa ref.read para obtener el notifier y actualizar la Cuenta activa globalmente.
        // Esto sobrescribe el estado del provider en el ProviderScope raíz.
        ref.read(cuentaActivaProvider.notifier).setCuenta(cuenta);

        // Navega a ProfileViews sin un ProviderScope, ya que el estado se maneja globalmente.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileViews()),
        );
      } else {
        _mostrarError('Correo o contraseña incorrectos');
      }
    } catch (e) {
      _mostrarError(
        'Fallo en la conexión con el servidor: $e',
      ); // Mostrar el error para depurar
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              // Añadido 'const' para optimización
              'Wallet Safe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 108, 238, 47),
              ),
            ),
            const SizedBox(height: 60),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo',
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
              // Añadido 'const' para optimización
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
