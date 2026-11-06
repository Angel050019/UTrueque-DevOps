import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../domain/entities/mensaje.dart';
import '../chat_keys.dart';

/// Un mensaje del chat: los míos a la derecha en azul marino y los del otro
/// a la izquierda en azul claro, con la hora abajo.
// TODO(diseño): burbujas según Figma.
class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje({super.key, required this.mensaje, required this.esMio});

  final Mensaje mensaje;
  final bool esMio;

  @override
  Widget build(BuildContext context) {
    final Color fondo = esMio ? AppColores.primario : AppColores.primarioSuave;
    final Color letra = esMio ? AppColores.sobrePrimario : AppColores.texto;
    return Align(
      key: ChatKeys.burbuja(mensaje.id),
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(esMio ? 16 : 4),
              bottomRight: Radius.circular(esMio ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensaje.texto, style: AppTexto.cuerpo(size: 15, color: letra)),
              const SizedBox(height: 2),
              Text(
                formatearHora(mensaje.creadoEn),
                style: AppTexto.cuerpo(size: 11, color: letra.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
