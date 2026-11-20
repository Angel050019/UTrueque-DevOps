import 'package:equatable/equatable.dart';

import 'punto_encuentro.dart';

/// Estados de un encuentro (HU-08). Los guarda la base de datos:
///
///   propuesto ──▶ aceptado | rechazado | cancelado | vencido
///   aceptado  ──▶ cancelado | concluido
enum EstadoEncuentro {
  propuesto('propuesto', 'Esperando respuesta'),
  aceptado('aceptado', 'Confirmado'),
  rechazado('rechazado', 'Rechazada'),
  cancelado('cancelado', 'Cancelada'),
  vencido('vencido', 'Venció'),
  concluido('concluido', 'Ya pasó');

  const EstadoEncuentro(this.valor, this.etiqueta);

  /// Texto que se guarda en la columna `estado`.
  final String valor;

  /// Texto para la tarjeta.
  final String etiqueta;

  /// Un valor desconocido se toma como cancelado (sin botones).
  static EstadoEncuentro desdeValor(String? valor) =>
      EstadoEncuentro.values.firstWhere((e) => e.valor == valor, orElse: () => EstadoEncuentro.cancelado);
}

/// Una propuesta de punto de encuentro dentro de una conversación (HU-08).
class Encuentro extends Equatable {
  const Encuentro({
    required this.id,
    required this.conversacionId,
    required this.propuestoPor,
    required this.punto,
    required this.fechaHora,
    required this.estado,
    required this.creadoEn,
  });

  final String id;
  final String conversacionId;

  /// Quién hizo la propuesta.
  final String propuestoPor;
  final PuntoEncuentro punto;
  final DateTime fechaHora;

  /// Estado que mandó el servidor.
  final EstadoEncuentro estado;
  final DateTime creadoEn;

  /// ¿La propuso el estudiante [idUsuario]?
  bool esDe(String? idUsuario) => idUsuario != null && idUsuario == propuestoPor;

  /// El estado considerando la hora: una propuesta o un encuentro cuya hora
  /// ya pasó dejan de estar activos (Escenario 9), aunque el servidor no lo
  /// haya actualizado todavía.
  EstadoEncuentro estadoAl(DateTime ahora) {
    if (!fechaHora.isAfter(ahora)) {
      if (estado == EstadoEncuentro.propuesto) return EstadoEncuentro.vencido;
      if (estado == EstadoEncuentro.aceptado) return EstadoEncuentro.concluido;
    }
    return estado;
  }

  /// Pendiente o confirmado (Escenario 7: solo puede haber uno).
  bool estaActivo(DateTime ahora) {
    final EstadoEncuentro e = estadoAl(ahora);
    return e == EstadoEncuentro.propuesto || e == EstadoEncuentro.aceptado;
  }

  /// Escenarios 2, 3 y 8: solo el OTRO responde una propuesta pendiente.
  bool puedeResponder(String? miId, DateTime ahora) =>
      estadoAl(ahora) == EstadoEncuentro.propuesto && !esDe(miId);

  /// Escenario 4: una propuesta, solo quien la hizo; un confirmado,
  /// cualquiera de los dos.
  bool puedeCancelar(String? miId, DateTime ahora) {
    final EstadoEncuentro e = estadoAl(ahora);
    return (e == EstadoEncuentro.propuesto && esDe(miId)) || e == EstadoEncuentro.aceptado;
  }

  @override
  List<Object?> get props => [id, conversacionId, propuestoPor, punto, fechaHora, estado, creadoEn];
}
