import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_precio.dart';
import '../../domain/entities/estado_publicacion.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/publicacion.dart';
import '../publicacion_keys.dart';

/// Tarjeta de una publicación en el Feed: portada a la izquierda y, a la
/// derecha, título, categoría, dueño, modalidad (o precio) y estado.
class TarjetaPublicacion extends StatelessWidget {
  const TarjetaPublicacion({super.key, required this.publicacion, this.onTap});

  static const double _ladoPortada = 96;

  final Publicacion publicacion;

  /// Qué pasa al tocar la tarjeta (por ahora abre "En desarrollo").
  final VoidCallback? onTap;

  String get _textoModalidad {
    final double? precio = publicacion.precio;
    if (publicacion.modalidad == Modalidad.venta && precio != null) {
      return formatearPrecio(precio);
    }
    return publicacion.modalidad.etiqueta;
  }

  @override
  Widget build(BuildContext context) {
    final String detalle = [
      publicacion.categoriaNombre,
      publicacion.duenoNombre,
    ].whereType<String>().join(' · ');

    return Material(
      key: PublicacionKeys.tarjeta(publicacion.id),
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
        side: const BorderSide(color: AppColores.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                child: SizedBox(
                  width: _ladoPortada,
                  height: _ladoPortada,
                  child: _Portada(url: publicacion.portadaUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publicacion.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTexto.subtitulo(size: 15),
                    ),
                    if (detalle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTexto.cuerpo(size: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Etiqueta(
                          texto: _textoModalidad,
                          fondo: AppColores.primario,
                          color: AppColores.sobrePrimario,
                        ),
                        if (publicacion.estado is! Disponible)
                          _Etiqueta(
                            texto: publicacion.estado.etiqueta,
                            fondo: AppColores.errorSuave,
                            color: AppColores.error,
                          )
                        else
                          const _Etiqueta(
                            texto: 'Disponible',
                            fondo: AppColores.acentoSuave,
                            color: AppColores.primario,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Portada extends StatelessWidget {
  const _Portada({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const Widget sinFoto = ColoredBox(
      color: AppColores.primarioSuave,
      child: Icon(Icons.image_outlined, color: AppColores.primario),
    );
    final String? direccion = url;
    if (direccion == null) return sinFoto;
    return Image.network(
      direccion,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => sinFoto,
      loadingBuilder: (context, child, progreso) =>
          progreso == null ? child : const ColoredBox(color: AppColores.primarioSuave),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.fondo, required this.color});

  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(999)),
      child: Text(texto, style: AppTexto.cuerpo(size: 12, color: color, peso: FontWeight.w600)),
    );
  }
}
