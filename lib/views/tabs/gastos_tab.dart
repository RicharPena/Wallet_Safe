import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/controllers/gastos_tab_controller.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/providers/app_providers.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';

/// `GastosTab` es un widget que permite al usuario gestionar gastos
/// y gastar de presupuestos, tanto personales como familiares.
/// Utiliza Riverpod para acceder a la cuenta activa, el perfil seleccionado
/// y el controlador de la pestaña de gastos.
class GastosTab extends ConsumerStatefulWidget {
  const GastosTab({super.key});

  @override
  ConsumerState<GastosTab> createState() => _GastosTabState();
}

class _GastosTabState extends ConsumerState<GastosTab> {
  final _formKeyGastoPersonal = GlobalKey<FormState>();
  final _formKeyGastarPresupuestoPersonal = GlobalKey<FormState>();
  final _formKeyGastarPresupuestoFamiliar = GlobalKey<FormState>();

  // DECLARAR TextEditingControllers AQUÍ
  late TextEditingController montoController;
  late TextEditingController descripcionController;
  late TextEditingController montoGastoPresupuestoPersonalController;
  late TextEditingController montoGastoPresupuestoFamiliarController;

  @override
  void initState() {
    super.initState();
    // INICIALIZAR TextEditingControllers EN initState
    montoController = TextEditingController();
    descripcionController = TextEditingController();
    montoGastoPresupuestoPersonalController = TextEditingController();
    montoGastoPresupuestoFamiliarController = TextEditingController();
  }

  @override
  void dispose() {
    // LIBERAR TextEditingControllers EN dispose
    montoController.dispose();
    descripcionController.dispose();
    montoGastoPresupuestoPersonalController.dispose();
    montoGastoPresupuestoFamiliarController.dispose();
    super.dispose();
  }

  // Método para limpiar todos los controladores
  void _clearAllControllers() {
    montoController.clear();
    descripcionController.clear();
    montoGastoPresupuestoPersonalController.clear();
    montoGastoPresupuestoFamiliarController.clear();
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

  Widget _buildPresupuestoCard(
    String title,
    double amount,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              isSelected
                  ? BorderSide(color: color, width: 2.5)
                  : BorderSide.none,
        ),
        color: isSelected ? color.withOpacity(0.15) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Disponible: \$${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected ? color.darken(0.1) : Colors.blueGrey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Perfil? perfil = ref.watch(perfilActivoProvider);
    final Cuenta? cuenta = ref.watch(cuentaActivaProvider);

    if (perfil == null || cuenta == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando información de gastos...'),
          ],
        ),
      );
    }
    final GastosTabController gastosController = ref.watch(
      gastosTabControllerProvider.notifier,
    );

    final gastosState = ref.watch(gastosTabControllerProvider);

    final double balanceActual = perfil.balance;

    // Filtrar presupuestos personales del perfil actual
    final List<PresupuestoPersonal> presupuestosPersonalesDisponibles =
        perfil.cnPresupuestosPersonales
            .where((p) => p.idPresupuestoFamiliarOrigen == null)
            .toList();

    // Filtrar presupuestos familiares (aquellos con idPresupuestoFamiliarOrigen no nulo)
    final List<PresupuestoPersonal> presupuestosPersonalesDeOrigenFamiliar =
        (perfil is Familia)
            ? ref
                .watch(familiaViewModelProvider.notifier)
                .presupuestosPersonalesDeFamiliares
            : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Gastos'),
        backgroundColor: Colors.red[700],
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

            // --- MÓDULO 1: AÑADIR GASTO PERSONAL ---
            _buildModuleContainer(
              title: 'Añadir Gasto Personal',
              icon: Icons.money_off_csred,
              color: Colors.red.shade700,
              child: Form(
                key: _formKeyGastoPersonal,
                child: Column(
                  children: [
                    TextFormField(
                      controller: montoController, // Usar el controlador local
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Monto del Gasto',
                        prefixIcon: Icon(Icons.money_off),
                        border: OutlineInputBorder(),
                        hintText: 'Ej. 75000.00',
                      ),
                      validator:
                          (value) => gastosController.validateMonto(value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller:
                          descripcionController, // Usar el controlador local
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
                      value: gastosState.categoriaGastoSeleccionada,
                      items:
                          GastosTabController.categoriasGastosPersonales.map((
                            categoria,
                          ) {
                            return DropdownMenuItem<String>(
                              value: categoria,
                              child: Text(categoria),
                            );
                          }).toList(),
                      onChanged: (value) {
                        gastosController.setCategoriaSeleccionada(value);
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
                      title: const Text('¿Gasto automático?'),
                      activeColor: Colors.red,
                      value: gastosController.esAutomatico,
                      onChanged: (value) {
                        gastosController.setEsAutomatico(value);
                      },
                    ),
                    if (gastosController.esAutomatico) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de gasto',
                          prefixIcon: Icon(Icons.repeat),
                          border: OutlineInputBorder(),
                        ),
                        value: gastosController.tipoGasto,
                        items:
                            ['Fijo', 'Variable'].map((tipo) {
                              return DropdownMenuItem<String>(
                                value: tipo,
                                child: Text(tipo),
                              );
                            }).toList(),
                        onChanged: (value) {
                          gastosController.setTipoGasto(value ?? 'Fijo');
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_formKeyGastoPersonal.currentState!.validate()) {
                            final currentContext = context;
                            final controller = gastosController;
                            try {
                              await controller.guardarGastoPersonal(
                                double.parse(
                                  montoController.text.replaceAll(',', '.'),
                                ),
                                descripcionController.text.trim(),
                              );
                              if (currentContext.mounted) {
                                ScaffoldMessenger.of(
                                  currentContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Gasto personal guardado correctamente',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _clearAllControllers(); // Limpiar los controladores aquí
                              }
                            } catch (e) {
                              if (currentContext.mounted) {
                                ScaffoldMessenger.of(
                                  currentContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al guardar gasto: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Registrar Gasto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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

            // --- MÓDULO 2: GASTAR DE PRESUPUESTO PERSONAL ---
            _buildModuleContainer(
              title: 'Gastar de Presupuesto Personal',
              icon: Icons.analytics_outlined,
              color: Colors.blue.shade700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tus Presupuestos Personales:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (presupuestosPersonalesDisponibles.isEmpty)
                    const Text(
                      'No tienes presupuestos personales disponibles.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  else
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children:
                          presupuestosPersonalesDisponibles.map((presupuesto) {
                            final isSelected =
                                gastosState
                                    .presupuestoPersonalSeleccionado
                                    ?.id ==
                                presupuesto.id;
                            return _buildPresupuestoCard(
                              presupuesto.categoria,
                              presupuesto
                                  .montoTotal, //- presupuesto.montoGastado, // Mostrar monto disponible
                              Colors.blue.shade700,
                              isSelected,
                              () {
                                gastosController
                                    .setPresupuestoPersonalSeleccionado(
                                      presupuesto,
                                    );
                                // Limpiar el campo de monto de gasto cuando se selecciona un nuevo presupuesto
                                montoGastoPresupuestoPersonalController.clear();
                                descripcionController
                                    .clear(); // Limpiar también la descripción
                              },
                            );
                          }).toList(),
                    ),
                  const SizedBox(height: 20),
                  if (gastosState.presupuestoPersonalSeleccionado != null)
                    Form(
                      key: _formKeyGastarPresupuestoPersonal,
                      child: Column(
                        children: [
                          Text(
                            'Gastando de: ${gastosState.presupuestoPersonalSeleccionado!.categoria}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:
                                montoGastoPresupuestoPersonalController, // Usar el controlador local
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Monto a gastar de este presupuesto',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                              hintText: 'Ej. 10000.00',
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
                              final presupuestoRestante =
                                  gastosState
                                      .presupuestoPersonalSeleccionado!
                                      .montoTotal; //- gastosState.presupuestoPersonalSeleccionado!.montoGastado; // Monto real disponible
                              if (monto > presupuestoRestante) {
                                return 'Monto supera el disponible en el presupuesto';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:
                                descripcionController, // Usar el controlador local
                            maxLength: 100,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descripción del gasto',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La descripción es requerida';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (_formKeyGastarPresupuestoPersonal
                                    .currentState!
                                    .validate()) {
                                  final currentContext = context;
                                  try {
                                    await gastosController
                                        .gastarDePresupuestoPersonal(
                                          gastosState
                                              .presupuestoPersonalSeleccionado!,
                                          double.parse(
                                            montoGastoPresupuestoPersonalController
                                                .text
                                                .replaceAll(',', '.'),
                                          ),
                                          descripcionController.text.trim(),
                                        );
                                    if (currentContext.mounted) {
                                      ScaffoldMessenger.of(
                                        currentContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gasto de presupuesto personal registrado en ${gastosState.presupuestoPersonalSeleccionado!.categoria}.',
                                          ),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                      _clearAllControllers(); // Limpiar los controladores aquí
                                    }
                                  } catch (e) {
                                    if (currentContext.mounted) {
                                      ScaffoldMessenger.of(
                                        currentContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error al gastar de presupuesto personal: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.trending_down),
                              label: const Text(
                                'Gastar de Presupuesto Personal',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
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
              ),
            ),

            // --- MÓDULO 3: GASTAR DE PRESUPUESTO FAMILIAR (Solo para perfiles de tipo Familia) ---
            if (perfil is Familia) ...[
              _buildModuleContainer(
                title: 'Gastar de Presupuesto Familiar',
                icon: Icons.group_work_outlined,
                color: Colors.orange.shade700,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presupuestos Familiares Asignados:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (presupuestosPersonalesDeOrigenFamiliar.isEmpty)
                      const Text(
                        'No tienes presupuestos familiares asignados.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    else
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children:
                            presupuestosPersonalesDeOrigenFamiliar.map((
                              presupuestoFamiliar, // Ahora es PresupuestoPersonal
                            ) {
                              final isSelected =
                                  gastosState
                                      .presupuestoPersonalSeleccionado
                                      ?.id == // Nuevo campo en GastosState
                                  presupuestoFamiliar.id;
                              return _buildPresupuestoCard(
                                presupuestoFamiliar
                                    .categoria, // Propiedad de PresupuestoPersonal
                                presupuestoFamiliar
                                    .montoTotal, //- presupuestoPersonal.montoGastado, // Mostrar monto disponible
                                Colors.orange.shade700,
                                isSelected,
                                () {
                                  gastosController
                                      .setPresupuestoPersonalSeleccionado(
                                        // Nuevo método en GastosController
                                        presupuestoFamiliar,
                                      );
                                  // Limpiar el campo de monto de gasto cuando se selecciona un nuevo presupuesto
                                  montoGastoPresupuestoFamiliarController
                                      .clear();
                                  descripcionController
                                      .clear(); // Limpiar también la descripción
                                },
                              );
                            }).toList(),
                      ),
                    const SizedBox(height: 20),
                    if (gastosState.presupuestoPersonalSeleccionado != null)
                      Form(
                        key: _formKeyGastarPresupuestoFamiliar,
                        child: Column(
                          children: [
                            Text(
                              'Gastando de: ${gastosState.presupuestoPersonalSeleccionado!.categoria}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                                  montoGastoPresupuestoFamiliarController, // Usar el controlador local
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Monto a gastar de este presupuesto',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(),
                                hintText: 'Ej. 5000.00',
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
                                final presupuestoRestante =
                                    gastosState
                                        .presupuestoPersonalSeleccionado!
                                        .montoTotal; //- gastosState.presupuestoPersonalSeleccionado!.montoGastado; // Monto real disponible
                                if (monto > presupuestoRestante) {
                                  return 'Monto supera el disponible en el presupuesto';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                                  descripcionController, // Usar el controlador local
                              maxLength: 100,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Descripción del gasto',
                                prefixIcon: Icon(Icons.description),
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La descripción es requerida';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_formKeyGastarPresupuestoFamiliar
                                      .currentState!
                                      .validate()) {
                                    final currentContext = context;
                                    try {
                                      // Asegúrate de que el presupuesto seleccionado es de tipo PresupuestoPersonal y que los parámetros coincidan con la firma
                                      await gastosController
                                          .gastarDePresupuestoFamiliar(
                                            gastosState
                                                .presupuestoPersonalSeleccionado!,
                                            double.parse(
                                              montoGastoPresupuestoFamiliarController
                                                  .text
                                                  .replaceAll(',', '.'),
                                            ),
                                            descripcionController.text.trim(),
                                          );
                                      if (currentContext.mounted) {
                                        ScaffoldMessenger.of(
                                          currentContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Gasto de presupuesto familiar registrado en ${gastosState.presupuestoPersonalSeleccionado!.categoria}.',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        _clearAllControllers(); // Limpiar los controladores aquí
                                      }
                                    } catch (e) {
                                      if (currentContext.mounted) {
                                        ScaffoldMessenger.of(
                                          currentContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error al gastar de presupuesto familiar: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.send_to_mobile),
                                label: const Text(
                                  'Gastar de Presupuesto Familiar',
                                ),
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Extensión para oscurecer colores (para las tarjetas seleccionadas)
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
