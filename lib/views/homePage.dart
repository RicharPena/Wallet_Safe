import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/models/familia.dart'; // Importa Familia para el check de tipo
import 'package:wallet_safe/controllers/familia_viewmodel.dart'; // Importa el ViewModel (ajusta la ruta si está en controllers)
import 'package:wallet_safe/widgets/notificacion_presupuesto.dart'; // Importa el diálogo (ajusta la ruta si lo renombraste)

import 'package:wallet_safe/views/profiles.dart';
import 'package:wallet_safe/views/tabs/home_tab.dart';
import 'package:wallet_safe/views/tabs/ingresos_tab.dart';
import 'package:wallet_safe/views/tabs/gastos_tab.dart';
import 'package:wallet_safe/views/tabs/estadisticas_tab.dart';
import 'package:wallet_safe/views/tabs/config_tab.dart';
import 'package:wallet_safe/widgets/barra_inferior.dart';

// Extensión para List para firstWhereOrNull
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class HomePage extends ConsumerStatefulWidget {
  final Cuenta cuenta;
  final Perfil perfil;

  HomePage({required this.cuenta, required this.perfil, super.key});
  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _dialogShownForThisBudget =
      false; // Flag para asegurar que el diálogo solo se muestre una vez por *este* presupuesto

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // SOLO si el perfil actual es de tipo Familia, cargarlo en el ViewModel
      // y restablecer el flag del diálogo porque es un nuevo ingreso al perfil.
      if (widget.perfil is Familia) {
        ref
            .read(familiaViewModelProvider.notifier)
            .cargarFamilia(widget.perfil as Familia);
        _dialogShownForThisBudget =
            false; // Resetear el flag al cargar un nuevo perfil Familia
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si el perfil actual es de tipo Familia, escuchamos el ViewModel para diálogos.
    // Si no es Familia (ej. Titular), simplemente ignoramos esta lógica de escucha.
    if (widget.perfil is Familia) {
      // Usamos ref.listen fuera del `if` principal para la lógica de escucha, pero dentro de otro `if` para el tipo de perfil.
      // Esta posición es importante para que el `ref.listen` se registre correctamente.
      ref.listen<Familia?>(familiaViewModelProvider, (
        previousFamilia,
        currentFamilia,
      ) {
        // Solo si el perfil actual es una Familia y hay un presupuesto pendiente,
        // Y el diálogo aún no se ha mostrado para el *presupuesto específico* actual.
        // Y el `currentFamilia` del ViewModel coincide con el `widget.perfil` actual
        // (importante para evitar diálogos de viejas instancias de Familia si el estado cambia).
        if (currentFamilia is Familia &&
            currentFamilia.id == widget.perfil.id &&
            !_dialogShownForThisBudget) {
          final presupuestoPendiente = currentFamilia.cnPresupuestosFamiliares
              .firstWhereOrNull((pf) => !pf.distribuido);

          if (presupuestoPendiente != null) {
            // Asegúrate de que el diálogo no se muestre si ya hay uno abierto.
            bool isDialogShowing = false;
            Navigator.of(context).popUntil((route) {
              if (route is PopupRoute &&
                  route.settings.name == 'new_budget_dialog') {
                isDialogShowing = true;
              }
              return true;
            });

            if (!isDialogShowing) {
              _dialogShownForThisBudget =
                  true; // Marcar que el diálogo se va a mostrar
              showDialog(
                context: context,
                barrierDismissible:
                    false, // El usuario DEBE procesar el presupuesto
                routeSettings: const RouteSettings(name: 'new_budget_dialog'),
                builder: (BuildContext dialogContext) {
                  return NewFamilyBudgetDialog(
                    presupuestoFamiliar: presupuestoPendiente,
                  );
                },
              ).then((_) {
                // Cuando el diálogo se cierra (después de la distribución),
                // podemos resetear el flag o dejarlo así ya que el presupuesto se marcó como distribuido.
                // Si el mismo presupuesto se asigna de nuevo (lo cual no debería pasar si se distribuye),
                // el flag es útil. Por ahora, como el presupuesto se marca como "distribuido",
                // la lógica de `firstWhereOrull` se encargará de que no se muestre de nuevo.
                // El flag _dialogShownForThisBudget previene múltiples disparos *mientras* el diálogo está abierto.
                _dialogShownForThisBudget =
                    false; // Resetear el flag para futuras interacciones
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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder:
                      (_) => ProviderScope(
                        child: ProfileViews(cuenta: widget.cuenta),
                      ),
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
