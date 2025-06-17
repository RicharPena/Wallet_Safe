import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wallet_safe/models/familia.dart'; // Asegúrate de importar Familia
import 'package:wallet_safe/models/titular.dart'; // Asegúrate de importar Titular

import 'gastos.dart';
import 'ingresos.dart';
import 'presupuesto_personal.dart';
import 'presupuesto_familiar.dart';

@immutable
abstract class Perfil {
  final int id;
  final String nombre;
  final double balance;
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
  }) : cnIngresos = cnIngresos ?? const [],
       cnGastos = cnGastos ?? const [],
       cnPresupuestosPersonales = cnPresupuestosPersonales ?? const [],
       cnPresupuestosFamiliares = cnPresupuestosFamiliares ?? const [];

  // ¡ESTE ES EL CONSTRUCTOR fromJson CORREGIDO PARA LA CLASE BASE Perfil!
  factory Perfil.fromJson(Map<String, dynamic> json) {
    final int id = json['id'] as int;
    final String nombre = json['nombre'] as String;
    final double balance = double.parse(json['balance'].toString());
    final int? esTitular =
        json['titular'] as int?; // Ahora sí se busca dentro de perfilData

    // 2. Extraer las listas de la raíz del JSON principal
    // Estas listas SÍ están en la raíz, NO dentro de 'perfilData'
    final List<Ingreso> cnIngresos =
        (json['ingresos'] as List<dynamic>?)
            ?.map((e) => Ingreso.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final List<Gasto> cnGastos =
        (json['gastos'] as List<dynamic>?)
            ?.map((e) => Gasto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final List<PresupuestoFamiliar> cnPresupuestosFamiliares =
        (json['presupuestos']
                as List<dynamic>?) // La clave en tu JSON es 'presupuestos'
            ?.map(
              (e) => PresupuestoFamiliar.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];
    final List<PresupuestoPersonal> cnPresupuestosPersonales =
        (json['detalles_presupuesto']
                as List<
                  dynamic
                >?) // La clave en tu JSON es 'detalles_presupuesto'
            ?.map(
              (e) => PresupuestoPersonal.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];

    // 3. Decidir qué subclase instanciar y pasarle todos los datos
    if (esTitular == 1) {
      return Titular(
        id: id,
        nombre: nombre,
        balance: balance,
        cnIngresos: cnIngresos,
        cnGastos: cnGastos,
        cnPresupuestosPersonales: cnPresupuestosPersonales,
        cnPresupuestosFamiliares: cnPresupuestosFamiliares,
      );
    } else if (esTitular == 0) {
      return Familia(
        id: id,
        nombre: nombre,
        balance: balance,
        cnIngresos: cnIngresos,
        cnGastos: cnGastos,
        cnPresupuestosPersonales: cnPresupuestosPersonales,
        cnPresupuestosFamiliares: cnPresupuestosFamiliares,
      );
    } else {
      throw ArgumentError(
        'Tipo de perfil desconocido o valor de "titular" inválido: $esTitular',
      );
    }
  }

  Map<String, dynamic> toJson();

  Perfil copyWith({
    int? id,
    String? nombre,
    double? balance,
    List<Ingreso>? cnIngresos,
    List<Gasto>? cnGastos,
    List<PresupuestoPersonal>? cnPresupuestosPersonales,
    List<PresupuestoFamiliar>? cnPresupuestosFamiliares,
  });

  void agregarIngreso(Ingreso ingreso);
  void agregarGasto(Gasto gasto);
  void agregarPresupuestoPersonal(PresupuestoPersonal presupuesto);
  void agregarPresupuestoFamiliar(PresupuestoFamiliar presupuesto);
}
