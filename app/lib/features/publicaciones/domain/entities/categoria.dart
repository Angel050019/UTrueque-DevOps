import 'package:equatable/equatable.dart';

/// Categoría de un artículo (Libros y apuntes, Calculadoras, Batas…).
/// El catálogo vive en la tabla `categorias` de Supabase.
class Categoria extends Equatable {
  const Categoria({required this.id, required this.nombre});

  final int id;
  final String nombre;

  @override
  List<Object?> get props => [id, nombre];
}
