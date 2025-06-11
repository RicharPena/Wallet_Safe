import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/gastos.dart';

// Extiende o mezcla con ChangeNotifier para permitir la notificación de cambios
class GastosTabController with ChangeNotifier {
  final TextEditingController montoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  final Cuenta? cuenta;
  final Perfil? perfil;

  // Propiedades privadas con getters para mantener el control y notificar cambios
  bool _esAutomatico = false;
  String _tipoGasto = 'Fijo';
  String? _categoriaSeleccionada;

  // Getters públicos para acceder a las propiedades
  bool get esAutomatico => _esAutomatico;
  String get tipoGasto => _tipoGasto;
  String? get categoriaSeleccionada => _categoriaSeleccionada;

  final List<String> categorias = [
    'Alimentos',
    'Transporte',
    'Entretenimiento',
    'Servicios',
    'Salud',
    'Educación',
  ];

  static int _contadorId = 0; // Usado para simular IDs

  GastosTabController({required this.cuenta, required this.perfil}) {
    // Inicializa la categoría seleccionada al crear el controlador
    _categoriaSeleccionada = categorias.isNotEmpty ? categorias.first : null;
    // Escucha los cambios en el perfil para que el controlador se reconstruya si el perfil cambia
    perfil?.addListener(notifyListeners);
  }

  // --- Setters para actualizar el estado y notificar a los listeners ---
  void setEsAutomatico(bool value) {
    if (_esAutomatico != value) {
      // Solo notifica si el valor cambia
      _esAutomatico = value;
      notifyListeners();
    }
  }

  void setTipoGasto(String value) {
    if (_tipoGasto != value) {
      // Solo notifica si el valor cambia
      _tipoGasto = value;
      notifyListeners();
    }
  }

  void setCategoriaSeleccionada(String? value) {
    if (_categoriaSeleccionada != value) {
      // Solo notifica si el valor cambia
      _categoriaSeleccionada = value;
      notifyListeners();
    }
  }
  // -------------------------------------------------------------------

  String? validateMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'El monto es requerido';
    }

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return 'Ingrese un monto válido';
    }

    return null;
  }

  void guardarGasto() {
    final monto =
        double.tryParse(montoController.text.replaceAll(',', '.')) ?? 0.0;
    final descripcion = descripcionController.text.trim();
    final categoria = _categoriaSeleccionada ?? 'Sin categoría';
    final tipo = _esAutomatico ? _tipoGasto : 'Fijo';

    // Incrementa el ID una vez y úsalo consistentemente
    _contadorId++;
    final nuevoId = _contadorId;

    Gasto.registrarGasto(
      id: nuevoId,
      monto: monto,
      descripcion: descripcion,
      categoria: categoria,
      tipo: tipo,
      automatico: _esAutomatico,
    );

    final nuevoGasto = Gasto(
      id: nuevoId, // Usa el mismo ID
      monto: monto,
      fecha: DateTime.now(),
      descripcion: descripcion,
      tipo: tipo,
      automatico: _esAutomatico,
      categoria: categoria, // ¡Asegúrate de agregar la categoría aquí!
    );

    perfil?.cnGastos.add(nuevoGasto);
    perfil?.balance -= monto;

    // Llama a notifyListeners() para notificar a la UI (ej. HomeTab si muestra el balance)
    // El perfil ya llama a notifyListeners si es un ChangeNotifier, pero un notifyListeners()
    // aquí asegura que cualquier widget que observe directamente a GastosTabController también se reconstruya
    notifyListeners();
    reset(); // Resetear el formulario después de guardar
  }

  void reset() {
    montoController.clear();
    descripcionController.clear();
    _esAutomatico = false;
    _tipoGasto = 'Fijo';
    _categoriaSeleccionada =
        categorias.first; // Asegura que se reinicie al primer elemento
    notifyListeners(); // Notifica que el estado ha sido reiniciado
  }

  @override
  void dispose() {
    montoController.dispose();
    descripcionController.dispose();
    // Elimina el listener para evitar fugas de memoria
    perfil?.removeListener(notifyListeners);
    super.dispose(); // Llama al dispose del ChangeNotifier
  }
}
