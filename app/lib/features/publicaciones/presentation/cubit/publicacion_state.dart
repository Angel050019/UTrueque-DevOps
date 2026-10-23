import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/foto_articulo.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/errors/publicacion_failures.dart';

/// Lo que la pantalla "Publicar artículo" necesita dibujar: el catálogo y lo
/// que el estudiante va eligiendo. Los textos (título, descripción, precio)
/// viven en los `TextEditingController` de la página.
class PublicacionDatos extends Equatable {
  const PublicacionDatos({
    this.categorias = const [],
    this.categoria,
    this.modalidad,
    this.fotos = const [],
    this.errores = const {},
  });

  final List<Categoria> categorias;
  final Categoria? categoria;
  final Modalidad? modalidad;

  /// Fotos elegidas, todavía sin subir. La primera es la portada.
  final List<FotoArticulo> fotos;

  /// Error de cada campo (se pinta en rojo debajo del campo).
  final Map<CampoPublicacion, String> errores;

  bool get muestraPrecio => modalidad?.requierePrecio ?? false;

  String? errorDe(CampoPublicacion campo) => errores[campo];

  PublicacionDatos copyWith({
    List<Categoria>? categorias,
    Categoria? Function()? categoria,
    Modalidad? Function()? modalidad,
    List<FotoArticulo>? fotos,
    Map<CampoPublicacion, String>? errores,
  }) {
    return PublicacionDatos(
      categorias: categorias ?? this.categorias,
      categoria: categoria != null ? categoria() : this.categoria,
      modalidad: modalidad != null ? modalidad() : this.modalidad,
      fotos: fotos ?? this.fotos,
      errores: errores ?? this.errores,
    );
  }

  /// Copia sin el error de los [campos] indicados.
  PublicacionDatos sinErrores(Iterable<CampoPublicacion> campos) {
    final Map<CampoPublicacion, String> restantes = Map<CampoPublicacion, String>.of(errores)
      ..removeWhere((campo, _) => campos.contains(campo));
    return copyWith(errores: restantes);
  }

  @override
  List<Object?> get props => [categorias, categoria, modalidad, fotos, errores];
}

/// Estados de la pantalla "Publicar artículo".
///
/// Flujo típico:
///   Inicial → Cargando → Editando
///   → (Publicar) Enviando → Publicada | Error
abstract class PublicacionState extends Equatable {
  const PublicacionState();

  /// Datos del formulario (null mientras carga o si falló la carga).
  PublicacionDatos? get datos => null;

  @override
  List<Object?> get props => [datos];
}

class PublicacionInicial extends PublicacionState {
  const PublicacionInicial();
}

/// Se está cargando el catálogo de categorías.
class PublicacionCargando extends PublicacionState {
  const PublicacionCargando();
}

/// Formulario listo para capturar.
class PublicacionEditando extends PublicacionState {
  const PublicacionEditando(this.datos);

  @override
  final PublicacionDatos datos;
}

/// Se están subiendo las fotos y creando la publicación.
class PublicacionEnviando extends PublicacionState {
  const PublicacionEnviando(this.datos);

  @override
  final PublicacionDatos datos;
}

/// La API respondió 201 Created: la publicación ya existe.
class PublicacionPublicada extends PublicacionState {
  const PublicacionPublicada(this.datos, this.publicacion);

  @override
  final PublicacionDatos datos;
  final Publicacion publicacion;

  @override
  List<Object?> get props => [datos, publicacion];
}

/// Algo falló. [mensaje] trae el texto en español para mostrar.
/// Si [datos] no es null, el formulario sigue en pantalla con lo capturado.
class PublicacionError extends PublicacionState {
  const PublicacionError(this.failure, {this.datos});

  final Failure failure;

  @override
  final PublicacionDatos? datos;

  String get mensaje => failure.mensaje;

  @override
  List<Object?> get props => [failure, datos];
}
