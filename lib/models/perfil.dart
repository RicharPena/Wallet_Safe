import 'ingresos.dart';
import 'gastos.dart';

abstract class Perfil {
  final int id;
  final String nombre;
  double presupuestoFamiliar;
  final List<Ingreso> cnIngresos;
  final List<Gasto> cnGastos;

  Perfil({
    required this.id,
    required this.nombre,
    this.presupuestoFamiliar = 0.0,
    List<Ingreso>? cnIngresos,
    List<Gasto>? cnGastos,
  }) : cnIngresos = cnIngresos ?? [],
       cnGastos = cnGastos ?? [];
}
