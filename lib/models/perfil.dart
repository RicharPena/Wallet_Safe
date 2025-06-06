import 'ingresos.dart';
import 'gastos.dart';

abstract class Perfil {
  final int id;
  final String nombre;
  double balance;
  final List<Ingreso> cnIngresos;
  final List<Gasto> cnGastos;

  Perfil({
    required this.id,
    required this.nombre,
    this.balance = 0.0,
    List<Ingreso>? cnIngresos,
    List<Gasto>? cnGastos,
  }) : cnIngresos = cnIngresos ?? [],
       cnGastos = cnGastos ?? [];
}
