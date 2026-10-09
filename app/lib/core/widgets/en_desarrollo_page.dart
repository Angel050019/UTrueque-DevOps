import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_ui.dart';
import 'primary_button.dart';

/// Pantalla "En desarrollo" para funciones que llegan en sprints
/// posteriores (detalle de la publicación, Mis publicaciones…). Así la app
/// responde al tocar y no se siente estática.
///
/// Uso:
/// ```dart
/// EnDesarrolloPage.abrir(context, titulo: 'Mis publicaciones', mensaje: '…');
/// ```
class EnDesarrolloPage extends StatelessWidget {
  const EnDesarrolloPage({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.sprint,
  });

  /// Las pruebas buscan la pantalla por esta Key.
  static const Key pantallaKey = Key('en_desarrollo_pantalla');
  static const Key regresarBoton = Key('en_desarrollo_regresar_boton');

  /// Nombre de la función (se muestra en la barra superior).
  final String titulo;

  /// Qué podrá hacer el estudiante cuando esté lista.
  final String mensaje;

  /// Texto opcional del sprint en que llega, por ejemplo "Sprint 4".
  final String? sprint;

  static Future<void> abrir(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String? sprint,
  }) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EnDesarrolloPage(titulo: titulo, mensaje: mensaje, sprint: sprint),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: pantallaKey,
      body: SafeArea(
        child: Column(
          children: [
            BarraSuperior(titulo: titulo),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(40, 48, 40, 24),
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColores.acentoSuave,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        size: 56,
                        color: AppColores.primario,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Estamos trabajando en esto',
                    textAlign: TextAlign.center,
                    style: AppTexto.titulo(size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(mensaje, textAlign: TextAlign.center, style: AppTexto.cuerpo()),
                  if (sprint != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColores.primarioSuave,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Llega en el $sprint',
                          style: AppTexto.etiqueta(color: AppColores.primario),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 8, AppMedidas.margen, 16),
                child: PrimaryButton(
                  key: regresarBoton,
                  texto: 'Regresar',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
