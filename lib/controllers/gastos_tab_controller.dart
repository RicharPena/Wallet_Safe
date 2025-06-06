import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/gastos.dart';

class GastosTabController {
  final TextEditingController montoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  final Cuenta cuenta;
  final Perfil perfil;

  GastosTabController({required this.cuenta, required this.perfil});

  bool esAutomatico = false;
  String tipoGasto = 'Fijo';
  String? categoriaSeleccionada = 'Alimentos';

  final List<String> categorias = [
    'Alimentos',
    'Transporte',
    'Entretenimiento',
    'Servicios',
    'Salud',
    'Educación',
  ];

  static int _contadorId = 0;

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
    final categoria = categoriaSeleccionada ?? 'Sin categoría';
    final tipo = esAutomatico ? tipoGasto : 'Fijo';

    Gasto.registrarGasto(
      id: _contadorId++,
      monto: monto,
      descripcion: descripcion,
      categoria: categoria,
      tipo: tipo,
      automatico: esAutomatico,
    );

    perfil.cnGastos.add(
      Gasto(
        id: _contadorId,
        monto: monto,
        fecha: DateTime.now(),
        descripcion: descripcion,
        tipo: tipo,
        automatico: esAutomatico,
      ),
    );
    perfil.balance -= monto;
  }

  void reset() {
    montoController.clear();
    descripcionController.clear();
    esAutomatico = false;
    tipoGasto = 'Fijo';
    categoriaSeleccionada = 'Alimentos';
  }

  void dispose() {
    montoController.dispose();
    descripcionController.dispose();
  }
}
