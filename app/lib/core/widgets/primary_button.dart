import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón primario estándar de UTrueque, con estado de carga integrado.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppMedidas.altoBoton,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColores.primario,
          foregroundColor: AppColores.sobrePrimario,
          disabledBackgroundColor: AppColores.primario.withValues(alpha: 0.55),
          disabledForegroundColor: AppColores.sobrePrimario,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMedidas.radioBoton),
          ),
          textStyle: AppTexto.subtitulo(color: AppColores.sobrePrimario),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColores.sobrePrimario,
                ),
              )
            : Text(texto),
      ),
    );
  }
}

/// Botón secundario (contorno), para acciones como "Editar perfil".
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.texto, required this.onPressed});

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppMedidas.altoBoton,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColores.primario,
          backgroundColor: AppColores.superficie,
          side: const BorderSide(color: AppColores.primario, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMedidas.radioBoton),
          ),
          textStyle: AppTexto.subtitulo(color: AppColores.primario),
        ),
        child: Text(texto),
      ),
    );
  }
}
