import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../perfil_keys.dart';

/// Indicador mientras se carga el perfil.
class CargandoPerfil extends StatelessWidget {
  const CargandoPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(key: PerfilKeys.cargando, color: AppColores.primario),
    );
  }
}

/// Error al cargar el perfil (sin datos que mostrar), con botón de reintento.
/// El mensaje ya viene en español desde la lógica.
class ErrorCargaPerfil extends StatelessWidget {
  const ErrorCargaPerfil({super.key, required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  bool get _esSinConexion => mensaje.toLowerCase().contains('conexión');

  @override
  Widget build(BuildContext context) {
    return Center(
      key: PerfilKeys.errorCarga,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: AppColores.errorSuave,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _esSinConexion ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 52,
                color: AppColores.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _esSinConexion ? 'Sin conexión' : 'Algo salió mal',
              style: AppTexto.titulo(size: 22),
            ),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center, style: AppTexto.cuerpo()),
            const SizedBox(height: 24),
            PrimaryButton(
              key: PerfilKeys.reintentarBoton,
              texto: 'Reintentar',
              onPressed: onReintentar,
            ),
          ],
        ),
      ),
    );
  }
}
