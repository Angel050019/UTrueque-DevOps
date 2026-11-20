import 'package:equatable/equatable.dart';

import '../../../publicaciones/domain/entities/estado_publicacion.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import 'mensaje.dart';

/// Una conversación entre el interesado (comprador) y el dueño (vendedor)
/// de una publicación (HU-07), vista por el estudiante con sesión.
///
/// SEGURIDAD: del otro estudiante solo se conoce su nombre a mostrar y su
/// foto; nunca su correo.
class Conversacion extends Equatable {
  const Conversacion({
    required this.id,
    required this.soyVendedor,
    required this.otroId,
    required this.otroNombre,
    required this.creadaEn,
    this.publicacionId,
    this.publicacionTitulo,
    this.publicacionFotoUrl,
    this.publicacionEstado,
    this.otroFotoUrl,
    this.ultimoTexto,
    this.ultimoAutorId,
    this.ultimoMensajeEn,
    this.noLeidos = 0,
  });

  /// La conversación que se abre desde el Detalle de [publicacion] con
  /// "Contactar al vendedor" (Escenarios 1 y 2): el otro es el vendedor.
  factory Conversacion.desdePublicacion(String id, Publicacion publicacion, {DateTime? creadaEn}) {
    return Conversacion(
      id: id,
      soyVendedor: false,
      otroId: publicacion.usuarioId,
      otroNombre: publicacion.duenoNombre ?? 'Vendedor',
      otroFotoUrl: publicacion.duenoFotoUrl,
      publicacionId: publicacion.id,
      publicacionTitulo: publicacion.titulo,
      publicacionFotoUrl: publicacion.portadaUrl,
      publicacionEstado: publicacion.estado,
      creadaEn: creadaEn ?? DateTime.now(),
    );
  }

  final String id;

  /// `null` si la publicación se borró: la conversación queda para leer.
  final String? publicacionId;
  final String? publicacionTitulo;
  final String? publicacionFotoUrl;
  final EstadoPublicacion? publicacionEstado;

  /// ¿El estudiante con sesión es el dueño de la publicación?
  final bool soyVendedor;

  /// El otro participante.
  final String otroId;
  final String otroNombre;
  final String? otroFotoUrl;

  final String? ultimoTexto;
  final String? ultimoAutorId;
  final DateTime? ultimoMensajeEn;

  /// Mensajes del otro que el estudiante no ha leído (Escenario 8).
  final int noLeidos;

  final DateTime creadaEn;

  bool get publicacionEliminada => publicacionId == null;

  /// Escenario 11: se puede escribir mientras la publicación exista y no
  /// esté Vendida (patrón State de HU-06).
  bool get aceptaMensajes => !publicacionEliminada && !(publicacionEstado?.esFinal ?? false);

  String get tituloVisible => publicacionTitulo ?? 'Publicación eliminada';

  /// Fecha para ordenar la bandeja: la del último mensaje o la de creación.
  DateTime get fechaOrden => ultimoMensajeEn ?? creadaEn;

  /// Escenario 3: llegó (o se envió) [mensaje]. Si no es mío, suma un no leído.
  Conversacion conMensaje(Mensaje mensaje, {required String? miId}) {
    return _copiar(
      ultimoTexto: mensaje.texto,
      ultimoAutorId: mensaje.autorId,
      ultimoMensajeEn: mensaje.creadoEn,
      noLeidos: mensaje.esDe(miId) ? noLeidos : noLeidos + 1,
    );
  }

  /// Escenario 8: el estudiante ya la leyó.
  Conversacion leida() => _copiar(noLeidos: 0);

  Conversacion _copiar({String? ultimoTexto, String? ultimoAutorId, DateTime? ultimoMensajeEn, int? noLeidos}) {
    return Conversacion(
      id: id,
      soyVendedor: soyVendedor,
      otroId: otroId,
      otroNombre: otroNombre,
      otroFotoUrl: otroFotoUrl,
      publicacionId: publicacionId,
      publicacionTitulo: publicacionTitulo,
      publicacionFotoUrl: publicacionFotoUrl,
      publicacionEstado: publicacionEstado,
      ultimoTexto: ultimoTexto ?? this.ultimoTexto,
      ultimoAutorId: ultimoAutorId ?? this.ultimoAutorId,
      ultimoMensajeEn: ultimoMensajeEn ?? this.ultimoMensajeEn,
      noLeidos: noLeidos ?? this.noLeidos,
      creadaEn: creadaEn,
    );
  }

  @override
  List<Object?> get props => [
        id,
        publicacionId,
        publicacionTitulo,
        publicacionFotoUrl,
        publicacionEstado,
        soyVendedor,
        otroId,
        otroNombre,
        otroFotoUrl,
        ultimoTexto,
        ultimoAutorId,
        ultimoMensajeEn,
        noLeidos,
        creadaEn,
      ];
}
