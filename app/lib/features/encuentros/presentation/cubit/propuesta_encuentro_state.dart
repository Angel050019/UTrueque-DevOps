import 'package:equatable/equatable.dart';

import '../../domain/entities/punto_encuentro.dart';

/// Estado de la hoja "Proponer punto de encuentro" (HU-08).
class PropuestaEncuentroState extends Equatable {
  const PropuestaEncuentroState({
    this.cargando = true,
    this.errorCatalogo,
    this.puntos = const <PuntoEncuentro>[],
    this.dias = const <DateTime>[],
    this.horas = const <DateTime>[],
    this.punto,
    this.dia,
    this.hora,
    this.enviando = false,
    this.error,
  });

  /// Se está pidiendo el catálogo de lugares.
  final bool cargando;

  /// No se pudo cargar el catálogo (sin conexión o error).
  final String? errorCatalogo;

  /// Escenario 5: solo los lugares del catálogo oficial.
  final List<PuntoEncuentro> puntos;

  /// Escenario 6: solo los días y horarios permitidos.
  final List<DateTime> dias;
  final List<DateTime> horas;

  final PuntoEncuentro? punto;
  final DateTime? dia;
  final DateTime? hora;

  final bool enviando;

  /// Motivo por el que no se envió (Escenarios 5, 6, 7, 12, 13 y 14). Lo
  /// que se eligió se conserva.
  final String? error;

  /// El botón "Enviar propuesta" está habilitado.
  bool get completa => punto != null && hora != null && !enviando;

  PropuestaEncuentroState copyWith({
    bool? cargando,
    String? Function()? errorCatalogo,
    List<PuntoEncuentro>? puntos,
    List<DateTime>? dias,
    List<DateTime>? horas,
    PuntoEncuentro? Function()? punto,
    DateTime? Function()? dia,
    DateTime? Function()? hora,
    bool? enviando,
    String? Function()? error,
  }) {
    return PropuestaEncuentroState(
      cargando: cargando ?? this.cargando,
      errorCatalogo: errorCatalogo != null ? errorCatalogo() : this.errorCatalogo,
      puntos: puntos ?? this.puntos,
      dias: dias ?? this.dias,
      horas: horas ?? this.horas,
      punto: punto != null ? punto() : this.punto,
      dia: dia != null ? dia() : this.dia,
      hora: hora != null ? hora() : this.hora,
      enviando: enviando ?? this.enviando,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [cargando, errorCatalogo, puntos, dias, horas, punto, dia, hora, enviando, error];
}
