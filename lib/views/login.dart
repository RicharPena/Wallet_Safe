import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/views/profiles.dart';
import 'package:wallet_safe/views/register.dart';
import 'package:wallet_safe/services/cuenta_service.dart';

class LoginView extends StatefulWidget {
  LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final correo = emailController.text;
    final contrasena = passwordController.text;

    try {
      final response = await CuentaService().login(correo, contrasena);

      if (response['estado'] == 'ok') {
        final usuario = response['usuario'];

        final cuenta = Cuenta(
          name: usuario['nombre'],
          email: usuario['correo'],
          password: contrasena,
        );

        Cuenta.cuentaActiva = cuenta;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileViews(cuenta: cuenta)),
        );
      } else {
        _mostrarError(response['mensaje'] ?? 'Error desconocido');
      }
    } catch (e) {
      _mostrarError('Fallo en la conexión con el servidor');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Wallet Safe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 108, 238, 47),
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
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar Sesión'),
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
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
