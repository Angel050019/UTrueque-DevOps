import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ruta del logo dentro de los assets.
const String rutaLogo = 'assets/images/logo_utrueque.png';

/// Logo de UTrueque. Si la imagen no carga, muestra el nombre en texto.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.ancho = 240});

  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      rutaLogo,
      width: ancho,
      semanticLabel: 'UTrueque',
      errorBuilder: (context, error, stackTrace) => Text(
        'UTrueque',
        style: AppTexto.titulo(size: ancho / 6, color: AppColores.acento),
      ),
    );
  }
}

/// Barra superior con botón de regreso y título, usada en pantallas
/// secundarias (Crear cuenta, Editar perfil).
class BarraSuperior extends StatelessWidget {
  const BarraSuperior({super.key, this.titulo, this.claro = false});

  final String? titulo;

  /// true cuando la barra va sobre un fondo oscuro (encabezado azul).
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final bool puedeRegresar = Navigator.of(context).canPop();
    final Color colorTexto = claro ? AppColores.sobrePrimario : AppColores.texto;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (puedeRegresar)
            Material(
              color: claro
                  ? AppColores.sobrePrimario.withValues(alpha: 0.15)
                  : AppColores.superficie,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: claro ? BorderSide.none : const BorderSide(color: AppColores.borde),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: colorTexto),
                ),
              ),
            ),
          if (puedeRegresar && titulo != null) const SizedBox(width: 12),
          if (titulo != null)
            Expanded(child: Text(titulo!, style: AppTexto.subtitulo(size: 18, color: colorTexto))),
        ],
      ),
    );
  }
}

/// Enlace de texto con estilo de la app (por ejemplo "Crear cuenta").
class EnlaceTexto extends StatelessWidget {
  const EnlaceTexto({super.key, required this.texto, required this.onPressed, this.color});

  final String texto;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColores.primario,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 36),
        textStyle: AppTexto.subtitulo(size: 14),
      ),
      child: Text(texto),
    );
  }
}

/// Muestra un mensaje flotante en la parte de abajo.
void mostrarMensaje(BuildContext context, String texto, {bool esError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColores.texto,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: esError ? AppColores.errorSuave : AppColores.acento,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: AppTexto.cuerpo(
                  size: 14,
                  color: AppColores.sobrePrimario,
                  peso: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
