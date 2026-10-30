import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/utils/formato_imagen.dart';

// FormatoImagen vive ahora en core/utils (HU-03 también lo usa). Se
// re-exporta aquí para no romper los imports existentes de HU-02.
export '../../../../core/utils/formato_imagen.dart' show FormatoImagen;

/// Foto elegida por el usuario, todavía sin subir.
/// Se guarda en bytes para que funcione igual en móvil y en Chrome.
class FotoPerfil extends Equatable {
  const FotoPerfil({required this.bytes, required this.nombreArchivo});

  final Uint8List bytes;
  final String nombreArchivo;

  int get tamanoBytes => bytes.length;

  /// Formato detectado por la firma del archivo (no por la extensión).
  /// Devuelve `null` si no es JPG ni PNG.
  FormatoImagen? get formato => detectarFormatoImagen(bytes);

  @override
  List<Object?> get props => [nombreArchivo, tamanoBytes];
}
