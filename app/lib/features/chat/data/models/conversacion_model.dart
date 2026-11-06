import '../../../publicaciones/domain/entities/estado_publicacion.dart';
import '../../domain/entities/conversacion.dart';

/// Una fila de la función `mis_conversaciones` (HU-07, bandeja).
class ConversacionModel extends Conversacion {
  const ConversacionModel({
    required super.id,
    required super.soyVendedor,
    required super.otroId,
    required super.otroNombre,
    required super.creadaEn,
    super.publicacionId,
    super.publicacionTitulo,
    super.publicacionFotoUrl,
    super.publicacionEstado,
    super.otroFotoUrl,
    super.ultimoTexto,
    super.ultimoAutorId,
    super.ultimoMensajeEn,
    super.noLeidos,
  });

  /// [urlFoto] convierte la ruta de la portada en el bucket en su URL
  /// pública.
  factory ConversacionModel.fromMap(Map<String, dynamic> mapa, {required String Function(String ruta) urlFoto}) {
    final String? ruta = mapa['publicacion_foto'] as String?;
    final String? estado = mapa['publicacion_estado'] as String?;
    final String? ultimo = mapa['ultimo_mensaje_en'] as String?;
    final String? nombre = (mapa['otro_nombre'] as String?)?.trim();
    return ConversacionModel(
      id: mapa['id'] as String,
      publicacionId: mapa['publicacion_id'] as String?,
      publicacionTitulo: mapa['publicacion_titulo'] as String?,
      publicacionFotoUrl: ruta == null ? null : urlFoto(ruta),
      publicacionEstado: estado == null ? null : EstadoPublicacion.desdeValor(estado),
      soyVendedor: mapa['soy_vendedor'] as bool? ?? false,
      otroId: mapa['otro_id'] as String,
      otroNombre: nombre == null || nombre.isEmpty ? 'Estudiante' : nombre,
      otroFotoUrl: mapa['otro_foto_url'] as String?,
      ultimoTexto: mapa['ultimo_texto'] as String?,
      ultimoAutorId: mapa['ultimo_autor_id'] as String?,
      ultimoMensajeEn: ultimo == null ? null : DateTime.parse(ultimo),
      noLeidos: (mapa['no_leidos'] as num?)?.toInt() ?? 0,
      creadaEn: DateTime.parse(mapa['created_at'] as String),
    );
  }
}
