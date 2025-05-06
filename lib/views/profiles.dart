import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/views/homePage.dart';

class ProfileViews extends StatefulWidget {
  final Cuenta cuenta;

  const ProfileViews({required this.cuenta, super.key});

  @override
  _ProfileViewsState createState() => _ProfileViewsState();
}

class _ProfileViewsState extends State<ProfileViews> {
  List<Perfil> get perfiles => widget.cuenta.perfiles;

  void _agregarPerfil() {
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
                if (nuevoNombre.trim().isNotEmpty && perfiles.length < 4) {
                  setState(() {
                    widget.cuenta.agregarFamiliar(nuevoNombre.trim());
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomePage(cuenta: widget.cuenta, perfil: perfil),
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

  Widget _buildAgregarPerfilCard() {
    return GestureDetector(
      onTap: _agregarPerfil,
      child: Container(
        width: 140,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey, width: 2),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
                  ...perfiles.map(_buildPerfilCard).toList(),
                  if (perfiles.length < 4) _buildAgregarPerfilCard(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
