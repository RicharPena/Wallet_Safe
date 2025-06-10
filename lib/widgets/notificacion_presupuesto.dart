import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/presupuesto_familiar.dart';
import '../controllers/familia_viewmodel.dart';
import '../models/familia.dart'; // Necesario para el casting
import '../providers/app_providers.dart'; // ¡Importa tus nuevos providers!

// Extensión para List para firstWhereOrNull (si no la tienes ya)
extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

class NewFamilyBudgetDialog extends ConsumerStatefulWidget {
  final PresupuestoFamiliar presupuestoFamiliar;

  const NewFamilyBudgetDialog({Key? key, required this.presupuestoFamiliar})
    : super(key: key);

  @override
  ConsumerState<NewFamilyBudgetDialog> createState() =>
      _NewFamilyBudgetDialogState();
}

class _NewFamilyBudgetDialogState extends ConsumerState<NewFamilyBudgetDialog> {
  List<Map<String, dynamic>> _subdivisiones = [];
  double _montoRestante = 0.0;
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _montoControllers = [];
  final List<TextEditingController> _categoriaControllers = [];

  final List<String> _categoriasDisponibles = [
    'Comida',
    'Transporte',
    'Vivienda',
    'Estudios',
    'Entretenimiento',
    'Salud',
    'Ropa',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _montoRestante = widget.presupuestoFamiliar.montoAsignado;
    _agregarSubdivision();
  }

  @override
  void dispose() {
    for (var controller in _montoControllers) {
      controller.dispose();
    }
    for (var controller in _categoriaControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _agregarSubdivision() {
    if (_montoRestante <= 0 && _subdivisiones.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ya has distribuido todo el monto disponible o no hay más monto para subdividir.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _subdivisiones.add({
        'monto': 0.0,
        'categoria': _categoriasDisponibles.first,
      });
      _montoControllers.add(TextEditingController());
      _categoriaControllers.add(
        TextEditingController(text: _categoriasDisponibles.first),
      );
    });
  }

  void _removerSubdivision(int index) {
    setState(() {
      double montoRemovido = 0.0;
      try {
        montoRemovido = double.parse(
          _montoControllers[index].text.replaceAll(',', '.'),
        );
      } catch (e) {
        // Si no se puede parsear, asumir 0
      }

      _subdivisiones.removeAt(index);
      _montoControllers[index].dispose();
      _categoriaControllers[index].dispose();
      _montoControllers.removeAt(index);
      _categoriaControllers.removeAt(index);

      _montoRestante += montoRemovido;
      _calcularMontoRestante();
    });
  }

  void _calcularMontoRestante() {
    double totalIngresado = 0.0;
    for (var i = 0; i < _subdivisiones.length; i++) {
      try {
        double monto = double.parse(
          _montoControllers[i].text.replaceAll(',', '.'),
        );
        totalIngresado += monto;
        _subdivisiones[i]['monto'] = monto;
      } catch (e) {
        // Si el campo está vacío o no es un número válido, no suma nada.
      }
    }
    setState(() {
      _montoRestante =
          widget.presupuestoFamiliar.montoAsignado - totalIngresado;
    });
  }

  void _confirmarDistribucion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _calcularMontoRestante();

    if (_montoRestante.abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El monto total de las subdivisiones no coincide con el presupuesto original. Asegúrate de distribuir todo el monto.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // AHORA OBTENEMOS LA CUENTA Y EL PERFIL (Familia) DESDE LOS PROVIDERS
    final familiaObjetivo =
        ref.read(perfilSeleccionadoProvider)
            as Familia; // Aseguramos que es Familia

    // Validar que la familiaObjetivo sea la misma que la del presupuesto familiar
    if (familiaObjetivo.id != widget.presupuestoFamiliar.idPerfilFamiliar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: El perfil activo no coincide con el perfil del presupuesto familiar.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final familiaViewModel = ref.read(familiaViewModelProvider.notifier);

    try {
      // Como el perfilSeleccionadoProvider ya nos da la instancia correcta de Familia,
      // el ViewModel ya debería estar escuchando y tener esa instancia.
      // Ya no es necesario llamar familiaViewModel.cargarFamilia(familiaObjetivo) aquí,
      // ya que HomePage.initState() y el listener ya se encargan.
      // Sin embargo, si quieres ser súper explícito y asegurarte, podrías hacerlo:
      // familiaViewModel.cargarFamilia(familiaObjetivo);

      familiaViewModel.procesarPresupuestoFamiliar(
        widget.presupuestoFamiliar,
        _subdivisiones,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presupuesto familiar distribuido exitosamente.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al distribuir presupuesto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('¡Nuevo Presupuesto Familiar Asignado!'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: ListBody(
              children: <Widget>[
                Text(
                  'Se te ha asignado un presupuesto de \$${widget.presupuestoFamiliar.montoAsignado.toStringAsFixed(2)} '
                  'para la categoría "${widget.presupuestoFamiliar.categoria}".',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Monto restante para distribuir: \$${_montoRestante.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        _montoRestante < 0
                            ? Colors.red
                            : (_montoRestante == 0
                                ? Colors.green
                                : Colors.orange),
                  ),
                ),
                const Divider(),
                ..._subdivisiones.asMap().entries.map((entry) {
                  int index = entry.key;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _montoControllers[index],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Monto Personal',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese un monto';
                              }
                              final monto = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
                              if (monto == null || monto <= 0) {
                                return 'Monto inválido';
                              }
                              return null;
                            },
                            onChanged: (_) => _calcularMontoRestante(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value:
                                _categoriaControllers[index].text.isEmpty
                                    ? _categoriasDisponibles.first
                                    : _categoriaControllers[index].text,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                _categoriasDisponibles.map((String categoria) {
                                  return DropdownMenuItem<String>(
                                    value: categoria,
                                    child: Text(categoria),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _categoriaControllers[index].text = newValue!;
                                _subdivisiones[index]['categoria'] = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Seleccione una categoría';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_subdivisiones.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () => _removerSubdivision(index),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _agregarSubdivision,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar otra subdivisión'),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _confirmarDistribucion,
            child: const Text('Confirmar Distribución'),
          ),
        ],
      ),
    );
  }
}
