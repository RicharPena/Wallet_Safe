import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importar Riverpod
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/providers/app_providers.dart'; // Importar app_providers para acceder a los providers

// Cambiamos a ConsumerStatefulWidget para acceder a Riverpod
class GastosTab extends ConsumerStatefulWidget {
  const GastosTab({super.key}); // Eliminamos los parámetros cuenta y perfil

  @override
  ConsumerState<GastosTab> createState() => _GastosTabState();
}

// Cambiamos a ConsumerState
class _GastosTabState extends ConsumerState<GastosTab> {
  final _formKey = GlobalKey<FormState>();
  // Ya no necesitamos 'late final GastosTabController controller;' aquí.
  // Lo obtendremos directamente del ref en el build método.

  final TextEditingController eliminarPresupuestoController =
      TextEditingController();

  @override
  void dispose() {
    eliminarPresupuestoController.dispose();
    // No necesitamos llamar a controller.dispose() aquí porque Riverpod
    // se encarga de disponer del ChangeNotifier cuando el provider se invalida
    // (gracias a autoDispose).
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observamos el controller utilizando ref.watch.
    // Cuando el controller notifica cambios, este widget se reconstruirá.
    final controller = ref.watch(gastosTabControllerProvider);

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
                // Aquí usamos el setter para actualizar el valor en el controller
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
                  // Llama al setter del controller
                  controller.setCategoriaSeleccionada(value);
                  // setState ya no es necesario para esto, notifyListeners() en el controller lo manejará
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('¿Gasto automático?'),
                // Aquí usamos el setter para actualizar el valor en el controller
                value: controller.esAutomatico,
                onChanged: (value) {
                  // Llama al setter del controller
                  controller.setEsAutomatico(value);
                  // setState ya no es necesario para esto
                },
              ),
              if (controller.esAutomatico) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de gasto',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  // Aquí usamos el setter para actualizar el valor en el controller
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
                    // Llama al setter del controller
                    controller.setTipoGasto(value ?? 'Fijo');
                    // setState ya no es necesario para esto
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
                    // Llama a reset del controller para limpiar y notificar
                    controller.reset();
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Gasto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
              // Aquí accedemos al perfil directamente del controlador
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
                      // Acceso directo a la cuenta y perfil a través del controlador
                      try {
                        // Aquí estamos modificando el balance directamente en el perfil del controlador.
                        // Asegúrate de que esta lógica sea la deseada.
                        // Si Titular.asignarPresupuestoAFamilia maneja la resta del balance,
                        // o si esta es una operación de "reembolso", deberías ajustar la lógica
                        // para llamar a un método en el controller (e.g., `controller.eliminarMontoPresupuestoFamiliar(monto)`).
                        // Por ahora, lo dejo como estaba pero tenlo en cuenta para el diseño de tu lógica.
                        (controller.perfil as Titular).balance -= monto;
                        eliminarPresupuestoController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Presupuesto familiar reducido'),
                          ),
                        );
                        // Notificar cambios al perfil (y por ende a los widgets que lo escuchan)
                        (controller.perfil
                            as Titular); // Si Titular extiende ChangeNotifier
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
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
