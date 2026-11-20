import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Globo con un número (HU-07, Escenario 8). Con 0 no se dibuja; de 10 en
/// adelante muestra "9+".
// TODO(diseño): globo según Figma.
class GloboNoLeidos extends StatelessWidget {
  const GloboNoLeidos({super.key, required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    if (cantidad <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColores.acento,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColores.superficie, width: 1.5),
      ),
      child: Text(
        cantidad > 9 ? '9+' : '$cantidad',
        style: AppTexto.subtitulo(size: 11, color: AppColores.primario),
      ),
    );
  }
}
