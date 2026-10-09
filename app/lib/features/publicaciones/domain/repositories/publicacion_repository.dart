import '../entities/categoria.dart';
import '../entities/foto_articulo.dart';
import '../entities/modalidad.dart';
import '../entities/publicacion.dart';

/// Contrato de datos de las publicaciones. El dominio y la presentación
/// solo conocen esta interfaz, nunca a Supabase.
/// Todos los métodos lanzan un `Failure` si algo sale mal.
abstract class PublicacionRepository {
  /// Publicaciones Disponibles o Reservadas, de la más nueva a la más
  /// vieja, con su portada, dueño y categoría (para el Feed).
  Future<List<Publicacion>> obtenerPublicacionesRecientes({int limite = 20});

  /// Categorías activas, en el orden en que se muestran.
  Future<List<Categoria>> obtenerCategorias();

  /// Sube una foto a `publicaciones/<id del usuario>/` y devuelve su ruta
  /// dentro del bucket.
  Future<String> subirFoto(FotoArticulo foto);

  /// Borra fotos ya subidas (cuando la publicación no se pudo guardar).
  Future<void> eliminarFotos(List<String> rutas);

  /// Crea la publicación. El dueño y el estado inicial (Disponible) los
  /// asigna el servidor. Devuelve la publicación ya guardada.
  Future<Publicacion> crearPublicacion({
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required Modalidad modalidad,
    required double? precio,
    required List<String> fotos,
  });
}
