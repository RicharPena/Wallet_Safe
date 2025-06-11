import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importar Riverpod
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/ingresos.dart';
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';

// Cambiamos 'with ChangeNotifier' por 'extends StateNotifier<bool>'
// El 'bool' aquí es solo un tipo de estado. Puedes usar void o un tipo más significativo
// si el controlador realmente tiene un estado booleano para notificar.
// Para controladores que solo notifican cambios a través de notifyListeners(),
// a veces se usa un tipo de estado 'void' o 'int' para un "dummy state".
// Para este caso, mantener un 'bool' o cambiar a 'void' está bien.
// Si no quieres manejar un 'state' explícito, puedes hacer que extienda StateNotifier<void>
// y solo usar `notifyListeners` (aunque en StateNotifier es `state = !state;` o similar
// para forzar una notificación si el estado es el mismo).
// Sin embargo, como ya usas ChangeNotifier, simplemente implementaremos StateNotifier de esa forma.

class IngresosTabController extends StateNotifier<bool> {
  // Cambiado aquí
  final Cuenta? cuenta;
  final Perfil? perfil;

  // TextEditingControllers
  final TextEditingController montoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController montoPresupuestoPersonalController =
      TextEditingController();
  final TextEditingController montoPresupuestoFamiliarController =
      TextEditingController();

  // Propiedades de estado para los Dropdowns y Switch
  String? categoriaIngresoSeleccionada;
  bool _esAutomatico = false;
  String _tipoIngreso = 'Fijo';

  // Getters para acceder a las propiedades privadas desde la UI
  bool get esAutomatico => _esAutomatico;
  String get tipoIngreso => _tipoIngreso;

  String? categoriaPresupuestoPersonalSeleccionada;
  String? categoriaPresupuestoFamiliarSeleccionada;
  String? perfilFamiliarSeleccionadoNombre;

  // Listas de categorías (sin cambios)
  final List<String> categoriasIngresosPersonales = [
    'Salario',
    'Freelance',
    'Inversiones',
    'Regalo',
    'Ventas',
    'Otros Ingresos',
  ];
  final List<String> categoriasPresupuestoPersonal = [
    'Alimentos',
    'Transporte',
    'Vivienda',
    'Servicios',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Ahorro',
    'Deudas',
    'Otros Gastos',
  ];
  final List<String> categoriasPresupuestoFamiliar = [
    'Comida Familiar',
    'Educación Hijos',
    'Salud Familiar',
    'Transporte Familiar',
    'Actividades Recreativas',
    'Regalos Familiares',
    'Mantenimiento del Hogar',
    'Otros Gastos Familiares',
  ];

  static int _nextIngresoId = 1;
  static int _nextPresupuestoPersonalId = 1;

  // Constructor
  IngresosTabController({this.cuenta, this.perfil}) : super(false) {
    // Llamar a super con un estado inicial
    if (perfil != null) {
      categoriaIngresoSeleccionada = categoriasIngresosPersonales.first;
      categoriaPresupuestoPersonalSeleccionada =
          categoriasPresupuestoPersonal.first;
      categoriaPresupuestoFamiliarSeleccionada =
          categoriasPresupuestoFamiliar.first;
    } else {
      categoriaIngresoSeleccionada = null;
      categoriaPresupuestoPersonalSeleccionada = null;
      categoriaPresupuestoFamiliarSeleccionada = null;
    }
    // Ya no necesitas perfil.addListener(notifyListeners); si extiendes StateNotifier
    // porque los cambios al `state` del StateNotifier o a propiedades observables
    // del perfil (si el perfil mismo es un ChangeNotifier) ya dispararán reconstrucciones
    // a través del ref.watch de Riverpod.
  }

  // Setters para actualizar las propiedades y notificar cambios
  // En StateNotifier, en lugar de notifyListeners(), se actualiza el 'state'.
  // Para un controlador que solo "notifica", puedes usar un dummy state como bool.
  void setEsAutomatico(bool value) {
    _esAutomatico = value;
    state = !state; // Cambia el estado para notificar a los oyentes
  }

  void setTipoIngreso(String value) {
    _tipoIngreso = value;
    state = !state;
  }

  void setCategoriaIngresoSeleccionada(String? value) {
    if (categoriaIngresoSeleccionada != value) {
      categoriaIngresoSeleccionada = value;
      state = !state;
    }
  }

  void setCategoriaPresupuestoPersonalSeleccionada(String? value) {
    if (categoriaPresupuestoPersonalSeleccionada != value) {
      categoriaPresupuestoPersonalSeleccionada = value;
      state = !state;
    }
  }

  void setPerfilFamiliarSeleccionadoNombre(String? value) {
    if (perfilFamiliarSeleccionadoNombre != value) {
      perfilFamiliarSeleccionadoNombre = value;
      state = !state;
    }
  }

  void setCategoriaPresupuestoFamiliarSeleccionada(String? value) {
    if (categoriaPresupuestoFamiliarSeleccionada != value) {
      categoriaPresupuestoFamiliarSeleccionada = value;
      state = !state;
    }
  }

  String? validateMonto(String? value) {
    // ... tu lógica de validación ...
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa un monto';
    }
    final monto = double.tryParse(value.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      return 'Monto inválido';
    }
    return null;
  }

  void guardarIngreso() {
    if (perfil == null) {
      print('Error: Perfil no disponible para guardar ingreso.');
      return;
    }
    final monto = double.parse(montoController.text.replaceAll(',', '.'));
    final descripcion = descripcionController.text;
    final categoria = categoriaIngresoSeleccionada!;

    final ingreso = Ingreso(
      id: _nextIngresoId++,
      monto: monto,
      descripcion: descripcion,
      fecha: DateTime.now(),
      categoria: categoria,
      tipo: _esAutomatico ? _tipoIngreso : 'Único',
      automatico: _esAutomatico,
    );

    perfil!.agregarIngreso(
      ingreso,
    ); // Esto debería notificar al perfil y por ende a los observadores
    Ingreso.registrarIngreso(
      // Esto es para persistencia o lógica externa
      id: ingreso.id,
      monto: ingreso.monto,
      descripcion: ingreso.descripcion,
      categoria: ingreso.categoria,
      tipo: ingreso.tipo,
      automatico: ingreso.automatico,
    );
    reset();
  }

  void crearPresupuestoPersonal() {
    if (perfil == null) {
      print('Error: Perfil no disponible para guardar ingreso.');
      return;
    }
    final monto = double.parse(
      montoPresupuestoPersonalController.text.replaceAll(',', '.'),
    );
    final categoria = categoriaPresupuestoPersonalSeleccionada!;

    if (monto > perfil!.balance) {
      throw Exception(
        'El monto del presupuesto personal excede el saldo disponible del perfil.',
      );
    }

    final nuevoPresupuestoPersonal = PresupuestoPersonal(
      id: _nextPresupuestoPersonalId++,
      montoAsignado: monto,
      categoria: categoria,
      perfilId: perfil!.id,
    );

    perfil!.agregarPresupuestoPersonal(nuevoPresupuestoPersonal);
    reset();
  }

  void asignarPresupuestoFamiliar() {
    if (perfil == null || cuenta == null) {
      print(
        'Error: Cuenta o Perfil no disponibles para asignar presupuesto familiar.',
      );
      return;
    }

    if (perfil is! Titular) {
      throw Exception(
        'Solo el perfil Titular puede asignar presupuesto familiar.',
      );
    }

    final titular = perfil as Titular;
    final monto = double.parse(
      montoPresupuestoFamiliarController.text.replaceAll(',', '.'),
    );
    final categoria = categoriaPresupuestoFamiliarSeleccionada!;

    if (perfilFamiliarSeleccionadoNombre == null ||
        perfilFamiliarSeleccionadoNombre!.isEmpty) {
      throw Exception(
        'Debes seleccionar un perfil familiar para asignar el presupuesto.',
      );
    }

    final Familia? perfilFamiliar = cuenta!.familiares.firstWhereOrNull(
      (f) => f.nombre == perfilFamiliarSeleccionadoNombre,
    );

    if (perfilFamiliar == null) {
      throw Exception('Perfil familiar no encontrado.');
    }

    if (monto > titular.balance) {
      throw Exception(
        'El monto del presupuesto familiar excede tu saldo disponible como Titular.',
      );
    }

    final bool asignado = titular.asignarPresupuestoAFamilia(
      perfilFamiliar,
      monto,
      categoria,
    );

    if (!asignado) {
      throw Exception(
        'No se pudo asignar el presupuesto familiar. Verifica el monto o el familiar.',
      );
    }
    reset();
  }

  void reset() {
    montoController.clear();
    descripcionController.clear();
    montoPresupuestoPersonalController.clear();
    montoPresupuestoFamiliarController.clear();

    categoriaIngresoSeleccionada = categoriasIngresosPersonales.first;
    _esAutomatico = false;
    _tipoIngreso = 'Fijo';
    categoriaPresupuestoPersonalSeleccionada =
        categoriasPresupuestoPersonal.first;
    categoriaPresupuestoFamiliarSeleccionada =
        categoriasPresupuestoFamiliar.first;
    perfilFamiliarSeleccionadoNombre = null;

    state =
        !state; // Notifica que el estado interno del controlador ha cambiado
  }

  @override
  void dispose() {
    montoController.dispose();
    descripcionController.dispose();
    montoPresupuestoPersonalController.dispose();
    montoPresupuestoFamiliarController.dispose();
    // No necesitas perfil.removeListener(notifyListeners) si usas StateNotifier.
    super.dispose(); // Llama a super.dispose() para StateNotifier
  }
}

// Extensión para List para `firstWhereOrNull` (la mantienes)
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
