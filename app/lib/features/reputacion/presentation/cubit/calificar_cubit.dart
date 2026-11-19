import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/trato.dart';
import '../../domain/errors/reputacion_failures.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';
import '../../domain/validators/calificacion_validator.dart';

/// Estado de la hoja "Calificar" (HU-09).
class CalificarState extends Equatable {
  const CalificarState({
    this.estrellas,
    this.comentario = '',
    this.errorComentario,
    this.enviando = false,
    this.error,
    this.enviada = false,
    this.tratoCerrado = false,
  });

  static const CalificacionValidator _validador = CalificacionValidator();

  /// De 1 a 5, o `null` si todavía no elige.
  final int? estrellas;
  final String comentario;

  /// Escenario 12: el error del campo de comentario.
  final String? errorComentario;

  final bool enviando;

  /// Motivo por el que no se envió (Escenarios 9, 10, 13 y 14). Las
  /// estrellas y el comentario se conservan.
  final String? error;

  /// Escenarios 3 y 4: se guardó.
  final bool enviada;

  /// Escenarios 9 y 10: ese trato ya no se puede calificar (ya se calificó
  /// en otro dispositivo o se venció). La hoja se cierra y el aviso se quita.
  final bool tratoCerrado;

  /// Caracteres escritos, para el contador "12/200".
  int get largoComentario => comentario.trim().length;

  /// ¿Se habilita "Enviar calificación"?
  bool get completa => !enviando && _validador.sePuedeEnviar(estrellas, comentario);

  CalificarState copyWith({
    int? Function()? estrellas,
    String? comentario,
    String? Function()? errorComentario,
    bool? enviando,
    String? Function()? error,
    bool? enviada,
    bool? tratoCerrado,
  }) {
    return CalificarState(
      estrellas: estrellas != null ? estrellas() : this.estrellas,
      comentario: comentario ?? this.comentario,
      errorComentario: errorComentario != null ? errorComentario() : this.errorComentario,
      enviando: enviando ?? this.enviando,
      error: error != null ? error() : this.error,
      enviada: enviada ?? this.enviada,
      tratoCerrado: tratoCerrado ?? this.tratoCerrado,
    );
  }

  @override
  List<Object?> get props => [estrellas, comentario, errorComentario, enviando, error, enviada, tratoCerrado];
}

/// Maneja la hoja "Calificar" de un [trato] (HU-09, Escenarios 3, 4, 9, 10,
/// 12, 13 y 14).
class CalificarCubit extends Cubit<CalificarState> {
  CalificarCubit({required this.trato, required Calificar calificar})
      : _calificar = calificar,
        super(const CalificarState());

  static const String mensajeGracias = '¡Gracias! Tu calificación ayuda a la comunidad.';
  static const CalificacionValidator _validador = CalificacionValidator();

  final TratoPorCalificar trato;
  final Calificar _calificar;

  void elegirEstrellas(int estrellas) {
    if (estrellas < 1 || estrellas > 5) return;
    _emitir(state.copyWith(estrellas: () => estrellas, error: () => null));
  }

  void cambiarComentario(String comentario) {
    _emitir(state.copyWith(
      comentario: comentario,
      errorComentario: () => _validador.validarComentario(comentario),
      error: () => null,
    ));
  }

  /// Devuelve `true` si se guardó. Si no, se muestra el motivo y se
  /// conserva lo elegido.
  Future<bool> enviar() async {
    if (state.enviando || state.enviada) return false;
    _emitir(state.copyWith(enviando: true, error: () => null));
    try {
      await _calificar(trato, estrellas: state.estrellas, comentario: state.comentario);
      _emitir(state.copyWith(enviando: false, enviada: true));
      return true;
    } on CalificacionDuplicadaFailure catch (f) {
      _emitir(state.copyWith(enviando: false, error: () => f.mensaje, tratoCerrado: true));
    } on PlazoVencidoFailure catch (f) {
      _emitir(state.copyWith(enviando: false, error: () => f.mensaje, tratoCerrado: true));
    } on Failure catch (f) {
      _emitir(state.copyWith(enviando: false, error: () => f.mensaje));
    } catch (_) {
      _emitir(state.copyWith(enviando: false, error: () => const ReputacionServidorFailure().mensaje));
    }
    return false;
  }

  void _emitir(CalificarState nuevo) {
    if (!isClosed) emit(nuevo);
  }
}
