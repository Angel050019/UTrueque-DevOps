import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pantalla de aviso a pantalla completa: ícono en círculo, título, texto y
/// una acción opcional (por ejemplo "Reintentar"). La usan el Feed y el
/// Detalle para los estados de vacío, error y "ya no está disponible".
///
/// Es una lista con scroll siempre activo para que "jalar para actualizar"
/// también funcione sobre el aviso.
class AvisoPantalla extends StatelessWidget {
  const AvisoPantalla({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    this.accion,
    this.margen = const EdgeInsets.fromLTRB(16, 24, 16, 88),
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final Widget? accion;

  /// Espacio alrededor del contenido (el Feed deja lugar abajo para el
  /// botón "Publicar").
  final EdgeInsetsGeometry margen;

  @override
  Widget build(BuildContext context) {
    final Widget? boton = accion;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: margen,
      children: [
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: AppColores.primarioSuave,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 52, color: AppColores.primario),
          ),
        ),
        const SizedBox(height: 16),
        Text(titulo, textAlign: TextAlign.center, style: AppTexto.subtitulo(size: 18)),
        const SizedBox(height: 8),
        Text(texto, textAlign: TextAlign.center, style: AppTexto.cuerpo(size: 14)),
        if (boton != null) ...[const SizedBox(height: 20), boton],
      ],
    );
  }
}
