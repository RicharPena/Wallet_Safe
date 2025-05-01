import 'package:flutter/material.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/views/tabs/home_tab.dart';
import 'package:wallet_safe/views/tabs/ingresos_tab.dart';
import 'package:wallet_safe/views/tabs/gastos_tab.dart';
import 'package:wallet_safe/views/tabs/estadisticas_tab.dart';
import 'package:wallet_safe/views/tabs/config_tab.dart';
import 'package:wallet_safe/widgets/barra_inferior.dart';

class HomePage extends StatelessWidget {
  final Cuenta cuenta;
  final Perfil perfil;

  HomePage({required this.cuenta, required this.perfil, super.key});
  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  Widget build(BuildContext context) {
    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: HomeTab(cuenta: cuenta, perfil: perfil),
          icon: Icons.home,
          title: 'Inicio',
          navigatorkey: _navigatorKeys[0],
        ),
        PersistentTabItem(
          tab: IngresosTab(),
          icon: Icons.savings, // ¡ícono tipo alcancía!
          title: 'Ingresos',
          navigatorkey: _navigatorKeys[1],
        ),
        PersistentTabItem(
          tab: GastosTab(),
          icon: Icons.money_off, // ícono que representa gasto
          title: 'Gastos',
          navigatorkey: _navigatorKeys[2],
        ),
        PersistentTabItem(
          tab: EstadisticasTab(),
          icon: Icons.bar_chart, // gráfico de barras
          title: 'Estadísticas',
          navigatorkey: _navigatorKeys[3],
        ),
        PersistentTabItem(
          tab: ConfiguracionTab(),
          icon: Icons.settings, // tuerca
          title: 'Ajustes',
          navigatorkey: _navigatorKeys[4],
        ),
      ],
    );
  }
}
