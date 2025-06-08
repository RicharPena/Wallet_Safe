import 'package:flutter/material.dart';
import 'gastos.dart';
import 'ingresos.dart';
import 'presupuesto_personal.dart'; // Importa la nueva clase
import 'presupuesto_familiar.dart'; // Importa la nueva clase

abstract class Perfil extends ChangeNotifier {
  final int id;
  final String nombre;
  double _balance = 0.0;
  final List<Ingreso> cnIngresos;
  final List<Gasto> cnGastos;
  final List<PresupuestoPersonal> cnPresupuestosPersonales;
  final List<PresupuestoFamiliar> cnPresupuestosFamiliares;

  Perfil({
    required this.id,
    required this.nombre,
    double balance = 0.0,
    List<Ingreso>? cnIngresos,
    List<Gasto>? cnGastos,
    List<PresupuestoPersonal>? cnPresupuestosPersonales,
    List<PresupuestoFamiliar>? cnPresupuestosFamiliares,
  }) : cnIngresos = cnIngresos ?? [],
       cnGastos = cnGastos ?? [],
       cnPresupuestosPersonales = cnPresupuestosPersonales ?? [],
       cnPresupuestosFamiliares = cnPresupuestosFamiliares ?? [];

  double get balance => _balance;
  set balance(double newBalance) {
    if (_balance != newBalance) {
      // Solo notificar si hay un cambio real
      _balance = newBalance;
      notifyListeners(); // Notifica a los listeners del Perfil
    }
  }

  void agregarIngreso(Ingreso ingreso);

  void agregarPresupuestoPersonal(PresupuestoPersonal presupuesto);
  void agregarPresupuestoFamiliar(PresupuestoFamiliar presupuesto);
}
