import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/trato.dart';
import '../../domain/errors/reputacion_failures.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';

/// Estado de la hoja "¿A quién se lo vendiste?" (HU-09, Escenarios 1 y 2).
class ElegirCompradorState extends Equatable {
  const ElegirCompradorState({
    this.cargando = true,
    this.compradores = const <CompradorPosible>[],
    this.eleccion,
    this.error,
  });

  final bool cargando;

  /// Quienes le escribieron por la publicación.
  final List<CompradorPosible> compradores;

  /// Lo que eligió (alguien de la lista o "fuera de UTrueque").
  final EleccionVenta? eleccion;

  /// No se pudo cargar la lista. Aun así se puede elegir "fuera de UTrueque".
  final String? error;

  bool get completa => eleccion != null;

  ElegirCompradorState copyWith({
    bool? cargando,
    List<CompradorPosible>? compradores,
    EleccionVenta? Function()? eleccion,
    String? Function()? error,
  }) {
    return ElegirCompradorState(
      cargando: cargando ?? this.cargando,
      compradores: compradores ?? this.compradores,
      eleccion: eleccion != null ? eleccion() : this.eleccion,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [cargando, compradores, eleccion, error];
}

/// Carga quiénes le escribieron al vendedor por [publicacionId] y guarda lo
/// que elige.
class ElegirCompradorCubit extends Cubit<ElegirCompradorState> {
  ElegirCompradorCubit({required this.publicacionId, required ObtenerCompradoresPosibles obtener})
      : _obtener = obtener,
        super(const ElegirCompradorState());

  final String publicacionId;
  final ObtenerCompradoresPosibles _obtener;

  /// También es "Reintentar".
  Future<void> cargar() async {
    _emitir(state.copyWith(cargando: true, error: () => null));
    try {
      final List<CompradorPosible> compradores = await _obtener(publicacionId);
      // Si el elegido ya no está en la lista, se borra la elección.
      final EleccionVenta? eleccion = state.eleccion;
      final bool sigue = eleccion == null ||
          eleccion.fueraDeUTrueque ||
          compradores.any((c) => c.conversacionId == eleccion.conversacionId);
      _emitir(state.copyWith(cargando: false, compradores: compradores, eleccion: sigue ? null : () => null));
    } catch (error) {
      final String mensaje = error is Failure ? error.mensaje : const ReputacionServidorFailure().mensaje;
      _emitir(state.copyWith(cargando: false, error: () => mensaje));
    }
  }

  void elegir(CompradorPosible comprador) =>
      _emitir(state.copyWith(eleccion: () => EleccionVenta.a(comprador.conversacionId, nombre: comprador.nombre)));

  void elegirFueraDeUTrueque() => _emitir(state.copyWith(eleccion: () => const EleccionVenta.fueraDeUTrueque()));

  void _emitir(ElegirCompradorState nuevo) {
    if (!isClosed) emit(nuevo);
  }
}
