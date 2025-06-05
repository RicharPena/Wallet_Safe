import 'package:flutter/material.dart';

class WealthLevelBar extends StatelessWidget {
  final int level; // El nivel actual (1-5)

  const WealthLevelBar({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        // index va de 0 a 4, los niveles son de 1 a 5
        final bool isFilled = index < level;
        final Color color =
            isFilled ? _getLevelColor(index + 1) : Colors.grey[300]!;

        return Container(
          width: 30, // Ancho de cada bloque
          height: 15, // Alto de cada bloque
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.red[700]!;
      case 2:
        return Colors.orange[700]!;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen[700]!;
      case 5:
        return Colors.green[700]!;
      default:
        return Colors.grey[300]!;
    }
  }
}
