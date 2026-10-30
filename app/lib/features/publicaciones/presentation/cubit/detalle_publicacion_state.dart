import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/errors/publicacion_failures.dart';

/// Estados de la pantalla "Detalle de la publicación" (HU-04).
abstract class DetalleState extends Equatable {
  const DetalleState();

  @override
  List<Object?> get props => const [];
}

class DetalleCargando extends DetalleState {
  const DetalleCargando();
}

/// La publicación ya no existe: su dueño la borró (Escenario 10).
class DetalleNoEncontrado extends DetalleState {
  const DetalleNoEncontrado();

  String get mensaje => const PublicacionNoEncontradaFailure().mensaje;
}

/// No se pudo cargar y no hay nada en pantalla (Escenarios 5 y 6).
class DetalleError extends DetalleState {
  const DetalleError(this.failure);

  final Failure failure;

  String get mensaje => failure.mensaje;

  @override
  List<Object?> get props => [failure];
}

/// La publicación ya cargó.
class DetalleCargado extends DetalleState {
  const DetalleCargado({required this.publicacion, required this.esMia, this.aviso});

  final Publicacion publicacion;

  /// La publicó el estudiante que la está viendo (Escenario 8).
  final bool esMia;

  /// Mensaje de un solo uso (SnackBar) cuando falla "jalar para actualizar".
  final String? aviso;

  /// "Contactar al vendedor" solo se habilita si no es mía y el estado lo
  /// permite (patrón State: solo Disponible acepta solicitudes).
  bool get puedeContactar => !esMia && publicacion.estado.aceptaSolicitudes;

  DetalleCargado copyWith({String? Function()? aviso}) {
    return DetalleCargado(
      publicacion: publicacion,
      esMia: esMia,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }

  @override
  List<Object?> get props => [publicacion, esMia, aviso];
}
