import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/trato.dart';
import '../../domain/errors/reputacion_failures.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';

/// Estado de los tratos que faltan por calificar (HU-09, Escenario 3).
class TratosPorCalificarState extends Equatable {
  const TratosPorCalificarState({this.cargando = true, this.tratos = const <TratoPorCalificar>[], this.error});

  final bool cargando;
  final List<TratoPorCalificar> tratos;

  /// No se pudieron cargar. El aviso "Califica tu trato" no se muestra; no
  /// es grave y se vuelve a intentar al regresar.
  final String? error;

  /// El trato de esa conversación del chat, si falta calificarlo.
  TratoPorCalificar? deConversacion(String conversacionId) {
    for (final TratoPorCalificar trato in tratos) {
      if (trato.conversacionId == conversacionId) return trato;
    }
    return null;
  }

  TratosPorCalificarState copyWith({bool? cargando, List<TratoPorCalificar>? tratos, String? Function()? error}) {
    return TratosPorCalificarState(
      cargando: cargando ?? this.cargando,
      tratos: tratos ?? this.tratos,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [cargando, tratos, error];
}

/// Los tratos que el estudiante todavía puede calificar, para el aviso
/// "Califica tu trato" del chat y de Mi perfil.
class TratosPorCalificarCubit extends Cubit<TratosPorCalificarState> {
  TratosPorCalificarCubit(ObtenerTratosPorCalificar obtener, {DateTime Function()? reloj})
      : _obtener = obtener,
        _reloj = reloj ?? DateTime.now,
        super(const TratosPorCalificarState());

  final ObtenerTratosPorCalificar _obtener;
  final DateTime Function() _reloj;

  Future<void> cargar() async {
    _emitir(state.copyWith(cargando: true, error: () => null));
    try {
      final DateTime ahora = _reloj();
      // Escenario 10: por si el servidor tardó, no se ofrecen los vencidos.
      final List<TratoPorCalificar> tratos =
          (await _obtener()).where((t) => !t.vencidoAl(ahora)).toList(growable: false);
      _emitir(state.copyWith(cargando: false, tratos: tratos));
    } catch (error) {
      final String mensaje = error is Failure ? error.mensaje : const ReputacionServidorFailure().mensaje;
      _emitir(state.copyWith(cargando: false, error: () => mensaje));
    }
  }

  /// Escenario 9: ya se calificó (o ya no se puede); el aviso desaparece.
  void quitar(String ventaId) {
    _emitir(state.copyWith(tratos: state.tratos.where((t) => t.ventaId != ventaId).toList(growable: false)));
  }

  void _emitir(TratosPorCalificarState nuevo) {
    if (!isClosed) emit(nuevo);
  }
}
