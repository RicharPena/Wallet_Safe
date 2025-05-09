import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/controllers/config_tab_controller.dart';

class ConfigTab extends StatefulWidget {
  final Cuenta cuenta;

  const ConfigTab({super.key, required this.cuenta});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  final _formKey = GlobalKey<FormState>();
  final _controller = ConfigTabController();

  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _contrasenaController;

  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cuenta.name);
    _correoController = TextEditingController(text: widget.cuenta.email);
    _contrasenaController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      widget.cuenta.name = _nombreController.text.trim();
      widget.cuenta.email = _correoController.text.trim();

      final ok = await _controller.actualizarCuenta(
        widget.cuenta,
        _contrasenaController.text.isNotEmpty
            ? _contrasenaController.text
            : null,
      );

      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Perfil actualizado')));
        setState(() => _editando = false);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
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
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre'),
                enabled: _editando,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Nombre requerido'
                            : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                decoration: InputDecoration(labelText: 'Correo'),
                enabled: _editando,
                validator:
                    (value) =>
                        value != null && value.contains('@')
                            ? null
                            : 'Correo inválido',
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contrasenaController,
                decoration: InputDecoration(labelText: 'Nueva contraseña'),
                obscureText: true,
                enabled: _editando,
              ),
              if (_editando)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: _guardarCambios,
                    child: Text('Guardar cambios'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
