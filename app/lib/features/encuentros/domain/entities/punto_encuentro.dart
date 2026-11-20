import 'package:equatable/equatable.dart';

/// Un lugar oficial y seguro de la UTSJR donde se puede hacer la entrega
/// (HU-08). Viene del catálogo de la base de datos; no hay lugares escritos
/// a mano.
class PuntoEncuentro extends Equatable {
  const PuntoEncuentro({required this.id, required this.nombre, required this.referencia});

  /// Texto corto y fijo, por ejemplo `biblioteca`.
  final String id;

  /// Por ejemplo "Biblioteca - Entrada Principal".
  final String nombre;

  /// Cómo encontrarlo, por ejemplo "Frente a la puerta principal".
  final String referencia;

  @override
  List<Object?> get props => [id, nombre, referencia];
}
