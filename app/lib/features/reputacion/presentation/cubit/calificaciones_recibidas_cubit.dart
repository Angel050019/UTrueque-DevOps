import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/trato.dart';
import '../../domain/errors/reputacion_failures.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';

/// Estado de "Calificaciones que recibí" en Mi perfil (HU-09, Escenario 5).
class CalificacionesRecibidasState extends Equatable {
  const CalificacionesRecibidasState({
    this.cargando = true,
    this.calificaciones = const <CalificacionRecibida>[],
    this.hayMas = false,
    this.cargandoMas = false,
    this.error,
    this.errorMas,
  });

  final bool cargando;
  final List<CalificacionRecibida> calificaciones;
  final bool hayMas;
  final bool cargandoMas;

  /// No se pudo cargar la primera página.
  final String? error;

  /// No se pudo cargar la página siguiente (lo cargado se conserva).
  final String? errorMas;

  CalificacionesRecibidasState copyWith({
    bool? cargando,
    List<CalificacionRecibida>? calificaciones,
    bool? hayMas,
    bool? cargandoMas,
    String? Function()? error,
    String? Function()? errorMas,
  }) {
    return CalificacionesRecibidasState(
      cargando: cargando ?? this.cargando,
      calificaciones: calificaciones ?? this.calificaciones,
      hayMas: hayMas ?? this.hayMas,
      cargandoMas: cargandoMas ?? this.cargandoMas,
      error: error != null ? error() : this.error,
      errorMas: errorMas != null ? errorMas() : this.errorMas,
    );
  }

  @override
  List<Object?> get props => [cargando, calificaciones, hayMas, cargandoMas, error, errorMas];
}

/// Las calificaciones que recibió el estudiante, de la más nueva a la más
/// vieja, por páginas.
class CalificacionesRecibidasCubit extends Cubit<CalificacionesRecibidasState> {
  CalificacionesRecibidasCubit(ObtenerCalificacionesRecibidas obtener)
      : _obtener = obtener,
        super(const CalificacionesRecibidasState());

  final ObtenerCalificacionesRecibidas _obtener;

  /// Primera página (también es "Reintentar").
  Future<void> cargar() async {
    _emitir(state.copyWith(cargando: true, error: () => null, errorMas: () => null));
    try {
      final PaginaCalificaciones pagina = await _obtener();
      _emitir(CalificacionesRecibidasState(
        cargando: false,
        calificaciones: pagina.calificaciones,
        hayMas: pagina.hayMas,
      ));
    } catch (error) {
      _emitir(state.copyWith(cargando: false, error: () => _mensaje(error)));
    }
  }

  /// "Ver más": la página siguiente, sin repetir ninguna.
  Future<void> cargarMas() async {
    if (state.cargando || state.cargandoMas || !state.hayMas || state.calificaciones.isEmpty) return;
    _emitir(state.copyWith(cargandoMas: true, errorMas: () => null));
    try {
      final PaginaCalificaciones pagina = await _obtener(despuesDe: state.calificaciones.last);
      final Set<String> vistas = state.calificaciones.map((c) => c.id).toSet();
      _emitir(state.copyWith(
        cargandoMas: false,
        calificaciones: <CalificacionRecibida>[
          ...state.calificaciones,
          ...pagina.calificaciones.where((c) => !vistas.contains(c.id)),
        ],
        hayMas: pagina.hayMas,
      ));
    } catch (error) {
      _emitir(state.copyWith(cargandoMas: false, errorMas: () => _mensaje(error)));
    }
  }

  static String _mensaje(Object error) =>
      error is Failure ? error.mensaje : const ReputacionServidorFailure().mensaje;

  void _emitir(CalificacionesRecibidasState nuevo) {
    if (!isClosed) emit(nuevo);
  }
}
