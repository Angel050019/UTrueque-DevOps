import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Formatos de imagen aceptados para la foto de perfil.
enum FormatoImagen {
  jpg('jpg', 'image/jpeg'),
  png('png', 'image/png');

  const FormatoImagen(this.extension, this.contentType);

  final String extension;
  final String contentType;
}

/// Foto elegida por el usuario, todavía sin subir.
/// Se guarda en bytes para que funcione igual en móvil y en Chrome.
class FotoPerfil extends Equatable {
  const FotoPerfil({required this.bytes, required this.nombreArchivo});

  final Uint8List bytes;
  final String nombreArchivo;

  int get tamanoBytes => bytes.length;

  /// Detecta el formato por la "firma" del archivo (sus primeros bytes),
  /// no por la extensión, para que no se pueda colar otro tipo de archivo.
  /// Devuelve `null` si no es JPG ni PNG.
  FormatoImagen? get formato {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return FormatoImagen.jpg;
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return FormatoImagen.png;
    }
    return null;
  }

  @override
  List<Object?> get props => [nombreArchivo, tamanoBytes];
}
