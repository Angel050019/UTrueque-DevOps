import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/utils/formato_imagen.dart';

/// Foto del artículo elegida en la galería, todavía sin subir.
/// Se guarda en bytes para que funcione igual en el celular y en Chrome.
class FotoArticulo extends Equatable {
  const FotoArticulo({required this.bytes, required this.nombreArchivo});

  final Uint8List bytes;
  final String nombreArchivo;

  int get tamanoBytes => bytes.length;

  /// Formato real según la firma del archivo; `null` si no es JPG ni PNG.
  FormatoImagen? get formato => detectarFormatoImagen(bytes);

  @override
  List<Object?> get props => [nombreArchivo, tamanoBytes];
}
