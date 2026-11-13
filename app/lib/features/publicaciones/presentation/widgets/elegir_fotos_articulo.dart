import 'package:image_picker/image_picker.dart';

import '../../domain/entities/foto_articulo.dart';

/// Abre la galería para elegir hasta [maximo] fotos del artículo y las
/// devuelve en bytes (funciona en Android, iOS y Chrome). Devuelve una
/// lista vacía si el usuario cancela.
///
/// Se pide a la galería una versión más ligera (máx. 1920 px y calidad 85)
/// porque las cámaras actuales sacan fotos de más de 5 MB. La validación
/// final (JPG/PNG, 5 MB, máximo 5 fotos) la hace el Cubit, no esta función.
Future<List<FotoArticulo>> elegirFotosArticulo({required int maximo}) async {
  if (maximo <= 0) return const [];
  final ImagePicker picker = ImagePicker();
  final List<XFile> archivos;
  if (maximo == 1) {
    final XFile? archivo =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
    archivos = archivo == null ? const [] : [archivo];
  } else {
    archivos = await picker.pickMultiImage(maxWidth: 1920, imageQuality: 85, limit: maximo);
  }
  return Future.wait(archivos.map(
    (archivo) async => FotoArticulo(bytes: await archivo.readAsBytes(), nombreArchivo: archivo.name),
  ));
}
