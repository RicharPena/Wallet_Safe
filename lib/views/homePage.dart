import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/controllers/familia_viewmodel.dart';
import 'package:wallet_safe/widgets/notificacion_presupuesto.dart';
import 'package:wallet_safe/providers/app_providers.dart'; // ¡Importa tus nuevos providers!

import 'package:wallet_safe/views/profiles.dart';
import 'package:wallet_safe/views/tabs/home_tab.dart';
import 'package:wallet_safe/views/tabs/ingresos_tab.dart';
import 'package:wallet_safe/views/tabs/gastos_tab.dart';
import 'package:wallet_safe/views/tabs/estadisticas_tab.dart';
import 'package:wallet_safe/views/tabs/config_tab.dart';
import 'package:wallet_safe/widgets/barra_inferior.dart';

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class HomePage extends ConsumerStatefulWidget {
  final Cuenta cuenta; // Todavía la recibimos, pero podemos usar el provider.
  final Perfil perfil; // Todavía la recibimos, pero podemos usar el provider.

  HomePage({required this.cuenta, required this.perfil, super.key});
  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _dialogShownForThisBudget = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usamos el perfilSeleccionadoProvider para asegurar que estamos cargando el perfil correcto
      final currentPerfil = ref.read(perfilSeleccionadoProvider);
      if (currentPerfil is Familia) {
        ref
            .read(familiaViewModelProvider.notifier)
            .cargarFamilia(currentPerfil);
        _dialogShownForThisBudget = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Observa el perfil activo a través del provider.
    final Perfil perfilActivo = ref.watch(perfilSeleccionadoProvider);

    // Solo si el perfil actual es de tipo Familia, escuchamos el ViewModel para diálogos.
    if (perfilActivo is Familia) {
      ref.listen<Familia?>(familiaViewModelProvider, (
        previousFamilia,
        currentFamilia,
      ) {
        if (currentFamilia is Familia &&
            currentFamilia.id ==
                perfilActivo.id && // Compara con el perfil activo del provider
            !_dialogShownForThisBudget) {
          final presupuestoPendiente = currentFamilia.cnPresupuestosFamiliares
              .firstWhereOrNull((pf) => !pf.distribuido);

          if (presupuestoPendiente != null) {
            bool isDialogShowing = false;
            // Verifica si un diálogo ya está abierto (esto es una mejora de robustez)
            Navigator.of(context).popUntil((route) {
              if (route is PopupRoute &&
                  route.settings.name == 'new_budget_dialog') {
                isDialogShowing = true;
              }
              return true;
            });

            if (!isDialogShowing) {
              _dialogShownForThisBudget = true;
              showDialog(
                context: context,
                barrierDismissible: false,
                routeSettings: const RouteSettings(name: 'new_budget_dialog'),
                builder: (BuildContext dialogContext) {
                  // Envuelve el NewFamilyBudgetDialog con un ProviderScope
                  // para asegurar que herede los providers de HomePage
                  return ProviderScope(
                    parent: ProviderScope.containerOf(
                      context,
                    ), // Opcional pero seguro: hereda del padre
                    child: NewFamilyBudgetDialog(
                      presupuestoFamiliar: presupuestoPendiente,
                    ),
                  );
                },
              ).then((_) {
                _dialogShownForThisBudget =
                    false; // Resetear el flag al cerrar el diálogo
              });
            }
          }
        }
      });
    }

    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: HomeTab(
            cuenta: widget.cuenta,
            perfil: widget.perfil,
            onLogout: () {
              // Si el logout significa volver al login,
              // debes asegurarte de que los providers de cuenta/perfil se reinicien.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder:
                      (_) => ProfileViews(
                        cuenta: widget.cuenta,
                      ), // Vuelve al LoginView
                ),
                (route) => false,
              );
            },
          ),
          icon: Icons.home,
          title: 'Inicio',
          navigatorkey: widget._navigatorKeys[0],
        ),
        PersistentTabItem(
          tab: IngresosTab(cuenta: widget.cuenta, perfil: widget.perfil),
          icon: Icons.savings,
          title: 'Ingresos',
          navigatorkey: widget._navigatorKeys[1],
        ),
        PersistentTabItem(
          tab: GastosTab(cuenta: widget.cuenta, perfil: widget.perfil),
          icon: Icons.money_off,
          title: 'Gastos',
          navigatorkey: widget._navigatorKeys[2],
        ),
        PersistentTabItem(
          tab: EstadisticasTab(perfil: widget.perfil),
          icon: Icons.bar_chart,
          title: 'Estadísticas',
          navigatorkey: widget._navigatorKeys[3],
        ),
        PersistentTabItem(
          tab: ConfigTab(cuenta: widget.cuenta),
          icon: Icons.settings,
          title: 'Ajustes',
          navigatorkey: widget._navigatorKeys[4],
        ),
      ],
    );
  }
}
