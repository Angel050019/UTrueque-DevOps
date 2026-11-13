import 'package:equatable/equatable.dart';

import 'categoria.dart';
import 'foto_articulo.dart';
import 'modalidad.dart';

/// Lo que el estudiante capturó en "Publicar artículo", todavía sin validar
/// ni enviar. El precio llega como texto, tal cual se escribió.
class BorradorPublicacion extends Equatable {
  const BorradorPublicacion({
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.modalidad,
    required this.fotos,
    this.precioTexto = '',
  });

  final String titulo;
  final String descripcion;
  final Categoria? categoria;
  final Modalidad? modalidad;
  final String precioTexto;
  final List<FotoArticulo> fotos;

  @override
  List<Object?> get props => [titulo, descripcion, categoria, modalidad, precioTexto, fotos];
}
