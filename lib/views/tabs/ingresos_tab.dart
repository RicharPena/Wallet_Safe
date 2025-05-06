import 'package:flutter/material.dart';
import 'package:wallet_safe/controllers/ingresos_tab_controller.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart';

class IngresosTab extends StatefulWidget {
  final Cuenta cuenta;
  final Perfil perfil;

  const IngresosTab({required this.cuenta, required this.perfil, super.key});

  @override
  State<IngresosTab> createState() => _IngresosTabState();
}

class _IngresosTabState extends State<IngresosTab> {
  final _formKey = GlobalKey<FormState>();
  late final IngresosTabController controller; // Declaración del controlador

  double montoAgregarPresupuesto = 0.0;
  double montoAsignarAFamilia = 0.0;
  String? perfilSeleccionado;
  final TextEditingController agregarPresupuestoController =
      TextEditingController();
  final TextEditingController asignarAFamiliaController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicialización del controlador con cuenta y perfil
    controller = IngresosTabController(
      cuenta: widget.cuenta,
      perfil: widget.perfil,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Ingreso'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Monto
              TextFormField(
                controller: controller.montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) => controller.validateMonto(value),
              ),

              const SizedBox(height: 16),

              // Descripción
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

              // Categoría
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                value: controller.categoriaSeleccionada,
                items:
                    controller.categorias.map((categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    controller.categoriaSeleccionada = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Automático switch
              SwitchListTile(
                title: const Text('¿Ingreso automático?'),
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
                    labelText: 'Tipo de ingreso',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  value: controller.tipoIngreso,
                  items:
                      ['Fijo', 'Variable'].map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      controller.tipoIngreso = value ?? 'Fijo';
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              //Botón para guardar los ingresos PROPIOS
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    controller.guardarIngreso();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingreso guardado correctamente'),
                      ),
                    );
                    _formKey.currentState!.reset();
                    setState(() {
                      controller.reset();
                    });
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Ingreso'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),

              // ---------------------- AGREGAR AL PRESUPUESTO FAMILIAR ----------------------
              if (controller.perfil is Titular) ...[
                const Divider(height: 32, color: Colors.black45),
                const Text(
                  'Gestión de presupuesto familiar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: agregarPresupuestoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Agregar al presupuesto familiar',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                ),

                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final monto =
                        double.tryParse(
                          agregarPresupuestoController.text.replaceAll(
                            ',',
                            '.',
                          ),
                        ) ??
                        0.0;
                    if (monto > 0) {
                      setState(() {
                        (controller.perfil as Titular).presupuestoFamiliar +=
                            monto;
                      });
                      agregarPresupuestoController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Presupuesto familiar actualizado'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir al presupuesto familiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                ),

                const SizedBox(height: 24),

                // ---------------------- ASIGNAR A FAMILIA ----------------------
                Text(
                  'Presupuesto disponible: \$${(controller.perfil as Titular).presupuestoFamiliar.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar perfil familiar',
                    prefixIcon: Icon(Icons.people),
                  ),
                  value: perfilSeleccionado,
                  items:
                      controller.cuenta.familiares.map((f) {
                        return DropdownMenuItem<String>(
                          value: f.nombre,
                          child: Text(f.nombre),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      perfilSeleccionado = value;
                    });
                  },
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: asignarAFamiliaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto a asignar',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),

                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (perfilSeleccionado == null) return;

                    final monto =
                        double.tryParse(
                          asignarAFamiliaController.text.replaceAll(',', '.'),
                        ) ??
                        0.0;

                    final titular = controller.perfil as Titular;
                    final familiar = controller.cuenta.familiares.firstWhere(
                      (f) => f.nombre == perfilSeleccionado,
                    );

                    final exito = titular.asignarPresupuestoAFamilia(
                      familiar,
                      monto,
                    );

                    if (exito) {
                      setState(() {});
                      asignarAFamiliaController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Se asignaron \$${monto.toStringAsFixed(2)} a ${familiar.nombre}',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Monto inválido o insuficiente'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Asignar a familia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
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
