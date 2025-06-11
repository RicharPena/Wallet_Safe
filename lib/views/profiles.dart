import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/views/homePage.dart' hide IterableExtension;
import '../providers/app_providers.dart';

// Extensión para firstWhereOrNull, la mantendremos aquí por ahora si es global.
// Si solo se usa en ProfileViews, podrías moverla dentro del archivo si prefieres.
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ProfileViews extends ConsumerStatefulWidget {
  const ProfileViews({super.key});

  @override
  ConsumerState<ProfileViews> createState() => _ProfileViewsState();
}

class _ProfileViewsState extends ConsumerState<ProfileViews> {
  @override
  void initState() {
    super.initState();
  }

  void _agregarPerfil(Cuenta cuentaActual) {
    String nuevoNombre = '';
    showDialog(
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
              onPressed: () {
                if (nuevoNombre.trim().isNotEmpty &&
                    cuentaActual.perfiles.length < 4) {
                  // Asumimos que `agregarFamiliar` modifica la lista de perfiles
                  // directamente en el objeto Cuenta. Si `Cuenta` es un
                  // ChangeNotifier, esto notificará a `cuentaActivaProvider`
                  // para que reconstruya `ProfileViews`. Si `Cuenta` es inmutable,
                  // necesitarías crear una nueva instancia de Cuenta con los perfiles
                  // actualizados y luego llamar a `ref.read(cuentaActivaProvider.notifier).setCuenta(nuevaCuenta)`.
                  setState(() {
                    cuentaActual.agregarFamiliar(nuevoNombre.trim());
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerfilCard(Perfil perfil) {
    return GestureDetector(
      onTap: () {
        // Usa ref.read para obtener el notifier y establecer el perfil seleccionado globalmente
        ref.read(perfilSeleccionadoProvider.notifier).setPerfil(perfil);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    HomePage(), // HomePage no necesita un ProviderScope aquí
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entraste con el perfil: ${perfil.nombre}')),
        );
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
          perfil.nombre,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAgregarPerfilCard(Cuenta cuentaActual) {
    return GestureDetector(
      onTap: () => _agregarPerfil(cuentaActual),
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
          // Añadido 'const' para optimización
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
    // ref.watch() aquí es para que ProfileViews se reconstruya si la cuenta cambia.
    // Esto es importante si el método `agregarFamiliar` modifica la `Cuenta` de forma que notifica.
    print('--- ProfileViews: Reconstruyendo ---');
    final Cuenta? cuentaActual = ref.watch(cuentaActivaProvider);
    print(
      'ProfileViews - cuentaActual: ${cuentaActual != null ? "Disponible" : "NULL"}',
    );

    // Muestra un indicador de carga o un mensaje si la cuenta aún es null (aunque no debería pasar aquí)
    if (cuentaActual == null) {
      print(
        'ProfileViews - ERROR: cuentaActual es NULL después de salir de perfil.',
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    print(
      'ProfileViews - Número de perfiles en cuentaActual: ${cuentaActual.perfiles.length}',
    );
    if (cuentaActual.perfiles.isEmpty) {
      print(
        'ProfileViews - Advertencia: La lista de perfiles de la cuenta está vacía.',
      );
      // Si la lista de perfiles está vacía (aunque tu constructor de Cuenta
      // siempre añade un 'Titular'), esto podría ser un punto de fallo si
      // la data no se carga correctamente.
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
                  ...cuentaActual.perfiles.map(_buildPerfilCard).toList(),
                  if (cuentaActual.perfiles.length < 4)
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
