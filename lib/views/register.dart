import 'package:flutter/material.dart';
import 'package:wallet_safe/controllers/register_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final registerController = RegisterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Crear cuenta',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(103, 192, 171, 522),
              ),
            ),
            const SizedBox(height: 40),

            // Campo: Nombre completo
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Campo: Correo electrónico
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Campo: Contraseña
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Campo: Confirmar contraseña
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Botón de registrar
            ElevatedButton(
              onPressed: () async {
                final result = await registerController.validarRegistro(
                  name: nameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  confirmPassword: confirmPasswordController.text,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(result)));

                if (result == 'Registro exitoso') {
                  Navigator.pop(context);
                }
              },
              child: const Text('Registrarse'),
            ),
            const SizedBox(height: 10),

            // Texto para volver al login
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Volver a la pantalla anterior
              },
              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
