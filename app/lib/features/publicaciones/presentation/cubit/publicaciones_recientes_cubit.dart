import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/usecases/obtener_publicaciones_recientes.dart';

/// Estados de la lista "Publicaciones recientes" del Feed.
abstract class RecientesState extends Equatable {
  const RecientesState();

  @override
  List<Object?> get props => const [];
}

class RecientesCargando extends RecientesState {
  const RecientesCargando();
}

class RecientesCargadas extends RecientesState {
  const RecientesCargadas(this.publicaciones);

  final List<Publicacion> publicaciones;

  @override
  List<Object?> get props => [publicaciones];
}

/// No se pudo cargar. [mensaje] ya viene en español.
class RecientesError extends RecientesState {
  const RecientesError(this.failure);

  final Failure failure;

  String get mensaje => failure.mensaje;

  @override
  List<Object?> get props => [failure];
}

/// Carga las publicaciones recientes para el Feed.
class PublicacionesRecientesCubit extends Cubit<RecientesState> {
  PublicacionesRecientesCubit(this._obtenerRecientes) : super(const RecientesCargando());

  final ObtenerPublicacionesRecientes _obtenerRecientes;

  /// Carga (o recarga) la lista. Si ya había publicaciones en pantalla, no
  /// las quita mientras recarga (para "jalar para actualizar").
  Future<void> cargar() async {
    if (state is! RecientesCargadas) emit(const RecientesCargando());
    try {
      emit(RecientesCargadas(await _obtenerRecientes()));
    } on Failure catch (falla) {
      emit(RecientesError(falla));
    } catch (_) {
      emit(const RecientesError(ServidorFailure()));
    }
  }
}
