import 'package:flutter/material.dart';
import 'package:wallet_safe/controllers/gastos_tab_controller.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart';

class GastosTab extends StatefulWidget {
  final Cuenta cuenta;
  final Perfil perfil;

  const GastosTab({required this.cuenta, required this.perfil, super.key});

  @override
  State<GastosTab> createState() => _GastosTabState();
}

class _GastosTabState extends State<GastosTab> {
  final _formKey = GlobalKey<FormState>();
  late final GastosTabController controller;

  final TextEditingController eliminarPresupuestoController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = GastosTabController(
      cuenta: widget.cuenta,
      perfil: widget.perfil,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Gasto'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: controller.montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.money_off),
                ),
                validator: controller.validateMonto,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.descripcionController,
                maxLength: 100,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                value: controller.categoriaSeleccionada,
                items:
                    controller.categorias
                        .map(
                          (categoria) => DropdownMenuItem<String>(
                            value: categoria,
                            child: Text(categoria),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    controller.categoriaSeleccionada = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('¿Gasto automático?'),
                value: controller.esAutomatico,
                onChanged: (value) {
                  setState(() {
                    controller.esAutomatico = value;
                  });
                },
              ),
              if (controller.esAutomatico) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de gasto',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  value: controller.tipoGasto,
                  items:
                      ['Fijo', 'Variable']
                          .map(
                            (tipo) => DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      controller.tipoGasto = value ?? 'Fijo';
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    controller.guardarGasto();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gasto guardado correctamente'),
                      ),
                    );
                    _formKey.currentState!.reset();
                    setState(() {
                      controller.reset();
                    });
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Gasto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
              if (controller.perfil is Titular) ...[
                const Divider(height: 32, color: Colors.black45),
                const Text(
                  'Gestión de presupuesto familiar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: eliminarPresupuestoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Eliminar del presupuesto familiar',
                    prefixIcon: Icon(Icons.remove_circle_outline),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final monto =
                        double.tryParse(
                          eliminarPresupuestoController.text.replaceAll(
                            ',',
                            '.',
                          ),
                        ) ??
                        0.0;
                    if (monto > 0) {
                      setState(() {
                        (controller.perfil as Titular).balance -= monto;
                      });
                      eliminarPresupuestoController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Presupuesto familiar reducido'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.remove),
                  label: const Text('Eliminar del presupuesto familiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
