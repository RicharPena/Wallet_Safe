// lib/views/profiles.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/views/homePage.dart' hide IterableExtension;
import 'package:wallet_safe/providers/app_providers.dart';

class ProfileViews extends ConsumerStatefulWidget {
  const ProfileViews({super.key});

  @override
  ConsumerState<ProfileViews> createState() => _ProfileViewsState();
}

class _ProfileViewsState extends ConsumerState<ProfileViews> {
  Future<void> _createFamiliaProfile(Cuenta cuentaActual) async {
    String nuevoNombre = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear perfil familiar'),
          content: TextField(
            onChanged: (value) {
              nuevoNombre = value;
            },
            decoration: const InputDecoration(hintText: 'Nombre del perfil'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (nuevoNombre.trim().isNotEmpty &&
                    cuentaActual.perfilesMetadata.length < 4) {
                  try {
                    final perfilService = ref.read(perfilServiceProvider);
                    final response = await perfilService.crearPerfil(
                      nuevoNombre.trim(),
                      cuentaActual.id,
                      'familiar',
                    );

                    if (response['estado'] == 'ok' && mounted) {
                      // --- INICIO DE LA CORRECCIÓN ---
                      // ¡ELIMINAMOS LA LLAMADA A perfilService.login AQUÍ!

                      // Asumimos que el backend de 'crearPerfil' devuelve el ID del perfil creado.
                      // Por ejemplo: {'estado': 'ok', 'mensaje': 'Perfil creado', 'id_perfil_creado': 123}
                      final int? newProfileId = int.tryParse(
                        response['id_perfil_creado']?.toString() ?? '',
                      );

                      if (newProfileId != null) {
                        final newProfileName = nuevoNombre.trim();
                        final newProfileMetadata = {
                          'id': newProfileId,
                          'nombre': newProfileName,
                          'tipo':
                              'familiar', // Asegúrate de que este tipo coincida con tu backend
                        };

                        // Crear una nueva lista de metadatos de perfiles con el nuevo perfil.
                        final List<Map<String, dynamic>> updatedMetadataList =
                            List<Map<String, dynamic>>.from(
                              cuentaActual.perfilesMetadata,
                            )..add(newProfileMetadata);

                        // Crear una nueva instancia de Cuenta con los metadatos actualizados.
                        final updatedCuenta = cuentaActual.copyWith(
                          perfilesMetadata: updatedMetadataList,
                        );

                        // Actualizar el estado de cuentaActivaProvider con la nueva Cuenta.
                        ref
                            .read(cuentaActivaProvider.notifier)
                            .setCuenta(updatedCuenta);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Perfil "$newProfileName" creado con éxito.',
                            ),
                          ),
                        );
                        Navigator.pop(context); // Cierra el diálogo
                      } else {
                        // Si el backend no devuelve el ID del nuevo perfil, hay un problema.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: No se pudo obtener el ID del perfil creado. ${response['mensaje']}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      // --- FIN DE LA CORRECCIÓN ---
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            response['mensaje'] ?? 'Error al crear perfil.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error al crear perfil familiar: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nombre de perfil inválido o límite alcanzado.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerfilCard(Map<String, dynamic> perfilMetadata) {
    final int perfilId = perfilMetadata['id'] as int;
    final String perfilNombre = perfilMetadata['nombre'] as String;

    return GestureDetector(
      onTap: () async {
        await ref.read(perfilActivoProvider.notifier).setPerfilActivo(perfilId);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Entraste con el perfil: $perfilNombre')),
          );
        }
      },
      child: Container(
        width: 140,
        height: 100,
        decoration: BoxDecoration(
          color: const Color.fromARGB(208, 76, 185, 197),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          perfilNombre,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAgregarPerfilCard(Cuenta cuentaActual) {
    return GestureDetector(
      onTap: () => _createFamiliaProfile(cuentaActual),
      child: Container(
        width: 140,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey, width: 2),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 30, color: Colors.black54),
            SizedBox(height: 8),
            Text('Agregar perfil'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Cuenta? cuentaActual = ref.watch(cuentaActivaProvider);

    if (cuentaActual == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Seleccionar perfil'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(215, 88, 242, 106),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  ...cuentaActual.perfilesMetadata
                      .map(_buildPerfilCard)
                      .toList(),
                  if (cuentaActual.perfilesMetadata.length < 4)
                    _buildAgregarPerfilCard(cuentaActual),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
