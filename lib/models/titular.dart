import 'package:flutter/foundation.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/familia.dart'; // No se usará directamente aquí, pero es bueno tenerlo si aplica en otros lugares
import 'package:wallet_safe/models/ingresos.dart';
import 'package:wallet_safe/models/gastos.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';
import 'package:wallet_safe/models/presupuesto_familiar.dart';

@immutable // Importante: marca la clase como inmutable
class Titular extends Perfil {
  Titular({
    required super.id,
    required super.nombre,
    super.balance,
    super.cnIngresos,
    super.cnGastos,
    super.cnPresupuestosPersonales,
    super.cnPresupuestosFamiliares,
  });

  // Métodos de acción (implementaciones concretas para Titular)
  // Como se indicó anteriormente, la lógica de mutación debe manejarse con copyWith
  // en el StateNotifier que gestiona este objeto inmutable.
  // Aquí solo se provee una implementación básica para satisfacer la interfaz abstracta.
  @override
  void agregarIngreso(Ingreso ingreso) {
    debugPrint(
      'Titular: Intentando agregar ingreso ${ingreso.monto}. Esta operación debe ser manejada por un Notifier que devuelva una nueva instancia.',
    );
  }

  @override
  void agregarGasto(Gasto gasto) {
    debugPrint(
      'Titular: Intentando agregar gasto ${gasto.monto}. Esta operación debe ser manejada por un Notifier que devuelva una nueva instancia.',
    );
  }

  @override
  void agregarPresupuestoPersonal(PresupuestoPersonal presupuesto) {
    debugPrint(
      'Titular: Intentando agregar presupuesto personal ${presupuesto.montoAsignado}. Esta operación debe ser manejada por un Notifier que devuelva una nueva instancia.',
    );
  }

  @override
  void agregarPresupuestoFamiliar(PresupuestoFamiliar presupuesto) {
    debugPrint(
      'Titular: Intentando agregar presupuesto familiar ${presupuesto.montoAsignado}. Esta operación debe ser manejada por un Notifier que devuelva una nueva instancia.',
    );
  }

  @override
  Titular copyWith({
    int? id,
    String? nombre,
    double? balance,
    List<Ingreso>? cnIngresos,
    List<Gasto>? cnGastos,
    List<PresupuestoPersonal>? cnPresupuestosPersonales,
    List<PresupuestoFamiliar>? cnPresupuestosFamiliares,
  }) {
    return Titular(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      balance: balance ?? this.balance,
      cnIngresos: cnIngresos ?? this.cnIngresos,
      cnGastos: cnGastos ?? this.cnGastos,
      cnPresupuestosPersonales:
          cnPresupuestosPersonales ?? this.cnPresupuestosPersonales,
      cnPresupuestosFamiliares:
          cnPresupuestosFamiliares ?? this.cnPresupuestosFamiliares,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ingresos': cnIngresos.map((i) => i.toJson()).toList(),
      'gastos': cnGastos.map((g) => g.toJson()).toList(),
      'presupuestos': cnPresupuestosFamiliares.map((p) => p.toJson()).toList(),
      'detalles_presupuesto':
          cnPresupuestosPersonales.map((p) => p.toJson()).toList(),
    };
  }
}
