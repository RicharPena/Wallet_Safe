import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/controllers/familia_viewmodel.dart';
import 'package:wallet_safe/views/profiles.dart';
import 'package:wallet_safe/widgets/notificacion_presupuesto.dart';
import 'package:wallet_safe/providers/app_providers.dart'; // ¡Importa tus nuevos providers!

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
  HomePage({super.key});
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
      final currentPerfil = ref.read(perfilActivoProvider);
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
    // Observa el perfil activo a través del provider. Puede ser null al inicio.
    final Perfil? perfilActivo = ref.watch(perfilActivoProvider);
    // Observa la cuenta activa a través del provider. Puede ser null al inicio.
    final Cuenta? cuentaActiva = ref.watch(cuentaActivaProvider);

    debugPrint('HOME_PAGE: perfilActivo es null? ${perfilActivo == null}');
    debugPrint('HOME_PAGE: cuentaActiva es null? ${cuentaActiva == null}');

    // Si el perfil activo es null, muestra un CircularProgressIndicator o maneja el estado de carga
    if (perfilActivo == null || cuentaActiva == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                  // No es necesario un ProviderScope aquí si los providers son globales (StateNotifierProvider)
                  // pero si el diálogo necesita un ProviderScope adicional para otros fines, déjalo.
                  // Para este caso, lo quitaría ya que `ref` estará disponible si es un ConsumerWidget/StatefulWidget.
                  return NewFamilyBudgetDialog(
                    presupuestoFamiliar: presupuestoPendiente,
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
            onLogout: () {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ProfileViews()),
                (route) => false, // Elimina todas las rutas anteriores
              );
            },
          ),
          icon: Icons.home,
          title: 'Inicio',
          navigatorkey: widget._navigatorKeys[0],
        ),
        PersistentTabItem(
          tab: IngresosTab(),
          icon: Icons.savings,
          title: 'Ingresos',
          navigatorkey: widget._navigatorKeys[1],
        ),
        PersistentTabItem(
          tab: GastosTab(),
          icon: Icons.money_off,
          title: 'Gastos',
          navigatorkey: widget._navigatorKeys[2],
        ),
        PersistentTabItem(
          tab: EstadisticasTab(),
          icon: Icons.bar_chart,
          title: 'Estadísticas',
          navigatorkey: widget._navigatorKeys[3],
        ),
        PersistentTabItem(
          tab: ConfigTab(),
          icon: Icons.settings,
          title: 'Ajustes',
          navigatorkey: widget._navigatorKeys[4],
        ),
      ],
    );
  }
}
