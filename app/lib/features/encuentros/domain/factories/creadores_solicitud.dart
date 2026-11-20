import '../../../chat/domain/entities/conversacion.dart';
import '../../../chat/domain/errors/chat_failures.dart';
import '../entities/encuentro.dart';
import '../entities/punto_encuentro.dart';
import '../entities/solicitud_encuentro.dart';
import '../errors/encuentro_failures.dart';
import '../validators/horario_encuentro.dart';

/// HU-08, patrón **Factory Method** (issue #3): el CREADOR.
///
/// Cada creador recibe los datos de una acción (proponer, responder o
/// cancelar), revisa en el celular las reglas que se pueden revisar sin
/// red y FABRICA la solicitud correcta con [crear]. Si algo no se cumple,
/// lanza el fallo con el mensaje para el estudiante y no se llama al
/// servidor.
///
/// Quien usa el creador (`EnviarSolicitudEncuentro`) solo conoce este tipo
/// abstracto: no sabe qué solicitud se fabrica ni qué reglas tiene. Para
/// una acción nueva basta con un creador nuevo.
///
/// El servidor vuelve a revisar TODO (SEGURIDAD: no confiar en el cliente).
abstract class CreadorSolicitudEncuentro {
  const CreadorSolicitudEncuentro();

  /// El Factory Method.
  SolicitudEncuentro crear();
}

/// Fabrica una [PropuestaEncuentro] (Escenarios 1, 5, 6, 7 y 10).
class CreadorPropuesta extends CreadorSolicitudEncuentro {
  CreadorPropuesta({
    required this.conversacion,
    required this.punto,
    required this.fechaHora,
    required this.catalogo,
    this.encuentroActivo,
    DateTime Function()? reloj,
    this.horario = const HorarioEncuentro(),
  }) : _reloj = reloj ?? DateTime.now;

  final Conversacion conversacion;
  final PuntoEncuentro? punto;
  final DateTime? fechaHora;

  /// Los lugares que entregó el servidor. Un lugar que no esté aquí no se
  /// envía (Escenario 5).
  final List<PuntoEncuentro> catalogo;

  /// El encuentro pendiente o confirmado de la conversación, si hay.
  final Encuentro? encuentroActivo;
  final HorarioEncuentro horario;
  final DateTime Function() _reloj;

  @override
  SolicitudEncuentro crear() {
    if (!conversacion.aceptaMensajes) throw const ConversacionCerradaFailure();
    if (encuentroActivo != null) throw const EncuentroActivoFailure();
    final PuntoEncuentro? lugar = punto;
    if (lugar == null || !catalogo.any((p) => p.id == lugar.id)) throw const PuntoNoPermitidoFailure();
    final DateTime? cuando = fechaHora;
    if (cuando == null || !horario.esValido(cuando, ahora: _reloj())) throw const HorarioNoPermitidoFailure();
    return PropuestaEncuentro(conversacionId: conversacion.id, puntoId: lugar.id, fechaHora: cuando.toUtc());
  }
}

/// Fabrica una [RespuestaEncuentro]: aceptar o rechazar (Escenarios 2, 3,
/// 8 y 9).
class CreadorRespuesta extends CreadorSolicitudEncuentro {
  CreadorRespuesta({required this.encuentro, required this.miId, required this.acepta, DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now;

  final Encuentro encuentro;
  final String? miId;
  final bool acepta;
  final DateTime Function() _reloj;

  @override
  SolicitudEncuentro crear() {
    if (encuentro.esDe(miId)) throw const EncuentroPropioFailure();
    final EstadoEncuentro estado = encuentro.estadoAl(_reloj());
    if (estado == EstadoEncuentro.vencido) throw const EncuentroVencidoFailure();
    if (estado != EstadoEncuentro.propuesto) throw const EncuentroNoPendienteFailure();
    return RespuestaEncuentro(encuentroId: encuentro.id, acepta: acepta);
  }
}

/// Fabrica una [CancelacionEncuentro] (Escenario 4).
class CreadorCancelacion extends CreadorSolicitudEncuentro {
  CreadorCancelacion({required this.encuentro, required this.miId, DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now;

  final Encuentro encuentro;
  final String? miId;
  final DateTime Function() _reloj;

  @override
  SolicitudEncuentro crear() {
    final DateTime ahora = _reloj();
    if (!encuentro.estaActivo(ahora)) throw const EncuentroNoActivoFailure();
    if (!encuentro.puedeCancelar(miId, ahora)) throw const CancelarNoPermitidoFailure();
    return CancelacionEncuentro(encuentroId: encuentro.id);
  }
}
