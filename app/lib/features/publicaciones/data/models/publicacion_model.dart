import '../../domain/entities/categoria.dart';
import '../../domain/entities/estado_publicacion.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/publicacion.dart';

/// Convierte filas de `public.publicaciones` en [Publicacion].
class PublicacionModel extends Publicacion {
  const PublicacionModel({
    required super.id,
    required super.usuarioId,
    required super.titulo,
    required super.descripcion,
    required super.categoriaId,
    required super.modalidad,
    required super.estado,
    required super.fotos,
    super.precio,
    super.creadaEn,
    super.portadaUrl,
    super.duenoNombre,
    super.categoriaNombre,
    super.fotosUrls,
    super.duenoFotoUrl,
    super.duenoDivision,
    super.duenoCarrera,
  });

  /// Columnas que se piden a Supabase.
  static const String columnasSelect = 'id, usuario_id, titulo, descripcion, categoria_id, '
      'modalidad, precio, estado, fotos, created_at';

  /// HU-04: vista de la base con la publicación, su categoría y el perfil
  /// público del dueño (la usan el Feed y el Detalle).
  static const String vistaDetalle = 'publicaciones_detalle';

  /// HU-05: función de la base que entrega el Feed por páginas, con
  /// búsqueda y filtros (sin filtros es el mismo Feed de HU-04). La función
  /// `feed_publicaciones` de HU-04 se conserva en la base solo para las
  /// versiones anteriores de la app.
  static const String funcionBuscar = 'buscar_publicaciones';

  /// HU-06: función de la base con las publicaciones del estudiante con
  /// sesión (Activas o Finalizadas), por páginas.
  static const String funcionMisPublicaciones = 'mis_publicaciones';

  /// Convierte una fila de `publicaciones` o de la vista
  /// `publicaciones_detalle` en [Publicacion].
  ///
  /// [urlFoto] convierte cada ruta del bucket en su URL pública; si no se
  /// pasa, `portadaUrl` queda en `null` y `fotosUrls` vacía.
  factory PublicacionModel.fromMap(
    Map<String, dynamic> mapa, {
    String Function(String ruta)? urlFoto,
  }) {
    final String? creada = mapa['created_at'] as String?;
    final List<String> fotos = ((mapa['fotos'] as List<dynamic>?) ?? const <dynamic>[])
        .cast<String>()
        .toList(growable: false);
    final List<String> fotosUrls =
        urlFoto == null ? const <String>[] : fotos.map(urlFoto).toList(growable: false);
    return PublicacionModel(
      id: mapa['id'] as String,
      usuarioId: mapa['usuario_id'] as String,
      titulo: mapa['titulo'] as String,
      descripcion: mapa['descripcion'] as String,
      categoriaId: (mapa['categoria_id'] as num).toInt(),
      modalidad: Modalidad.desdeValor(mapa['modalidad'] as String),
      // numeric llega como número; por si acaso también se acepta texto.
      precio: _leerNumero(mapa['precio']),
      estado: EstadoPublicacion.desdeValor(mapa['estado'] as String),
      fotos: fotos,
      creadaEn: creada == null ? null : DateTime.parse(creada),
      portadaUrl: fotosUrls.isEmpty ? null : fotosUrls.first,
      fotosUrls: fotosUrls,
      // Columnas de la vista publicaciones_detalle (HU-04).
      categoriaNombre: mapa['categoria_nombre'] as String?,
      duenoNombre: mapa['dueno_nombre'] as String?,
      duenoFotoUrl: mapa['dueno_foto_url'] as String?,
      duenoDivision: mapa['dueno_division'] as String?,
      duenoCarrera: mapa['dueno_carrera'] as String?,
    );
  }

  /// SEGURIDAD: no confiar en el cliente.
  /// Datos que la app envía al crear una publicación. NO incluye
  /// `usuario_id` ni `estado`: los pone el servidor (no se confía en el
  /// cliente para decidir de quién es la publicación ni en qué estado nace).
  static Map<String, dynamic> paraCrear({
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required Modalidad modalidad,
    required double? precio,
    required List<String> fotos,
  }) {
    return <String, dynamic>{
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
      'modalidad': modalidad.valor,
      'precio': modalidad.requierePrecio ? precio : null,
      'fotos': fotos,
    };
  }

  /// HU-06: datos que la app envía al editar una publicación. Son los
  /// mismos campos que al crear; tampoco incluye `usuario_id` ni `estado`.
  static Map<String, dynamic> paraEditar({
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required Modalidad modalidad,
    required double? precio,
    required List<String> fotos,
  }) =>
      paraCrear(
        titulo: titulo,
        descripcion: descripcion,
        categoriaId: categoriaId,
        modalidad: modalidad,
        precio: precio,
        fotos: fotos,
      );

  /// HU-06: al cambiar de estado se manda SOLO el estado nuevo. El servidor
  /// revisa que la transición sea válida (patrón State).
  static Map<String, dynamic> paraCambiarEstado(EstadoPublicacion estado) =>
      <String, dynamic>{'estado': estado.valor};

  static double? _leerNumero(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString());
  }
}

/// Convierte filas de `public.categorias` en [Categoria].
class CategoriaModel extends Categoria {
  const CategoriaModel({required super.id, required super.nombre});

  static const String columnasSelect = 'id, nombre, orden';

  factory CategoriaModel.fromMap(Map<String, dynamic> mapa) {
    return CategoriaModel(
      id: (mapa['id'] as num).toInt(),
      nombre: mapa['nombre'] as String,
    );
  }
}
