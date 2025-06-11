import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importar Riverpod
import 'package:wallet_safe/providers/app_providers.dart'; // Importar app_providers para acceder a los providers

/// `ConfigTab` es un widget que permite al usuario ver y editar la información de su cuenta.
/// Ahora utiliza Riverpod para acceder a la cuenta activa y su controlador de configuración.
class ConfigTab extends ConsumerStatefulWidget {
  const ConfigTab({super.key}); // Eliminamos el parámetro 'cuenta'

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  final _formKey = GlobalKey<FormState>();
  // El controlador ahora se obtiene de Riverpod, no se inicializa aquí
  // final _controller = ConfigTabController(); // Esta línea ya no es necesaria

  // El estado de edición se mantiene local al widget de UI
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    // No necesitamos inicializar los TextEditingController aquí
    // ya que serán gestionados por el ConfigTabController.
  }

  @override
  void dispose() {
    // Los TextEditingController son dispuestos por el ConfigTabController
    // cuando el provider se auto-dispone.
    super.dispose();
  }

  // Este método ahora interactúa con el ConfigTabController obtenido de Riverpod
  Future<void> _guardarCambios() async {
    // Obtener la instancia del controlador usando ref.read
    final configController = ref.read(configTabControllerProvider);

    if (_formKey.currentState!.validate()) {
      // Validar contraseñas antes de intentar actualizar
      if (configController.contrasenaController.text.isNotEmpty &&
          configController.contrasenaController.text !=
              configController.confirContrasenaController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')),
        );
        return;
      }

      // Llamar al método actualizarCuenta del controlador
      final ok = await configController.actualizarCuenta(
        configController.contrasenaController.text.isNotEmpty
            ? configController.contrasenaController.text
            : null,
      );

      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        setState(() => _editando = false);
        configController
            .clearPasswordFields(); // Limpiar campos de contraseña después de guardar
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al actualizar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observar la cuenta activa y el controlador de configuración de Riverpod
    final cuenta = ref.watch(cuentaActivaProvider); // Obtener la cuenta activa
    final configController = ref.watch(
      configTabControllerProvider,
    ); // Obtener el controlador de configuración

    // NOTA: Los TextEditingController dentro de configController se inicializan
    // con los valores de 'cuenta' cuando configTabControllerProvider se crea.
    // Si la 'cuenta' cambia (ej. por un nuevo login), configTabControllerProvider
    // se invalidará y recreará, lo que reinicializará los TextEditingController
    // con los nuevos valores de la cuenta.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            icon: Icon(_editando ? Icons.save : Icons.edit),
            onPressed: () {
              if (_editando) {
                _guardarCambios();
              } else {
                setState(() => _editando = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller:
                    configController
                        .nombreController, // Usar controller de Riverpod
                decoration: const InputDecoration(labelText: 'Nombre'),
                enabled: _editando,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Nombre requerido'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller:
                    configController
                        .correoController, // Usar controller de Riverpod
                decoration: const InputDecoration(labelText: 'Correo'),
                enabled: _editando,
                validator:
                    (value) =>
                        value != null && value.contains('@')
                            ? null
                            : 'Correo inválido',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller:
                    configController
                        .contrasenaController, // Usar controller de Riverpod
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                ),
                obscureText: true,
                enabled: _editando,
              ),
              if (_editando)
                TextFormField(
                  controller:
                      configController
                          .confirContrasenaController, // Usar controller de Riverpod
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (configController.contrasenaController.text.isNotEmpty &&
                        value != configController.contrasenaController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              if (_editando)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: _guardarCambios,
                    child: const Text('Guardar cambios'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
