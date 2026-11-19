import 'package:equatable/equatable.dart';

/// Un estudiante que le escribió al vendedor por una publicación y al que
/// se le puede marcar como comprador (HU-09, Escenario 1).
class CompradorPosible extends Equatable {
  const CompradorPosible({
    required this.conversacionId,
    required this.compradorId,
    required this.nombre,
    this.fotoUrl,
    this.ultimoMensajeEn,
  });

  final String conversacionId;
  final String compradorId;
  final String nombre;
  final String? fotoUrl;
  final DateTime? ultimoMensajeEn;

  @override
  List<Object?> get props => [conversacionId, compradorId, nombre, fotoUrl, ultimoMensajeEn];
}

/// Lo que eligió el vendedor en la hoja "¿A quién se lo vendiste?".
class EleccionVenta extends Equatable {
  /// Se lo vendió a quien tiene la conversación [conversacionId].
  const EleccionVenta.a(String this.conversacionId, {this.nombre});

  /// "Lo vendí fuera de UTrueque" (Escenario 2): nadie califica.
  const EleccionVenta.fueraDeUTrueque()
      : conversacionId = null,
        nombre = null;

  final String? conversacionId;
  final String? nombre;

  bool get fueraDeUTrueque => conversacionId == null;

  @override
  List<Object?> get props => [conversacionId, nombre];
}

/// Un trato que el estudiante con sesión todavía puede calificar
/// (HU-09, Escenarios 3, 4 y 10).
class TratoPorCalificar extends Equatable {
  const TratoPorCalificar({
    required this.ventaId,
    required this.publicacionId,
    required this.publicacionTitulo,
    required this.soyVendedor,
    required this.otroId,
    required this.otroNombre,
    required this.vendidaEn,
    required this.venceEn,
    this.conversacionId,
    this.publicacionFotoUrl,
    this.otroFotoUrl,
  });

  /// Días para calificar después de la venta (decisión 6).
  static const int diasParaCalificar = 14;

  final String ventaId;
  final String? conversacionId;
  final String publicacionId;
  final String publicacionTitulo;
  final String? publicacionFotoUrl;

  /// ¿Califico al comprador (yo vendí) o al vendedor (yo compré)?
  final bool soyVendedor;

  /// A quién se califica.
  final String otroId;
  final String otroNombre;
  final String? otroFotoUrl;

  final DateTime vendidaEn;
  final DateTime venceEn;

  /// Escenario 10: ya pasaron los 14 días.
  bool vencidoAl(DateTime ahora) => !ahora.isBefore(venceEn);

  /// Días completos que quedan (0 el último día).
  int diasRestantesAl(DateTime ahora) {
    if (vencidoAl(ahora)) return 0;
    return venceEn.difference(ahora).inDays;
  }

  /// "Califica tu trato con Ana López".
  String get invitacion => 'Califica tu trato con $otroNombre';

  @override
  List<Object?> get props => [
        ventaId,
        conversacionId,
        publicacionId,
        publicacionTitulo,
        publicacionFotoUrl,
        soyVendedor,
        otroId,
        otroNombre,
        otroFotoUrl,
        vendidaEn,
        venceEn,
      ];
}

/// Una calificación que recibió el estudiante con sesión (Escenario 5).
class CalificacionRecibida extends Equatable {
  const CalificacionRecibida({
    required this.id,
    required this.estrellas,
    required this.creadaEn,
    required this.autorId,
    required this.autorNombre,
    required this.publicacionTitulo,
    required this.comoVendedor,
    this.comentario,
    this.autorFotoUrl,
  });

  final String id;
  final int estrellas;
  final String? comentario;
  final DateTime creadaEn;
  final String autorId;
  final String autorNombre;
  final String? autorFotoUrl;
  final String publicacionTitulo;

  /// ¿Me calificaron como vendedor (o como comprador)?
  final bool comoVendedor;

  @override
  List<Object?> get props =>
      [id, estrellas, comentario, creadaEn, autorId, autorNombre, autorFotoUrl, publicacionTitulo, comoVendedor];
}

/// Una página de calificaciones recibidas (de la más nueva a la más vieja).
class PaginaCalificaciones extends Equatable {
  const PaginaCalificaciones({required this.calificaciones, required this.hayMas});

  final List<CalificacionRecibida> calificaciones;
  final bool hayMas;

  @override
  List<Object?> get props => [calificaciones, hayMas];
}
