import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importa Riverpod
import 'package:wallet_safe/controllers/ingresos_tab_controller.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart'; // Asegúrate de la ruta correcta
import 'package:wallet_safe/models/familia.dart'; // Asegúrate de la ruta correcta
import 'package:wallet_safe/providers/app_providers.dart'; // Importa tus providers

/// `IngresosTab` es un widget que permite al usuario gestionar ingresos
/// y presupuestos, tanto personales como familiares.
/// Ahora utiliza Riverpod para acceder a la cuenta activa, el perfil seleccionado
/// y el controlador de la pestaña de ingresos.
class IngresosTab extends ConsumerStatefulWidget {
  const IngresosTab({super.key});

  @override
  ConsumerState<IngresosTab> createState() => _IngresosTabState();
}

class _IngresosTabState extends ConsumerState<IngresosTab> {
  final _formKeyIngresoPersonal = GlobalKey<FormState>();
  final _formKeyPresupuestoPersonal = GlobalKey<FormState>();
  final _formKeyPresupuestoFamiliar = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // No necesitamos desregistrar listeners ni hacer dispose del controlador aquí,
    // ya que Riverpod con .autoDispose se encarga de ello.
    super.dispose();
  }

  Widget _buildModuleContainer({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    EdgeInsets? padding,
    List<Widget>? actions,
  }) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        padding: padding ?? const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1, color: Colors.grey),
            child,
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Perfil? perfil = ref.watch(perfilSeleccionadoProvider);
    final Cuenta? cuenta = ref.watch(cuentaActivaProvider);

    if (perfil == null || cuenta == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando información de ingresos...'),
          ],
        ),
      );
    }
    final IngresosTabController ingresosController = ref.watch(
      ingresosTabControllerProvider.notifier,
    );

    final double balanceActual = perfil.balance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Dinero'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25.0, top: 5),
                child: Column(
                  children: [
                    const Text(
                      'Tu Saldo Disponible:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${balanceActual.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color:
                            balanceActual >= 0
                                ? Colors.green[700]
                                : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- MÓDULO 1: AÑADIR INGRESO PERSONAL ---
            _buildModuleContainer(
              title: 'Añadir Ingreso Personal',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.green.shade700,
              child: Form(
                key: _formKeyIngresoPersonal,
                child: Column(
                  children: [
                    TextFormField(
                      controller:
                          ingresosController
                              .montoController, // Usa el controller de Riverpod
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Monto del Ingreso',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                        hintText: 'Ej. 150000.00',
                      ),
                      validator:
                          (value) => ingresosController.validateMonto(
                            value,
                          ), // Usa el controller de Riverpod
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller:
                          ingresosController
                              .descripcionController, // Usa el controller de Riverpod
                      maxLength: 100,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      value:
                          ingresosController
                              .categoriaIngresoSeleccionada, // Usa el controller de Riverpod
                      items:
                          ingresosController.categoriasIngresosPersonales.map((
                            categoria,
                          ) {
                            return DropdownMenuItem<String>(
                              value: categoria,
                              child: Text(categoria),
                            );
                          }).toList(),
                      onChanged: (value) {
                        // Notificar al controlador de Riverpod el cambio
                        ingresosController.setCategoriaIngresoSeleccionada(
                          value,
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona una categoría';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('¿Ingreso automático?'),
                      activeColor: Colors.green,
                      value:
                          ingresosController
                              .esAutomatico, // Usa el controller de Riverpod
                      onChanged: (value) {
                        ingresosController.setEsAutomatico(
                          value,
                        ); // Usa el controller de Riverpod
                      },
                    ),
                    if (ingresosController.esAutomatico) ...[
                      // Usa el controller de Riverpod
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de ingreso',
                          prefixIcon: Icon(Icons.repeat),
                          border: OutlineInputBorder(),
                        ),
                        value:
                            ingresosController
                                .tipoIngreso, // Usa el controller de Riverpod
                        items:
                            ['Fijo', 'Variable'].map((tipo) {
                              return DropdownMenuItem<String>(
                                value: tipo,
                                child: Text(tipo),
                              );
                            }).toList(),
                        onChanged: (value) {
                          ingresosController.setTipoIngreso(
                            value ?? 'Fijo',
                          ); // Usa el controller de Riverpod
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKeyIngresoPersonal.currentState!
                              .validate()) {
                            try {
                              ingresosController
                                  .guardarIngreso(); // Usa el controller de Riverpod
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ingreso personal guardado correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al guardar ingreso: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Guardar Ingreso'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- MÓDULO 2: CREAR PRESUPUESTO (Personal y Familiar) ---
            _buildModuleContainer(
              title: 'Crear Presupuesto',
              icon: Icons.pie_chart_outline,
              color: Colors.blue.shade700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Sub-módulo: Crear Presupuesto Personal (para el perfil actual) ---
                  Text(
                    'Presupuesto Personal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKeyPresupuestoPersonal,
                    child: Column(
                      children: [
                        TextFormField(
                          controller:
                              ingresosController
                                  .montoPresupuestoPersonalController, // Usa el controller de Riverpod
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Monto para tu presupuesto personal',
                            prefixIcon: Icon(Icons.monetization_on_outlined),
                            border: OutlineInputBorder(),
                            hintText: 'Ej. 50000.00',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa un monto';
                            }
                            final monto = double.tryParse(
                              value.replaceAll(',', '.'),
                            );
                            if (monto == null || monto <= 0) {
                              return 'Monto inválido';
                            }
                            // Validar contra el balance actual del perfil obtenido por Riverpod
                            if (monto > perfil.balance) {
                              return 'Monto supera tu saldo disponible';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Categoría del presupuesto',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          value:
                              ingresosController
                                  .categoriaPresupuestoPersonalSeleccionada, // Usa el controller de Riverpod
                          items:
                              ingresosController.categoriasPresupuestoPersonal
                                  .map((categoria) {
                                    return DropdownMenuItem<String>(
                                      value: categoria,
                                      child: Text(categoria),
                                    );
                                  })
                                  .toList(),
                          onChanged: (value) {
                            // Notificar al controlador de Riverpod el cambio
                            ingresosController
                                .setCategoriaPresupuestoPersonalSeleccionada(
                                  value,
                                );
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona una categoría';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_formKeyPresupuestoPersonal.currentState!
                                  .validate()) {
                                try {
                                  ingresosController
                                      .crearPresupuestoPersonal(); // Usa el controller de Riverpod
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Presupuesto personal de \$${ingresosController.montoPresupuestoPersonalController.text} para ${ingresosController.categoriaPresupuestoPersonalSeleccionada!} creado.',
                                      ),
                                      backgroundColor: Colors.indigo,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al crear presupuesto personal: ${e.toString()}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add_task),
                            label: const Text('Crear Presupuesto Personal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Sub-módulo: Crear Presupuesto Familiar (Solo para Titulares) ---
                  if (perfil is Titular) ...[
                    // Usa el perfil obtenido por Riverpod
                    const Divider(height: 40, thickness: 1, color: Colors.grey),
                    Text(
                      'Presupuesto Familiar (Asignar a otro perfil)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKeyPresupuestoFamiliar,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar perfil familiar',
                              prefixIcon: Icon(Icons.group),
                              border: OutlineInputBorder(),
                            ),
                            value:
                                ingresosController
                                    .perfilFamiliarSeleccionadoNombre, // Usa el controller de Riverpod
                            items:
                                cuenta
                                    .familiares // Usa la cuenta obtenida por Riverpod
                                    .whereType<Familia>()
                                    .map((f) {
                                      return DropdownMenuItem<String>(
                                        value: f.nombre,
                                        child: Text(f.nombre),
                                      );
                                    })
                                    .toList(),
                            onChanged: (value) {
                              // Notificar al controlador de Riverpod el cambio
                              ingresosController
                                  .setPerfilFamiliarSeleccionadoNombre(value);
                            },
                            validator: (value) {
                              // Solo validamos si hay familiares registrados para asignar.
                              if (cuenta.familiares
                                      .whereType<Familia>()
                                      .isNotEmpty &&
                                  value == null) {
                                return 'Selecciona un perfil familiar';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:
                                ingresosController
                                    .montoPresupuestoFamiliarController, // Usa el controller de Riverpod
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Monto a asignar',
                              prefixIcon: Icon(Icons.money_off_csred_outlined),
                              border: OutlineInputBorder(),
                              hintText: 'Ej. 25000.00',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa un monto';
                              }
                              final monto = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
                              if (monto == null || monto <= 0) {
                                return 'Monto inválido';
                              }
                              // Validar contra el balance actual del perfil obtenido por Riverpod
                              if (monto > perfil.balance) {
                                return 'Monto supera tu saldo disponible';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Categoría del presupuesto',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            value:
                                ingresosController
                                    .categoriaPresupuestoFamiliarSeleccionada, // Usa el controller de Riverpod
                            items:
                                ingresosController.categoriasPresupuestoFamiliar
                                    .map((categoria) {
                                      return DropdownMenuItem<String>(
                                        value: categoria,
                                        child: Text(categoria),
                                      );
                                    })
                                    .toList(),
                            onChanged: (value) {
                              // Notificar al controlador de Riverpod el cambio
                              ingresosController
                                  .setCategoriaPresupuestoFamiliarSeleccionada(
                                    value,
                                  );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona una categoría';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_formKeyPresupuestoFamiliar.currentState!
                                    .validate()) {
                                  try {
                                    ingresosController
                                        .asignarPresupuestoFamiliar(); // Usa el controller de Riverpod
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Presupuesto de \$${ingresosController.montoPresupuestoFamiliarController.text} para ${ingresosController.perfilFamiliarSeleccionadoNombre!} en categoría ${ingresosController.categoriaPresupuestoFamiliarSeleccionada!} asignado.',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al asignar presupuesto: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.send_to_mobile),
                              label: const Text('Asignar Presupuesto Familiar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
