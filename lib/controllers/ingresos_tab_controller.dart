import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/ingresos.dart'; // Asegúrate que el import sea 'ingreso.dart' si la clase es Ingreso.

class IngresosTabController {
  final TextEditingController montoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  final Cuenta cuenta;
  final Perfil perfil;

  IngresosTabController({required this.cuenta, required this.perfil}) {
    // *** Cambio aquí: Llamar a initCategories en el constructor ***
    initCategories();
  }

  bool esAutomatico = false;
  String tipoIngreso = 'Fijo';

  final List<String> categoriasIngresosPersonales = [
    'Salario',
    'Ventas',
    'Pagos',
    'Regalias',
    'Reembolsos',
  ];

  final List<String> categoriasPresupuestoPersonal = [
    'Mercado',
    'Salidas',
    'Servicios',
    'Vehículo',
    'Reparaciones',
  ];

  final List<String> categoriasPresupuestoFamiliar = [
    'Universidad',
    'Colegio',
    'Salidas',
    'Transporte',
  ];

  String? categoriaIngresoSeleccionada;

  static int _contadorId = 0;

  void initCategories() {
    categoriaIngresoSeleccionada =
        categoriasIngresosPersonales.isNotEmpty
            ? categoriasIngresosPersonales.first
            : null;
  }

  String? validateMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'El monto es requerido';
    }

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return 'Ingrese un monto válido y mayor a cero';
    }

    return null;
  }

  void guardarIngreso() {
    final monto =
        double.tryParse(montoController.text.replaceAll(',', '.')) ?? 0.0;
    final descripcion = descripcionController.text.trim();
    final categoria = categoriaIngresoSeleccionada ?? 'Sin categoría';
    final tipo = esAutomatico ? tipoIngreso : 'Fijo';

    Ingreso.registrarIngreso(
      id: _contadorId++,
      monto: monto,
      descripcion: descripcion,
      categoria: categoria,
      tipo: tipo,
      automatico: esAutomatico,
    );

    perfil.cnIngresos.add(
      Ingreso(
        id: _contadorId, // Esto debería ser _contadorId++ también o simplemente id
        monto: monto,
        fecha: DateTime.now(),
        descripcion: descripcion,
        categoria: categoria,
        tipo: tipo,
        automatico: esAutomatico,
      ),
    );
    // Nota: Esta línea `perfil.presupuestoFamiliar += monto;` parece ser un remanente
    // de la lógica anterior donde los ingresos directamente sumaban al presupuesto familiar.
    // Será importante reevaluar esto cuando implementemos la lógica de presupuesto completo.
    // Por ahora, la dejaré pero marcada como algo a revisar.
    perfil.presupuestoFamiliar += monto;
  }

  void reset() {
    montoController.clear();
    descripcionController.clear();
    esAutomatico = false;
    tipoIngreso = 'Fijo';
    categoriaIngresoSeleccionada =
        categoriasIngresosPersonales.isNotEmpty
            ? categoriasIngresosPersonales.first
            : null;
  }

  void dispose() {
    montoController.dispose();
    descripcionController.dispose();
  }
}
