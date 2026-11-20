import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/conversacion.dart';

/// Estados de la bandeja de mensajes (HU-07, Escenario 7).
abstract class BandejaState extends Equatable {
  const BandejaState();

  @override
  List<Object?> get props => const [];
}

class BandejaCargando extends BandejaState {
  const BandejaCargando();
}

/// "Aún no tienes mensajes."
class BandejaVacia extends BandejaState {
  const BandejaVacia();

  static const String mensaje = 'Aún no tienes mensajes.';
}

class BandejaError extends BandejaState {
  const BandejaError(this.failure);

  final Failure failure;

  String get mensaje => failure.mensaje;

  bool get sinConexion => failure is SinConexionFailure;

  @override
  List<Object?> get props => [failure];
}

class BandejaCargada extends BandejaState {
  const BandejaCargada(this.conversaciones, {this.aviso});

  /// La más reciente primero.
  final List<Conversacion> conversaciones;

  /// Mensaje de un solo uso (SnackBar) si falla "jalar para actualizar".
  final String? aviso;

  @override
  List<Object?> get props => [conversaciones, aviso];
}
