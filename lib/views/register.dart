import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importa Riverpod
import 'package:wallet_safe/controllers/register_controller.dart'; // Importa el controlador
import 'package:wallet_safe/providers/app_providers.dart'; // Importa app_providers para acceder al provider

class RegisterPage extends ConsumerStatefulWidget {
  // Cambia a ConsumerStatefulWidget
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState(); // Cambia a ConsumerState
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // Ahora los TextEditingController son gestionados por el RegisterController
  // final nameController = TextEditingController(); // Ya no son necesarios aquí
  // final emailController = TextEditingController();
  // final passwordController = TextEditingController();
  // final confirmPasswordController = TextEditingController();

  // No necesitamos instanciar el controlador aquí, Riverpod lo provee
  // final registerController = RegisterController(); // Eliminar esta línea

  @override
  void initState() {
    super.initState();
    // Limpiar mensajes al entrar a la pantalla (opcional, pero buena práctica)
    // Se gestiona mejor observando los cambios de estado.
  }

  @override
  void dispose() {
    // Los controladores de texto ahora son dispuestos por RegisterController
    // al ser autoDispose.
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Observar el estado del RegisterController
    final registerState = ref.watch(registerControllerProvider);
    final registerController = ref.read(
      registerControllerProvider.notifier,
    ); // Acceder al notifier para llamar a métodos

    // Escuchar cambios de estado para mostrar Snackbars
    ref.listen<RegisterState>(registerControllerProvider, (previous, current) {
      if (current.errorMessage != null &&
          previous?.errorMessage != current.errorMessage) {
        _showSnackBar(current.errorMessage!, isError: true);
        registerController
            .clearMessages(); // Limpiar el mensaje después de mostrarlo
      } else if (current.successMessage != null &&
          previous?.successMessage != current.successMessage) {
        _showSnackBar(current.successMessage!, isError: false);
        registerController.clearMessages(); // Limpiar el mensaje
        Navigator.pop(context); // Navegar de vuelta al login
      }
    });

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
              controller:
                  registerController
                      .nameController, // Usa el controlador de Riverpod
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Campo: Correo electrónico
            TextField(
              controller:
                  registerController
                      .emailController, // Usa el controlador de Riverpod
              decoration: const InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Campo: Contraseña
            TextField(
              controller:
                  registerController
                      .passwordController, // Usa el controlador de Riverpod
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Campo: Confirmar contraseña
            TextField(
              controller:
                  registerController
                      .confirmPasswordController, // Usa el controlador de Riverpod
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Botón de registrar
            ElevatedButton(
              onPressed:
                  registerState.isLoading
                      ? null
                      : () => registerController.register(),
              child:
                  registerState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrarse'),
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
