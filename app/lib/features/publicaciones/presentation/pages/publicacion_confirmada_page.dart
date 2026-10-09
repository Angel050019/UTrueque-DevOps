import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_precio.dart';
import '../../../../core/widgets/en_desarrollo_page.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/foto_articulo.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/publicacion.dart';
import '../publicacion_keys.dart';

/// Confirmación de publicación (diseño de Figma "Confirmación Publicación").
/// Aparece después de que la API responde 201 Created: muestra la tarjeta
/// del artículo y dos acciones: "Ver publicación" y "Volver al inicio".
///
/// Se abre ENCIMA de un Feed nuevo (ya recargado), así que "Volver al
/// inicio" o el botón atrás del celular solo cierran esta pantalla.
class PublicacionConfirmadaPage extends StatelessWidget {
  const PublicacionConfirmadaPage({
    super.key,
    required this.publicacion,
    this.portada,
    this.categoriaNombre,
  });

  final Publicacion publicacion;

  /// Primera foto elegida (se muestra desde la memoria, sin descargarla).
  final FotoArticulo? portada;
  final String? categoriaNombre;

  /// Deja el Feed recién cargado como única pantalla y abre la
  /// confirmación encima.
  static void mostrar(
    BuildContext context, {
    required Publicacion publicacion,
    FotoArticulo? portada,
    String? categoriaNombre,
  }) {
    final NavigatorState navegador = Navigator.of(context);
    navegador.pushNamedAndRemoveUntil(AppRoutes.feedPrincipal, (route) => false);
    navegador.push(MaterialPageRoute<void>(
      builder: (_) => PublicacionConfirmadaPage(
        publicacion: publicacion,
        portada: portada,
        categoriaNombre: categoriaNombre,
      ),
    ));
  }

  void _verPublicacion(BuildContext context) {
    EnDesarrolloPage.abrir(
      context,
      titulo: 'Detalle de la publicación',
      mensaje: 'Muy pronto podrás ver todas las fotos, la descripción completa '
          'y los datos de quien publica.',
      sprint: 'Sprint 4',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: PublicacionKeys.confirmacion,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 40, AppMedidas.margen, 24),
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColores.acentoSuave,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 56, color: AppColores.primario),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tu publicación está activa',
                    textAlign: TextAlign.center,
                    style: AppTexto.titulo(size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Perfecto! Tus compañeros de la UTSJR ya pueden ver tu artículo en el Feed.',
                    textAlign: TextAlign.center,
                    style: AppTexto.cuerpo(),
                  ),
                  const SizedBox(height: 28),
                  _TarjetaConfirmacion(
                    publicacion: publicacion,
                    portada: portada,
                    categoriaNombre: categoriaNombre,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 8, AppMedidas.margen, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      key: PublicacionKeys.verPublicacionBoton,
                      texto: 'Ver publicación',
                      onPressed: () => _verPublicacion(context),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      key: PublicacionKeys.volverInicioBoton,
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColores.primario,
                        textStyle: AppTexto.subtitulo(size: 15).copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      child: const Text('Volver al inicio'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta grande con la portada, la categoría, el título y el precio (o
/// la modalidad), como en el diseño de Figma.
class _TarjetaConfirmacion extends StatelessWidget {
  const _TarjetaConfirmacion({
    required this.publicacion,
    required this.portada,
    required this.categoriaNombre,
  });

  final Publicacion publicacion;
  final FotoArticulo? portada;
  final String? categoriaNombre;

  String get _precioOModalidad {
    final double? precio = publicacion.precio;
    if (publicacion.modalidad == Modalidad.venta && precio != null) {
      return formatearPrecio(precio);
    }
    return publicacion.modalidad.etiqueta;
  }

  @override
  Widget build(BuildContext context) {
    final FotoArticulo? foto = portada;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: foto == null
                ? const ColoredBox(
                    color: AppColores.primarioSuave,
                    child: Icon(Icons.image_outlined, size: 48, color: AppColores.primario),
                  )
                : Image.memory(foto.bytes, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (categoriaNombre != null)
                  Text(
                    categoriaNombre!.toUpperCase(),
                    style: AppTexto.etiqueta(color: AppColores.primario).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  publicacion.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTexto.subtitulo(size: 17),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColores.acentoSuave,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _precioOModalidad,
                    style: AppTexto.cuerpo(size: 13, color: AppColores.primario, peso: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
