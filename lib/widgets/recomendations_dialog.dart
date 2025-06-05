import 'package:flutter/material.dart';
import 'package:wallet_safe/models/perfil.dart';
import 'package:wallet_safe/services/chart_service.dart';
import 'package:wallet_safe/widgets/recomendations_bar.dart';

class FinancialInsightDialog extends StatelessWidget {
  final Perfil perfil;

  const FinancialInsightDialog({super.key, required this.perfil});

  @override
  Widget build(BuildContext context) {
    final currentLevel = ChartService.obtenerNivelPoderAdquisitivo(perfil);
    final recommendation = ChartService.obtenerRecomendacion(currentLevel);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text(
        "Tu Nivel de Poder Adquisitivo",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize:
            MainAxisSize.min, // Para que el Column no ocupe todo el alto
        children: [
          Text(
            "Nivel Actual: $currentLevel/5",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          WealthLevelBar(level: currentLevel), // Tu barra de nivel
          const SizedBox(height: 20),
          const Text(
            "Recomendación:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo
          },
          child: const Text("Cerrar"),
        ),
      ],
    );
  }

  // Método estático para mostrar el diálogo fácilmente
  static void show(BuildContext context, Perfil perfil) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FinancialInsightDialog(perfil: perfil);
      },
    );
  }
}
