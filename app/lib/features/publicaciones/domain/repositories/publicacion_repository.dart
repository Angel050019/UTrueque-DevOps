import '../entities/categoria.dart';
import '../entities/estado_publicacion.dart';
import '../entities/filtros_feed.dart';
import '../entities/foto_articulo.dart';
import '../entities/modalidad.dart';
import '../entities/pagina_feed.dart';
import '../entities/publicacion.dart';

/// Contrato de datos de las publicaciones. El dominio y la presentación
/// solo conocen esta interfaz, nunca a Supabase.
/// Todos los métodos lanzan un `Failure` si algo sale mal.
abstract class PublicacionRepository {
  /// HU-04 y HU-05: una página del Feed. Publicaciones Disponibles o
  /// Reservadas, de la más nueva a la más vieja, con su portada, dueño y
  /// categoría, que cumplen todos los [filtros] (texto, categoría, división
  /// y carrera del dueño). Con [despuesDe] trae las que siguen a ese cursor.
  Future<PaginaFeed> buscarPublicaciones({
    FiltrosFeed filtros = const FiltrosFeed(),
    CursorFeed? despuesDe,
    required int limite,
  });

  /// HU-04: detalle de una publicación con todas sus fotos y el perfil
  /// público del dueño. Lanza `PublicacionNoEncontradaFailure` si ya no
  /// existe.
  Future<Publicacion> obtenerDetalle(String id);

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

  // -------------------------------------------------------------------
  // HU-06: Gestión de "Mis publicaciones"
  // -------------------------------------------------------------------

  /// Una página de las publicaciones del estudiante con sesión, de la más
  /// nueva a la más vieja. [finalizadas] = false trae las Activas
  /// (Disponibles y Reservadas); true trae las Vendidas (historial).
  Future<PaginaFeed> obtenerMisPublicaciones({
    required bool finalizadas,
    CursorFeed? despuesDe,
    required int limite,
  });

  /// Cambia el estado de la publicación [id] a [nuevo]. El servidor revisa
  /// que la transición sea válida y que la publicación sea del estudiante.
  /// Devuelve la publicación ya actualizada.
  Future<Publicacion> cambiarEstado(String id, EstadoPublicacion nuevo);

  /// Guarda los datos editados de la publicación [id] (solo Disponibles).
  /// Devuelve la publicación ya actualizada.
  Future<Publicacion> editarPublicacion({
    required String id,
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required Modalidad modalidad,
    required double? precio,
    required List<String> fotos,
  });

  /// Borra la publicación [id] (solo Disponibles) y devuelve las rutas de
  /// sus fotos para borrarlas de Storage.
  Future<List<String>> borrarPublicacion(String id);
}
