import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/providers/app_providers.dart';
import 'package:wallet_safe/controllers/config_tab_controller.dart';
import 'package:wallet_safe/views/login.dart'; // <--- VERIFICA ESTA RUTA

class ConfigTab extends ConsumerStatefulWidget {
  const ConfigTab({super.key});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  final _formKey = GlobalKey<FormState>();
  bool _editando = false;

  // DECLARAR LOS TEXTEDITINGCONTROLLER AQUÍ, DENTRO DEL STATE
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;

  @override
  void initState() {
    super.initState();
    // Inicializar los controladores aquí
    final cuentaActiva = ref.read(
      cuentaActivaProvider,
    ); // Leer el valor inicial
    _nombreController = TextEditingController(text: cuentaActiva?.name ?? '');
    _correoController = TextEditingController(text: cuentaActiva?.email ?? '');
  }

  @override
  void dispose() {
    // DISPONER LOS CONTROLADORES CUANDO EL WIDGET SE DISPONE
    _nombreController.dispose();
    _correoController.dispose();
    debugPrint(
      'ConfigTab: TextEditingControllers de nombre y correo dispuestos.',
    );
    super.dispose();
  }

  Future<void> _guardarCambios(ConfigTabController configController) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Comparar si hubo cambios reales antes de llamar al backend
      final cuentaActual = configController.cuentaActiva;
      final nuevoNombre = _nombreController.text;
      final nuevoCorreo = _correoController.text;

      bool hayCambios = false;
      if (cuentaActual != null) {
        if (nuevoNombre != cuentaActual.name ||
            nuevoCorreo != cuentaActual.email) {
          hayCambios = true;
        }
      } else {
        // Si no hay cuenta actual pero estamos "guardando", algo raro pasa, forzamos true para que el error del backend lo capture.
        hayCambios = true;
      }

      if (!hayCambios) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay cambios para guardar.')),
          );
          setState(() {
            _editando = false; // Salir del modo edición si no hay cambios
          });
        }
        return; // No hacer nada si no hay cambios
      }

      final bool success = await configController.guardarCambios(
        nuevoNombre: nuevoNombre,
        nuevoCorreo: nuevoCorreo,
        nuevaContrasena: null, // La contraseña se maneja por separado
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cambios guardados con éxito')),
          );
          setState(() {
            _editando = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar cambios')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configController = ref.read(configTabControllerProvider);
    final cuentaActiva = ref.watch(
      cuentaActivaProvider,
    ); // Observar para redirección

    // Redirigir a login si no hay cuenta activa (ej. después de logout)
    if (cuentaActiva == null) {
      Future.microtask(() {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginView()),
            (Route<dynamic> route) => false,
          );
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    // Actualizar los controladores de texto si la cuentaActiva cambia
    // Esto es importante si el usuario edita el perfil desde otro lugar
    // o si el _nombreController se actualiza por alguna razón externa.
    // Solo actualizamos si no estamos editando para no sobrescribir la entrada del usuario.
    if (!_editando) {
      _nombreController.text = cuentaActiva.name;
      _correoController.text = cuentaActiva.email;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Cuenta'),
        actions: [
          IconButton(
            icon: Icon(_editando ? Icons.check : Icons.edit),
            onPressed: () {
              if (_editando) {
                // Si estamos editando, intentamos guardar los cambios de nombre/correo
                _guardarCambios(configController);
              } else {
                // Si no estamos editando, activamos el modo edición
                setState(() {
                  _editando = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreController, // Usar controlador local
                decoration: const InputDecoration(
                  labelText: 'Nombre de Cuenta',
                ),
                enabled: _editando,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre no puede estar vacío';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController, // Usar controlador local
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: _editando,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El correo no puede estar vacío';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Introduce un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    _editando // Habilitar solo si estamos editando
                        ? () {
                          _showChangePasswordDialog(context, configController);
                        }
                        : null,
                icon: const Icon(Icons.lock),
                label: const Text('Cambiar Contraseña'),
              ),
              const Divider(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmLogout = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Cerrar Sesión'),
                          content: const Text(
                            '¿Estás seguro de que quieres cerrar tu sesión?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Cerrar Sesión'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmLogout == true) {
                      // Llamar a la función logout del controlador, que limpiará los providers
                      configController.logout();
                      if (mounted) {
                        // Navegar a la pantalla de login y remover todas las rutas anteriores
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                          (Route<dynamic> route) =>
                              false, // Esto elimina todas las rutas anteriores
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    ConfigTabController controller,
  ) {
    final _changePasswordFormKey = GlobalKey<FormState>();

    // DECLARAR LOS TextEditingController LOCALES AL DIÁLOGO
    final TextEditingController nuevaContrasenaController =
        TextEditingController();
    final TextEditingController confirNuevaContrasenaController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Form(
            key: _changePasswordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nuevaContrasenaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Al menos 6 caracteres para cambiar contraseña';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: confirNuevaContrasenaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirma tu nueva contraseña';
                    }
                    if (value != nuevaContrasenaController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // DISPONER LOS CONTROLADORES LOCALES AL CANCELAR
                nuevaContrasenaController.dispose();
                confirNuevaContrasenaController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_changePasswordFormKey.currentState!.validate()) {
                  // Llamar a guardarCambios del controlador, pasando todos los valores
                  // para que el controlador tenga los datos completos para enviar.
                  final success = await controller.guardarCambios(
                    nuevoNombre:
                        _nombreController
                            .text, // Obtener del controlador principal
                    nuevoCorreo:
                        _correoController
                            .text, // Obtener del controlador principal
                    nuevaContrasena:
                        nuevaContrasenaController
                            .text, // Obtener del controlador del diálogo
                  );
                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contraseña cambiada con éxito'),
                        ),
                      );
                      // DISPONER LOS CONTROLADORES LOCALES AL CAMBIAR Y CERRAR
                      nuevaContrasenaController.dispose();
                      confirNuevaContrasenaController.dispose();
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al cambiar contraseña.'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        );
      },
    );
  }
}
