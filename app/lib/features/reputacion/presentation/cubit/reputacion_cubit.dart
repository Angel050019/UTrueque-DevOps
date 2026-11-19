import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/reputacion.dart';
import '../../domain/errors/reputacion_failures.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';

/// Estados de la reputación de un estudiante (HU-09, Escenarios 5 a 8 y 14).
abstract class ReputacionState extends Equatable {
  const ReputacionState();

  @override
  List<Object?> get props => const [];
}

class ReputacionCargando extends ReputacionState {
  const ReputacionCargando();
}

class ReputacionLista extends ReputacionState {
  const ReputacionLista(this.reputacion);

  final Reputacion reputacion;

  @override
  List<Object?> get props => [reputacion];
}

class ReputacionError extends ReputacionState {
  const ReputacionError(this.mensaje, {this.sinConexion = false});

  final String mensaje;
  final bool sinConexion;

  @override
  List<Object?> get props => [mensaje, sinConexion];
}

/// La reputación de [usuarioId] para Mi perfil, el Detalle y el chat. La
/// calcula el caso de uso con el patrón Strategy; aquí solo se pide.
class ReputacionCubit extends Cubit<ReputacionState> {
  ReputacionCubit({required ObtenerReputacion obtenerReputacion, required this.usuarioId})
      : _obtener = obtenerReputacion,
        super(const ReputacionCargando());

  final ObtenerReputacion _obtener;
  final String usuarioId;

  /// También es "Reintentar" y sirve para actualizar después de calificar.
  Future<void> cargar() async {
    if (state is! ReputacionLista) _emitir(const ReputacionCargando());
    try {
      _emitir(ReputacionLista(await _obtener(usuarioId)));
    } on SinConexionFailure catch (f) {
      _emitir(ReputacionError(f.mensaje, sinConexion: true));
    } on Failure catch (f) {
      _emitir(ReputacionError(f.mensaje));
    } catch (_) {
      _emitir(ReputacionError(const ReputacionServidorFailure().mensaje));
    }
  }

  void _emitir(ReputacionState nuevo) {
    if (!isClosed) emit(nuevo);
  }
}
