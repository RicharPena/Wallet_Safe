import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/providers/app_providers.dart'; // Importamos todos los providers
import 'package:wallet_safe/controllers/config_tab_controller.dart'; // Importamos el controlador
import 'package:wallet_safe/views/login.dart'; // Asume que tienes tu pantalla de Login

class ConfigTab extends ConsumerStatefulWidget {
  const ConfigTab({super.key});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditingProfile =
      false; // Estado para controlar si estamos editando el perfil
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores aquí.
    // Los valores iniciales se cargarán del estado del controller en build.
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Métodos de UI y Lógica de Interacción ---

  // Método para guardar cambios de nombre/correo
  Future<void> _saveProfileChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      final configController = ref.read(configTabControllerProvider.notifier);
      final success = await configController.updateAccountDetails(
        newName: _nameController.text.trim(),
        newEmail: _emailController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado con éxito!')),
          );
          setState(() {
            _isEditingProfile = false; // Salir del modo edición
          });
        } else {
          // Mostrar mensaje de error del controlador
          final errorMessage =
              ref.read(configTabControllerProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Error al actualizar el perfil.'),
            ),
          );
        }
      }
    }
  }

  // Diálogo para cambiar la contraseña
  Future<void> _showChangePasswordDialog() async {
    final _newPasswordController = TextEditingController();
    final _confirmNewPasswordController = TextEditingController();
    final _passwordFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Form(
            key: _passwordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese una nueva contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme su nueva contraseña';
                    }
                    if (value != _newPasswordController.text) {
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            Consumer(
              builder: (context, ref, child) {
                final configState = ref.watch(configTabControllerProvider);
                return ElevatedButton(
                  onPressed:
                      configState.isLoading
                          ? null
                          : () async {
                            if (_passwordFormKey.currentState?.validate() ??
                                false) {
                              final configController = ref.read(
                                configTabControllerProvider.notifier,
                              );
                              final success = await configController
                                  .changePassword(
                                    newPassword: _newPasswordController.text,
                                  );
                              if (mounted) {
                                Navigator.of(
                                  dialogContext,
                                ).pop(); // Cerrar el diálogo
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Contraseña cambiada con éxito!'
                                          : configState.errorMessage ??
                                              'Error al cambiar contraseña.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                  child:
                      configState.isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Cambiar'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Método para cerrar sesión
  Future<void> _logout() async {
    final configController = ref.read(configTabControllerProvider.notifier);
    await configController.logout();
    if (mounted) {
      // Navegar a la pantalla de login, eliminando todas las rutas anteriores
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginView(),
        ), // Asume LoginView
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observamos el estado del controlador
    final configState = ref.watch(configTabControllerProvider);
    final Cuenta? account = configState.cuenta;

    // Actualizamos los controladores de texto solo si la cuenta es diferente o estamos entrando en modo edición
    if (account != null && !_isEditingProfile) {
      _nameController.text = account.name ?? '';
      _emailController.text = account.email ?? '';
    }

    if (account == null && !configState.isLoading) {
      // Esto podría pasar si la sesión ha expirado o se ha cerrado
      return const Center(child: Text('No hay cuenta activa.'));
    }

    if (configState.isLoading && account == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo suave
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade400, // Tono de verde amigable
        elevation: 0,
        // Icono de edición/guardar en la AppBar
        actions: [
          if (!_isEditingProfile)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditingProfile = true;
                });
              },
            ),
          if (_isEditingProfile)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _saveProfileChanges,
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
              // Sección de Información de Perfil
              Card(
                margin: const EdgeInsets.only(bottom: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Perfil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditingProfile,
                        decoration: _inputDecoration(
                          'Nombre de Usuario',
                          Icons.person,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre no puede estar vacío';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _emailController,
                        enabled: _isEditingProfile,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          'Correo Electrónico',
                          Icons.email,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El correo no puede estar vacío';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Ingrese un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      if (_isEditingProfile) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingProfile = false;
                                  // Restablecer los controladores a los valores originales si se cancela
                                  _nameController.text = account?.name ?? '';
                                  _emailController.text = account?.email ?? '';
                                });
                              },
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _saveProfileChanges,
                              icon:
                                  configState.isLoading
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.save),
                              label: Text(
                                configState.isLoading
                                    ? 'Guardando...'
                                    : 'Guardar Cambios',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Sección de Seguridad
              Card(
                margin: const EdgeInsets.only(bottom: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seguridad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.blueGrey),
                        title: const Text('Cambiar Contraseña'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showChangePasswordDialog,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tileColor:
                            Colors.grey[50], // Fondo ligero para el ListTile
                      ),
                    ],
                  ),
                ),
              ),

              // Sección de Acciones
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        onTap: _logout,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tileColor: Colors.grey[50],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Estilo de InputDecoration reutilizable
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green.shade600, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    );
  }
}
