import 'dart:typed_data';

/// Formatos de imagen aceptados en la app (fotos de perfil y de
/// publicaciones). Coinciden con los `allowed_mime_types` de los buckets.
enum FormatoImagen {
  jpg('jpg', 'image/jpeg'),
  png('png', 'image/png');

  const FormatoImagen(this.extension, this.contentType);

  final String extension;
  final String contentType;
}

/// SEGURIDAD: validación de entrada.
/// Detecta el formato por la "firma" del archivo (sus primeros bytes),
/// no por la extensión, para que no se pueda colar otro tipo de archivo
/// renombrado. Devuelve `null` si no es JPG ni PNG.
FormatoImagen? detectarFormatoImagen(Uint8List bytes) {
  if (_empiezaCon(bytes, const [0xFF, 0xD8, 0xFF])) return FormatoImagen.jpg;
  if (_empiezaCon(bytes, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return FormatoImagen.png;
  }
  return null;
}

bool _empiezaCon(Uint8List bytes, List<int> firma) {
  if (bytes.length < firma.length) return false;
  for (int i = 0; i < firma.length; i++) {
    if (bytes[i] != firma[i]) return false;
  }
  return true;
}
