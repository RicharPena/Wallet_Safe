import 'gastos.dart';
import 'ingresos.dart';
import 'presupuesto_personal.dart'; // Importa la nueva clase
import 'presupuesto_familiar.dart'; // Importa la nueva clase

abstract class Perfil {
  final int id;
  final String nombre;
  double balance;
  final List<Ingreso> cnIngresos;
  final List<Gasto> cnGastos;
  final List<PresupuestoPersonal> cnPresupuestosPersonales;
  final List<PresupuestoFamiliar> cnPresupuestosFamiliares;

  Perfil({
    required this.id,
    required this.nombre,
    this.balance = 0.0,
    List<Ingreso>? cnIngresos,
    List<Gasto>? cnGastos,
    List<PresupuestoPersonal>? cnPresupuestosPersonales,
    List<PresupuestoFamiliar>? cnPresupuestosFamiliares,
  }) : cnIngresos = cnIngresos ?? [],
       cnGastos = cnGastos ?? [],
       cnPresupuestosPersonales = cnPresupuestosPersonales ?? [],
       cnPresupuestosFamiliares = cnPresupuestosFamiliares ?? [];

  void agregarPresupuestoPersonal(PresupuestoPersonal presupuesto);
  void agregarPresupuestoFamiliar(PresupuestoFamiliar presupuesto);
}
