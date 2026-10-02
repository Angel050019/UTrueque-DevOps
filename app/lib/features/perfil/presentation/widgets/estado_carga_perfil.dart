import 'package:flutter/material.dart';

import '../perfil_keys.dart';

/// Indicador mientras se carga el perfil.
///
/// TODO(diseño): estado de carga final (skeleton, shimmer, etc.).
class CargandoPerfil extends StatelessWidget {
  const CargandoPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(key: PerfilKeys.cargando));
  }
}

/// Error al cargar el perfil (sin datos que mostrar), con botón de reintento.
///
/// TODO(diseño): estado de error/vacío final (ilustración, texto, botón).
class ErrorCargaPerfil extends StatelessWidget {
  const ErrorCargaPerfil({super.key, required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: PerfilKeys.errorCarga,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              key: PerfilKeys.reintentarBoton,
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
