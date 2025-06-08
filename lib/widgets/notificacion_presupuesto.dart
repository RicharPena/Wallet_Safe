import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/presupuesto_familiar.dart';
import '../controllers/familia_viewmodel.dart'; // Importa tu ViewModel

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

  List<TextEditingController> _montoControllers = [];
  List<TextEditingController> _categoriaControllers = [];

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
          content: Text('Ya has distribuido todo el monto disponible.'),
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
      double montoRemovido = _subdivisiones[index]['monto'] as double;
      _subdivisiones.removeAt(index);
      _montoControllers[index].dispose();
      _categoriaControllers[index].dispose();
      _montoControllers.removeAt(index);
      _categoriaControllers.removeAt(index);

      _montoRestante += montoRemovido;
      _calcularMontoRestante(); // Recalcular al remover
    });
  }

  void _calcularMontoRestante() {
    double totalIngresado = 0.0;
    for (var i = 0; i < _subdivisiones.length; i++) {
      try {
        double monto = double.parse(_montoControllers[i].text);
        totalIngresado += monto;
        _subdivisiones[i]['monto'] = monto;
      } catch (e) {
        // Ignorar si el campo está vacío o no es un número válido por ahora
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

    if (_montoRestante.abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El monto total de las subdivisiones no coincide con el presupuesto original.',
          ),
        ),
      );
      return;
    }

    final familiaViewModel = ref.read(familiaViewModelProvider.notifier);

    familiaViewModel.procesarPresupuestoFamiliar(
      widget.presupuestoFamiliar,
      _subdivisiones,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          false, // Evita que el diálogo se cierre al presionar el botón de atrás
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
                    color: _montoRestante < 0 ? Colors.red : Colors.green,
                  ),
                ),
                const Divider(),
                ..._subdivisiones.asMap().entries.map((entry) {
                  int index = entry.key;
                  // Map<String, dynamic> sub = entry.value; // No usado directamente aquí

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _montoControllers[index],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monto Personal',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese un monto';
                              }
                              final monto = double.tryParse(value);
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
                                // Actualizar el valor en el controlador y también en la lista de subdivisiones
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
                        if (_subdivisiones.length >
                            1) // Permitir remover solo si hay más de una subdivisión
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
