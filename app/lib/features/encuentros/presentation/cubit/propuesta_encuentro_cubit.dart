import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../chat/domain/entities/conversacion.dart';
import '../../../chat/domain/errors/chat_failures.dart';
import '../../domain/entities/encuentro.dart';
import '../../domain/entities/punto_encuentro.dart';
import '../../domain/factories/creadores_solicitud.dart';
import '../../domain/usecases/enviar_solicitud_encuentro.dart';
import '../../domain/usecases/obtener_puntos_encuentro.dart';
import '../../domain/validators/horario_encuentro.dart';
import 'propuesta_encuentro_state.dart';

/// Maneja la hoja "Proponer punto de encuentro" (HU-08, Escenarios 1, 5,
/// 6, 7, 12, 13 y 14).
///
/// Solo ofrece lugares del catálogo y horarios permitidos. Al enviar usa el
/// [CreadorPropuesta] del patrón Factory Method.
class PropuestaEncuentroCubit extends Cubit<PropuestaEncuentroState> {
  PropuestaEncuentroCubit({
    required Conversacion conversacion,
    required ObtenerPuntosEncuentro obtenerPuntos,
    required EnviarSolicitudEncuentro enviarSolicitud,
    this.encuentroActivo,
    DateTime Function()? reloj,
    HorarioEncuentro horario = const HorarioEncuentro(),
  })  : _conversacion = conversacion,
        _obtenerPuntos = obtenerPuntos,
        _enviar = enviarSolicitud,
        _reloj = reloj ?? DateTime.now,
        _horario = horario,
        super(const PropuestaEncuentroState());

  final Conversacion _conversacion;
  final ObtenerPuntosEncuentro _obtenerPuntos;
  final EnviarSolicitudEncuentro _enviar;
  final DateTime Function() _reloj;
  final HorarioEncuentro _horario;

  /// El encuentro pendiente o confirmado de la conversación (Escenario 7).
  final Encuentro? encuentroActivo;

  /// Carga el catálogo (también es "Reintentar") y los días permitidos. Se
  /// elige el primer día disponible.
  Future<void> cargar() async {
    final DateTime ahora = _reloj();
    final List<DateTime> dias = _horario.diasDisponibles(ahora: ahora);
    final DateTime? primerDia = dias.isEmpty ? null : dias.first;
    _emitir(state.copyWith(
      cargando: true,
      errorCatalogo: () => null,
      dias: dias,
      dia: () => primerDia,
      horas: primerDia == null ? const <DateTime>[] : _horario.horasDisponibles(primerDia, ahora: ahora),
      hora: () => null,
    ));
    try {
      final List<PuntoEncuentro> puntos = await _obtenerPuntos();
      _emitir(state.copyWith(cargando: false, puntos: puntos));
    } catch (error) {
      _emitir(state.copyWith(cargando: false, errorCatalogo: () => _comoFailure(error).mensaje));
    }
  }

  void elegirPunto(PuntoEncuentro punto) => _emitir(state.copyWith(punto: () => punto, error: () => null));

  /// Al cambiar de día se borra la hora elegida.
  void elegirDia(DateTime dia) {
    _emitir(state.copyWith(
      dia: () => dia,
      horas: _horario.horasDisponibles(dia, ahora: _reloj()),
      hora: () => null,
      error: () => null,
    ));
  }

  void elegirHora(DateTime hora) => _emitir(state.copyWith(hora: () => hora, error: () => null));

  /// Escenario 1. Devuelve `true` si se envió (la hoja se cierra). Si no,
  /// se muestra el motivo y se conserva lo elegido.
  Future<bool> enviar() async {
    if (state.enviando) return false;
    _emitir(state.copyWith(enviando: true, error: () => null));
    try {
      await _enviar(CreadorPropuesta(
        conversacion: _conversacion,
        punto: state.punto,
        fechaHora: state.hora,
        catalogo: state.puntos,
        encuentroActivo: encuentroActivo,
        reloj: _reloj,
        horario: _horario,
      ));
      _emitir(state.copyWith(enviando: false));
      return true;
    } catch (error) {
      _emitir(state.copyWith(enviando: false, error: () => _comoFailure(error).mensaje));
      return false;
    }
  }

  static Failure _comoFailure(Object error) => error is Failure ? error : const ChatServidorFailure();

  void _emitir(PropuestaEncuentroState nuevo) {
    if (!isClosed) emit(nuevo);
  }
}
