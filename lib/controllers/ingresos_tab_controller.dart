import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/ingresos.dart';
import 'package:wallet_safe/models/titular.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';

class IngresosTabController with ChangeNotifier {
  final Cuenta cuenta;
  final Perfil perfil;

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

  // Listas de categorías (sin cambios, ya que no se relacionan directamente con el modelo Ingreso)
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

  // Simulador de ID para Ingresos y Presupuesto Personal (para propósitos de demostración)
  static int _nextIngresoId = 1;
  static int _nextPresupuestoPersonalId = 1; // Nuevo para presupuesto personal

  IngresosTabController({required this.cuenta, required this.perfil}) {
    categoriaIngresoSeleccionada = categoriasIngresosPersonales.first;
    categoriaPresupuestoPersonalSeleccionada =
        categoriasPresupuestoPersonal.first;
    categoriaPresupuestoFamiliarSeleccionada =
        categoriasPresupuestoFamiliar.first;
    perfil.addListener(notifyListeners);
  }

  // Setters para actualizar las propiedades y notificar cambios
  void setEsAutomatico(bool value) {
    _esAutomatico = value;
    notifyListeners();
  }

  void setTipoIngreso(String value) {
    _tipoIngreso = value;
    notifyListeners();
  }

  String? validateMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa un monto';
    }
    final monto = double.tryParse(value.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      return 'Monto inválido';
    }
    return null;
  }

  // --- Lógica para Guardar Ingreso Personal ---
  void guardarIngreso() {
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

    // Llama al método agregarIngreso del perfil, que se encargará del balance
    perfil.agregarIngreso(ingreso);

    // Puedes mantener esta llamada si tu clase Ingreso.registrarIngreso hace algo adicional (e.g., persistencia)
    Ingreso.registrarIngreso(
      id: ingreso.id,
      monto: ingreso.monto,
      descripcion: ingreso.descripcion,
      categoria: ingreso.categoria,
      tipo: ingreso.tipo,
      automatico: ingreso.automatico,
    );
    reset();
  }

  // --- Lógica para Crear Presupuesto Personal ---
  void crearPresupuestoPersonal() {
    final monto = double.parse(
      montoPresupuestoPersonalController.text.replaceAll(',', '.'),
    );
    final categoria = categoriaPresupuestoPersonalSeleccionada!;

    if (monto > perfil.balance) {
      throw Exception(
        'El monto del presupuesto personal excede el saldo disponible del perfil.',
      );
    }

    // Crea el objeto PresupuestoPersonal
    final nuevoPresupuestoPersonal = PresupuestoPersonal(
      id: _nextPresupuestoPersonalId++, // Asigna un ID simulado
      montoAsignado: monto,
      categoria: categoria,
      perfilId: perfil.id, // Asocia el presupuesto con el ID del perfil actual
    );

    // Llama al método agregarPresupuestoPersonal del perfil
    perfil.agregarPresupuestoPersonal(nuevoPresupuestoPersonal);

    // Opcional: Si quieres restar el monto del balance inmediatamente, pero tu Perfil.agregarPresupuestoPersonal no lo hace
    // Si la lógica es que el presupuesto personal es una "asignación" de tu propio dinero y esto reduce tu balance,
    // entonces deberías hacer `perfil.balance -= monto;` aquí o dentro de `perfil.agregarPresupuestoPersonal`.
    // Por la estructura de tus clases, asumo que `agregarPresupuestoPersonal` solo añade a la lista
    // y no afecta el balance directamente (es más una "categorización" de dinero).
    // Si necesitas que afecte el balance, indícamelo.

    reset();
  }

  // --- Lógica para Asignar Presupuesto Familiar ---
  void asignarPresupuestoFamiliar() {
    // Primero, asegurar que el perfil actual es un Titular
    if (perfil is! Titular) {
      throw Exception(
        'Solo el perfil Titular puede asignar presupuesto familiar.',
      );
    }

    final titular = perfil as Titular; // Castear de forma segura a Titular
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

    // Busca el perfil familiar por nombre en la lista de familiares del Titular
    // (Asegúrate de que `titular.familiares` esté disponible, si no, usa `cuenta.familiares`)
    // Asumo que `titular.familiares` es una lista de `Familia` en tu modelo `Titular`
    final Familia? perfilFamiliar = cuenta.familiares.firstWhereOrNull(
      // Debe ser de tipo Familia
      (f) => f.nombre == perfilFamiliarSeleccionadoNombre,
    );

    if (perfilFamiliar == null) {
      throw Exception('Perfil familiar no encontrado.');
    }

    // La validación del balance ya la hace Titular.asignarPresupuestoAFamilia,
    // pero podemos hacerla aquí también para feedback temprano en la UI
    if (monto > titular.balance) {
      throw Exception(
        'El monto del presupuesto familiar excede tu saldo disponible como Titular.',
      );
    }

    // Llama al método específico de Titular para asignar el presupuesto
    final bool asignado = titular.asignarPresupuestoAFamilia(
      perfilFamiliar,
      monto,
      categoria,
    );

    if (!asignado) {
      // Esto capturaría si el método interno de Titular.asignarPresupuestoAFamilia retorna false
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

    notifyListeners();
  }

  @override
  void dispose() {
    montoController.dispose();
    descripcionController.dispose();
    montoPresupuestoPersonalController.dispose();
    montoPresupuestoFamiliarController.dispose();
    perfil.removeListener(notifyListeners);
    super.dispose();
  }
}

// Extensión para List para `firstWhereOrNull`
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
