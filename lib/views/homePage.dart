import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/familia.dart';
import 'package:wallet_safe/controllers/familia_viewmodel.dart';
import 'package:wallet_safe/views/profiles.dart';
import 'package:wallet_safe/widgets/notificacion_presupuesto.dart';
import 'package:wallet_safe/providers/app_providers.dart';

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
      // Leemos el Perfil activo
      final Perfil? currentPerfil = ref.read(perfilActivoProvider);

      if (currentPerfil is Familia) {
        // Aseguramos que el ViewModel esté cargado con los datos de la familia activa
        final familiaViewModel = ref.read(familiaViewModelProvider.notifier);
        familiaViewModel.cargarFamilia(currentPerfil);

        // Realizamos la comprobación inmediata de presupuestos pendientes
        _checkForPendingFamilyBudget(familiaViewModel);
      }
    });
  }

  // Método auxiliar para encapsular la lógica del diálogo
  void _checkForPendingFamilyBudget(FamiliaViewModel familiaViewModel) {
    // Si el diálogo ya se mostró, no lo mostramos de nuevo
    if (_dialogShownForThisBudget) return;

    // Obtenemos el primer presupuesto familiar no distribuido
    final presupuestoPendiente =
        familiaViewModel.getPresupuestoFamiliarPendiente();

    if (presupuestoPendiente != null) {
      _dialogShownForThisBudget = true; // Establecemos el flag
      showDialog(
        context: context,
        barrierDismissible: false, // El usuario debe interactuar con él
        builder: (BuildContext context) {
          return NewFamilyBudgetDialog(
            presupuestoFamiliar: presupuestoPendiente,
          );
        },
      ).then((_) {
        // Reseteamos el flag cuando el diálogo se cierra
        _dialogShownForThisBudget = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Perfil? perfilActivo = ref.watch(perfilActivoProvider);
    final Cuenta? cuentaActiva = ref.watch(cuentaActivaProvider);

    debugPrint('HOME_PAGE: perfilActivo es null? ${perfilActivo == null}');
    debugPrint('HOME_PAGE: cuentaActiva es null? ${cuentaActiva == null}');

    if (perfilActivo == null || cuentaActiva == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (perfilActivo is Familia) {
      // Este listener maneja las actualizaciones posteriores del perfil familiar
      // (por ejemplo, si se asigna un nuevo presupuesto mientras el usuario está en HomePage)
      ref.listen<Familia?>(familiaViewModelProvider, (
        previousFamilia,
        currentFamilia,
      ) {
        if (currentFamilia is Familia && currentFamilia.id == perfilActivo.id) {
          // Activamos la comprobación de nuevo si los datos de la familia cambian
          _checkForPendingFamilyBudget(
            ref.read(familiaViewModelProvider.notifier),
          );
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
