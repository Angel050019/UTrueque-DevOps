import 'package:image_picker/image_picker.dart';

import '../../domain/entities/foto_perfil.dart';

/// Abre la galería y devuelve la foto elegida en bytes (funciona en
/// Android, iOS y Chrome). Devuelve `null` si el usuario cancela.
/// La validación (JPG/PNG, 5 MB) la hace el Cubit, no esta función.
Future<FotoPerfil?> elegirFotoDeGaleria() async {
  final XFile? archivo = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (archivo == null) return null;
  return FotoPerfil(bytes: await archivo.readAsBytes(), nombreArchivo: archivo.name);
}
