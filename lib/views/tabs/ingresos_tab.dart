import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
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
  final _formKeyIngresoPersonal = GlobalKey<FormState>();
  final _formKeyPresupuestoPersonal = GlobalKey<FormState>();
  final _formKeyPresupuestoFamiliar = GlobalKey<FormState>();

  late final IngresosTabController controller;

  final TextEditingController montoPresupuestoPersonalController =
      TextEditingController();
  final TextEditingController montoPresupuestoFamiliarController =
      TextEditingController();

  // *** CAMBIO: Variables de estado para las categorías seleccionadas, una por cada Dropdown
  // Se inicializan a null para que el Dropdown muestre el hint text si no hay selección.
  String? categoriaPresupuestoPersonalSeleccionada;
  String? categoriaPresupuestoFamiliarSeleccionada;
  String? perfilFamiliarSeleccionado;

  @override
  void initState() {
    super.initState();
    controller = IngresosTabController(
      cuenta: widget.cuenta,
      perfil: widget.perfil,
    );
    // No necesitamos inicializar aqui la categoriaIngresoSeleccionada,
    // el controller ya lo hace en su constructor.
    // Solo inicializamos las del presupuesto si es necesario que tengan un valor por defecto.
    // Por ahora, las dejamos en null para que el validador actúe.
  }

  @override
  void dispose() {
    montoPresupuestoPersonalController.dispose();
    montoPresupuestoFamiliarController.dispose();
    controller
        .dispose(); // Asegúrate de que tu controller también dispose sus TextEditingControllers
    super.dispose();
  }

  // Helper para crear los contenedores de módulo con estilo
  Widget _buildModuleContainer({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    EdgeInsets? padding,
    List<Widget>? actions, // Opcional para botones o acciones
  }) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), // Color más suave para el fondo
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
    // Escuchar cambios en el balance para actualizar la UI
    // Esto requiere que `Perfil` sea un `ChangeNotifier` o que use un state management como Provider/Riverpod
    // Por ahora, leeremos el balance directamente o con un setState si es un valor interno.
    // Asumo que el balance del perfil se mantiene actualizado en el modelo.
    // *** CAMBIO: Usar el balance del perfil. Asumo que perfil.balance está disponible. ***
    final double balanceActual =
        widget
            .perfil
            .presupuestoFamiliar; // O el balance que quieras mostrar aquí

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Dinero'),
        backgroundColor: Colors.indigo, // Nuevo color para la AppBar
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Dinero Disponible ---
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
                      controller: controller.montoController,
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
                      validator: (value) => controller.validateMonto(value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.descripcionController,
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
                      // *** CAMBIO: Usar controller.categoriaIngresoSeleccionada ***
                      value: controller.categoriaIngresoSeleccionada,
                      // *** CAMBIO: Usar categoriasIngresosPersonales del controller ***
                      items:
                          controller.categoriasIngresosPersonales.map((
                            categoria,
                          ) {
                            return DropdownMenuItem<String>(
                              value: categoria,
                              child: Text(categoria),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          // *** CAMBIO: Actualizar controller.categoriaIngresoSeleccionada ***
                          controller.categoriaIngresoSeleccionada = value;
                        });
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
                          border: OutlineInputBorder(),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKeyIngresoPersonal.currentState!
                              .validate()) {
                            controller.guardarIngreso();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingreso personal guardado correctamente',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _formKeyIngresoPersonal.currentState!.reset();
                            setState(() {
                              controller.reset();
                            });
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
                          controller: montoPresupuestoPersonalController,
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
                            // *** CAMBIO: Usar el balance actual del perfil para la validación ***
                            if (monto > balanceActual) {
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
                          // *** CAMBIO: Usar la variable de estado local categoriaPresupuestoPersonalSeleccionada ***
                          value: categoriaPresupuestoPersonalSeleccionada,
                          // *** CAMBIO: Usar categoriasPresupuestoPersonal del controller ***
                          items:
                              controller.categoriasPresupuestoPersonal.map((
                                categoria,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: categoria,
                                  child: Text(categoria),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              // *** CAMBIO: Actualizar la variable de estado local ***
                              categoriaPresupuestoPersonalSeleccionada = value;
                            });
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
                                final monto = double.parse(
                                  montoPresupuestoPersonalController.text
                                      .replaceAll(',', '.'),
                                );
                                // Lógica futura: Guardar presupuesto personal
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Presupuesto personal de \$${monto.toStringAsFixed(2)} para ${categoriaPresupuestoPersonalSeleccionada!} creado (funcionalidad futura)',
                                    ),
                                    backgroundColor: Colors.indigo,
                                  ),
                                );
                                montoPresupuestoPersonalController.clear();
                                setState(() {
                                  // Opcional: Resetear la selección del dropdown a null o al primero.
                                  categoriaPresupuestoPersonalSeleccionada =
                                      null;
                                });
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
                  if (widget.perfil is Titular) ...[
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
                            value: perfilFamiliarSeleccionado,
                            items:
                                widget.cuenta.familiares.map((f) {
                                  return DropdownMenuItem<String>(
                                    value: f.nombre,
                                    child: Text(f.nombre),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                perfilFamiliarSeleccionado = value;
                              });
                            },
                            validator: (value) {
                              if (widget.cuenta.familiares.isNotEmpty &&
                                  value == null) {
                                return 'Selecciona un perfil familiar';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: montoPresupuestoFamiliarController,
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
                              // *** CAMBIO: Usar el balance actual del perfil para la validación ***
                              if (monto > balanceActual) {
                                // Aquí usarías el balance del titular
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
                            // *** CAMBIO: Usar la variable de estado local categoriaPresupuestoFamiliarSeleccionada ***
                            value: categoriaPresupuestoFamiliarSeleccionada,
                            // *** CAMBIO: Usar categoriasPresupuestoFamiliar del controller ***
                            items:
                                controller.categoriasPresupuestoFamiliar.map((
                                  categoria,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: categoria,
                                    child: Text(categoria),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                // *** CAMBIO: Actualizar la variable de estado local ***
                                categoriaPresupuestoFamiliarSeleccionada =
                                    value;
                              });
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
                                  if (perfilFamiliarSeleccionado == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Por favor, selecciona un perfil familiar.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  final monto = double.parse(
                                    montoPresupuestoFamiliarController.text
                                        .replaceAll(',', '.'),
                                  );
                                  // Lógica futura: Asignar presupuesto familiar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Presupuesto de \$${monto.toStringAsFixed(2)} para ${perfilFamiliarSeleccionado!} en categoría ${categoriaPresupuestoFamiliarSeleccionada!} asignado (funcionalidad futura)',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  montoPresupuestoFamiliarController.clear();
                                  setState(() {
                                    perfilFamiliarSeleccionado =
                                        null; // Resetear selección
                                    // Opcional: Resetear la selección del dropdown a null o al primero.
                                    categoriaPresupuestoFamiliarSeleccionada =
                                        null;
                                  });
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
                  ], // Fin del if (widget.perfil is Titular) para Presupuesto Familiar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
