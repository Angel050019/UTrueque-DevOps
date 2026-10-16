import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/errors/publicacion_failures.dart';
import '../../domain/usecases/obtener_detalle_publicacion.dart';
import 'detalle_publicacion_state.dart';

/// Maneja la pantalla "Detalle de la publicación" (HU-04).
///
/// Siempre lee la publicación del servidor al abrirse, para mostrar su
/// estado actual (Escenario 9) o avisar que ya se borró (Escenario 10).
class DetallePublicacionCubit extends Cubit<DetalleState> {
  DetallePublicacionCubit(
    this._obtenerDetalle, {
    required this.idPublicacion,
    String? idUsuarioActual,
  })  : _idUsuarioActual = idUsuarioActual,
        super(const DetalleCargando());

  final ObtenerDetallePublicacion _obtenerDetalle;

  /// Publicación que se está viendo.
  final String idPublicacion;

  /// Estudiante con sesión; sirve para saber si la publicación es suya.
  final String? _idUsuarioActual;

  /// Carga (o vuelve a cargar con "jalar para actualizar" o "Reintentar").
  /// Si ya había una publicación en pantalla y falla, se conserva y se
  /// muestra el mensaje.
  Future<void> cargar() async {
    final DetalleState anterior = state;
    if (anterior is! DetalleCargado) emit(const DetalleCargando());
    try {
      final Publicacion publicacion = await _obtenerDetalle(idPublicacion);
      emit(DetalleCargado(publicacion: publicacion, esMia: publicacion.esDe(_idUsuarioActual)));
    } on PublicacionNoEncontradaFailure {
      emit(const DetalleNoEncontrado());
    } catch (error) {
      final Failure falla = error is Failure ? error : const CargarPublicacionesFailure();
      if (anterior is DetalleCargado) {
        emit(anterior.copyWith(aviso: () => falla.mensaje));
      } else {
        emit(DetalleError(falla));
      }
    }
  }

  /// La pantalla ya mostró el aviso (SnackBar); se limpia para no repetirlo.
  void avisoMostrado() {
    final DetalleState actual = state;
    if (actual is DetalleCargado && actual.aviso != null) {
      emit(actual.copyWith(aviso: () => null));
    }
  }
}
