import 'package:flutter/foundation.dart';
import 'package:wallet_safe/models/perfil.dart';
// ¡Quita esta línea! import 'package:wallet_safe/models/familia.dart'; // No se usará directamente aquí, pero es bueno tenerlo si aplica en otros lugares
import 'package:wallet_safe/models/ingresos.dart';
import 'package:wallet_safe/models/gastos.dart';
import 'package:wallet_safe/models/presupuesto_personal.dart';
import 'package:wallet_safe/models/presupuesto_familiar.dart';

@immutable
class Familia extends Perfil {
  // Propiedades específicas de Familia si las hay

  Familia({
    required super.id,
    required super.nombre,
    super.balance,
    super.cnIngresos,
    super.cnGastos,
    super.cnPresupuestosPersonales, // Los familiares pueden tener presupuestos personales
    super.cnPresupuestosFamiliares, // O si reciben presupuestos familiares asignados
  });

  // Implementación concreta de los métodos abstractos de Perfil
  @override
  void agregarIngreso(Ingreso ingreso) {
    debugPrint(
      'Familiar: Intentando agregar ingreso ${ingreso.monto}. Esta operación debe ser manejada por un Notifier que devuelva una nueva instancia.',
    );
  }

  @override
  void agregarGasto(Gasto gasto) {
    debugPrint(
      'Familiar: Intentando agregar gasto ${gasto.monto}. Esta operación debe ser manejada por un Notifier que devuelva una nueva instancia.',
    );
  }

  @override
  void agregarPresupuestoPersonal(PresupuestoPersonal presupuesto) {
    debugPrint(
      'Familiar: Intentando agregar presupuesto personal ${presupuesto.montoAsignado}. Esta operación debe ser manejada por un Notifier que devuelva una nueva instancia.',
    );
  }

  @override
  void agregarPresupuestoFamiliar(PresupuestoFamiliar presupuesto) {
    debugPrint(
      'Familiar: Intentando agregar presupuesto familiar ${presupuesto.montoAsignado}. Esta operación debe ser manejada por un Notifier que devuelva una nueva instancia.',
    );
  }

  @override
  Familia copyWith({
    int? id,
    String? nombre,
    double? balance,
    List<Ingreso>? cnIngresos,
    List<Gasto>? cnGastos,
    List<PresupuestoPersonal>? cnPresupuestosPersonales,
    List<PresupuestoFamiliar>? cnPresupuestosFamiliares,
  }) {
    return Familia(
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

  // ¡ELIMINA ESTE MÉTODO factory Familia.fromJson DE AQUÍ!
  // Ahora Perfil.fromJson se encarga de crear la instancia de Familia.
  /*
  factory Familia.fromJson(Map<String, dynamic> json) {
    final perfilData = json['perfil'] as Map<String, dynamic>?;

    if (perfilData == null) {
      throw ArgumentError(
        'JSON de perfil incompleto: falta la clave "perfil".',
      );
    }

    return Familia(
      id: perfilData['id'] as int,
      nombre: perfilData['nombre'] as String,
      // ... (resto de la lógica, que ya no es necesaria aquí)
    );
  }
  */
}
