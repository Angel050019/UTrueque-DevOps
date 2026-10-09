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
  });

  /// Columnas que se piden a Supabase.
  static const String columnasSelect = 'id, usuario_id, titulo, descripcion, categoria_id, '
      'modalidad, precio, estado, fotos, created_at';

  factory PublicacionModel.fromMap(Map<String, dynamic> mapa) {
    final String? creada = mapa['created_at'] as String?;
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
      fotos: ((mapa['fotos'] as List<dynamic>?) ?? const <dynamic>[])
          .cast<String>()
          .toList(growable: false),
      creadaEn: creada == null ? null : DateTime.parse(creada),
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
