import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../publicacion_keys.dart';

/// Indicador mientras llegan las categorías.
class CargandoPublicacion extends StatelessWidget {
  const CargandoPublicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(key: PublicacionKeys.cargando, color: AppColores.primario),
    );
  }
}

/// No se pudo preparar el formulario (por ejemplo, sin internet).
/// El [mensaje] ya viene en español desde la lógica.
class ErrorCargaPublicacion extends StatelessWidget {
  const ErrorCargaPublicacion({super.key, required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: PublicacionKeys.errorCarga,
      padding: const EdgeInsets.all(AppMedidas.margen),
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.cloud_off_rounded, size: 64, color: AppColores.error),
        const SizedBox(height: 16),
        Text(
          'No pudimos abrir el formulario',
          textAlign: TextAlign.center,
          style: AppTexto.subtitulo(size: 18),
        ),
        const SizedBox(height: 8),
        Text(mensaje, textAlign: TextAlign.center, style: AppTexto.cuerpo()),
        const SizedBox(height: 24),
        PrimaryButton(
          key: PublicacionKeys.reintentarBoton,
          texto: 'Reintentar',
          onPressed: onReintentar,
        ),
      ],
    );
  }
}
