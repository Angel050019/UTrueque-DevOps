import 'package:equatable/equatable.dart';

import '../../domain/entities/encuentro.dart';

/// Estado de los encuentros de UNA conversación (HU-08): con esto el chat
/// dibuja las tarjetas, el aviso fijo del encuentro confirmado y habilita
/// o no el botón "Proponer punto de encuentro".
class EncuentrosState extends Equatable {
  const EncuentrosState({
    this.encuentros = const <Encuentro>[],
    this.cargado = false,
    this.enviando = false,
    this.cerradaPorServidor = false,
    this.aviso,
    this.avisoEsError = true,
  });

  /// El más reciente primero.
  final List<Encuentro> encuentros;

  /// Ya se cargó al menos una vez (antes no se puede proponer).
  final bool cargado;

  /// Se está aceptando, rechazando o cancelando (los botones se deshabilitan).
  final bool enviando;

  /// El servidor avisó que la publicación se vendió o se borró.
  final bool cerradaPorServidor;

  /// Mensaje de un solo uso (SnackBar).
  final String? aviso;
  final bool avisoEsError;

  /// El encuentro de una tarjeta, o `null` si todavía no se carga.
  Encuentro? porId(String? id) {
    if (id == null) return null;
    for (final Encuentro e in encuentros) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Escenario 7: el encuentro pendiente o confirmado, si hay.
  Encuentro? activoAl(DateTime ahora) {
    for (final Encuentro e in encuentros) {
      if (e.estaActivo(ahora)) return e;
    }
    return null;
  }

  /// Escenario 2: el encuentro confirmado para el aviso fijo, si hay.
  Encuentro? confirmadoAl(DateTime ahora) {
    final Encuentro? activo = activoAl(ahora);
    return activo != null && activo.estadoAl(ahora) == EstadoEncuentro.aceptado ? activo : null;
  }

  EncuentrosState copyWith({
    List<Encuentro>? encuentros,
    bool? cargado,
    bool? enviando,
    bool? cerradaPorServidor,
    String? Function()? aviso,
    bool? avisoEsError,
  }) {
    return EncuentrosState(
      encuentros: encuentros ?? this.encuentros,
      cargado: cargado ?? this.cargado,
      enviando: enviando ?? this.enviando,
      cerradaPorServidor: cerradaPorServidor ?? this.cerradaPorServidor,
      aviso: aviso != null ? aviso() : this.aviso,
      avisoEsError: avisoEsError ?? this.avisoEsError,
    );
  }

  @override
  List<Object?> get props => [encuentros, cargado, enviando, cerradaPorServidor, aviso, avisoEsError];
}
