import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/utils/formato_imagen.dart';

/// Foto del artículo elegida en la galería, todavía sin subir.
/// Se guarda en bytes para que funcione igual en el celular y en Chrome.
///
/// HU-06: al editar, las fotos que la publicación ya tenía se representan
/// con [FotoArticulo.guardada]: no tienen bytes, solo su [ruta] en el
/// bucket y su [url] pública. No se vuelven a subir.
class FotoArticulo extends Equatable {
  const FotoArticulo({required this.bytes, required this.nombreArchivo})
      : ruta = null,
        url = null;

  /// HU-06: foto que ya está guardada en Storage.
  FotoArticulo.guardada({required String this.ruta, required String this.url})
      : bytes = Uint8List(0),
        nombreArchivo = ruta;

  final Uint8List bytes;
  final String nombreArchivo;

  /// Ruta dentro del bucket (`<id del dueño>/<archivo>`); `null` si la foto
  /// todavía no se ha subido.
  final String? ruta;

  /// URL pública de una foto ya guardada.
  final String? url;

  /// ¿Ya está en Storage? (no se valida ni se sube de nuevo).
  bool get yaGuardada => ruta != null;

  int get tamanoBytes => bytes.length;

  /// Formato real según la firma del archivo; `null` si no es JPG ni PNG.
  FormatoImagen? get formato => detectarFormatoImagen(bytes);

  @override
  List<Object?> get props => [nombreArchivo, tamanoBytes, ruta];
}
