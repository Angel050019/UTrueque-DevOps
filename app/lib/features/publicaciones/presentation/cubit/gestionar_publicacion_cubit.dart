import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../reputacion/domain/entities/trato.dart';
import '../../../reputacion/domain/usecases/casos_de_uso_reputacion.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/errors/publicacion_failures.dart';
import '../../domain/usecases/borrar_publicacion.dart';
import '../../domain/usecases/cambiar_estado_publicacion.dart';
import '../../domain/usecases/obtener_detalle_publicacion.dart';
import 'gestionar_publicacion_state.dart';

/// Maneja la hoja "Gestionar publicación" (HU-06, Escenarios 3 a 5, 8 y 9).
///
/// Las acciones que se ofrecen salen del estado de la publicación (patrón
/// State). Vender y Borrar piden confirmación antes de enviar nada.
class GestionarPublicacionCubit extends Cubit<GestionState> {
  GestionarPublicacionCubit({
    required Publicacion publicacion,
    required CambiarEstadoPublicacion cambiarEstado,
    required BorrarPublicacion borrarPublicacion,
    ObtenerDetallePublicacion? obtenerDetalle,
    MarcarVendida? marcarVendida,
  })  : _cambiarEstado = cambiarEstado,
        _borrar = borrarPublicacion,
        _obtenerDetalle = obtenerDetalle,
        _marcarVendida = marcarVendida,
        super(GestionLista(publicacion));

  final CambiarEstadoPublicacion _cambiarEstado;
  final BorrarPublicacion _borrar;

  /// Para recargar la publicación cuando el servidor dice que su estado ya
  /// cambió (por ejemplo, se vendió desde otro dispositivo).
  final ObtenerDetallePublicacion? _obtenerDetalle;

  /// HU-09: vender eligiendo al comprador. Si no se da, "Marcar como
  /// Vendido" funciona como en HU-06.
  final MarcarVendida? _marcarVendida;

  /// HU-09: ¿al confirmar la venta se pregunta a quién se le vendió?
  bool get eligeComprador => _marcarVendida != null;

  /// El estudiante tocó una operación. Si es Vender o Borrar, primero se
  /// pide confirmar; si no, se envía de una vez.
  Future<void> elegir(OperacionGestion operacion) async {
    final GestionState actual = state;
    if (actual is! GestionLista && actual is! GestionError) return;
    if (!actual.operaciones.contains(operacion)) {
      _emitir(GestionError(actual.publicacion, const AccionNoPermitidaFailure()));
      return;
    }
    if (operacion.requiereConfirmacion) {
      _emitir(GestionConfirmando(actual.publicacion, operacion));
      return;
    }
    await _ejecutar(actual.publicacion, operacion);
  }

  /// "Sí" en la confirmación.
  Future<void> confirmar() async {
    final GestionState actual = state;
    if (actual is! GestionConfirmando) return;
    await _ejecutar(actual.publicacion, actual.operacion);
  }

  /// HU-09, Escenarios 1 y 2: el vendedor eligió a quién se lo vendió (o
  /// "fuera de UTrueque") en lugar de solo confirmar.
  Future<void> venderA(EleccionVenta eleccion) async {
    final GestionState actual = state;
    final MarcarVendida? vender = _marcarVendida;
    if (actual is! GestionConfirmando || actual.operacion != OperacionGestion.marcarVendido) return;
    if (vender == null) {
      await _ejecutar(actual.publicacion, actual.operacion);
      return;
    }
    final Publicacion publicacion = actual.publicacion;
    _emitir(GestionEnviando(publicacion, OperacionGestion.marcarVendido));
    try {
      final ResultadoVenta resultado = await vender(publicacion, eleccion);
      _emitir(GestionTerminada(
        publicacion,
        OperacionGestion.marcarVendido,
        actualizada: resultado.publicacion,
        mensaje: resultado.mensaje,
      ));
    } on AccionNoPermitidaFailure catch (falla) {
      _emitir(GestionError(await _recargar(publicacion), falla));
    } on Failure catch (falla) {
      _emitir(GestionError(publicacion, falla));
    } catch (_) {
      _emitir(GestionError(publicacion, const GestionarPublicacionFailure()));
    }
  }

  /// "Cancelar" en la confirmación: no se envía nada.
  void cancelar() {
    final GestionState actual = state;
    if (actual is GestionConfirmando) _emitir(GestionLista(actual.publicacion));
  }

  /// La pantalla ya mostró el error; se vuelve a la lista de acciones.
  void descartarError() {
    final GestionState actual = state;
    if (actual is GestionError) _emitir(GestionLista(actual.publicacion));
  }

  Future<void> _ejecutar(Publicacion publicacion, OperacionGestion operacion) async {
    _emitir(GestionEnviando(publicacion, operacion));
    try {
      if (operacion == OperacionGestion.borrar) {
        await _borrar(publicacion);
        _emitir(GestionTerminada(publicacion, operacion));
      } else {
        final Publicacion actualizada = await _cambiarEstado(publicacion, operacion.accionEstado!);
        _emitir(GestionTerminada(publicacion, operacion, actualizada: actualizada));
      }
    } on AccionNoPermitidaFailure catch (falla) {
      // Escenario 9: el estado cambió en otro lado. Se muestra el actual.
      _emitir(GestionError(await _recargar(publicacion), falla));
    } on Failure catch (falla) {
      _emitir(GestionError(publicacion, falla));
    } catch (_) {
      _emitir(GestionError(publicacion, const GestionarPublicacionFailure()));
    }
  }

  Future<Publicacion> _recargar(Publicacion publicacion) async {
    final ObtenerDetallePublicacion? obtener = _obtenerDetalle;
    if (obtener == null) return publicacion;
    try {
      return await obtener(publicacion.id);
    } catch (_) {
      return publicacion;
    }
  }

  void _emitir(GestionState nuevo) {
    if (!isClosed) emit(nuevo);
  }
}
