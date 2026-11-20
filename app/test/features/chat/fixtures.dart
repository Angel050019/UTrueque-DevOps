import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/chat/domain/entities/conversacion.dart';
import 'package:utrueque/features/chat/domain/entities/mensaje.dart';
import 'package:utrueque/features/chat/domain/entities/pagina_mensajes.dart';
import 'package:utrueque/features/chat/domain/repositories/chat_repository.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockRed extends Mock implements NetworkInfo {}

/// El interesado (comprador) es el estudiante con sesión en casi todas las
/// pruebas; el vendedor es el dueño de la publicación.
const String idComprador = '7f1c2a9e-0000-4000-8000-000000000001';
const String idVendedor = '7f1c2a9e-0000-4000-8000-000000000002';
const String idConversacion = 'conv-1';

final DateTime hace10 = DateTime.utc(2026, 11, 6, 16, 0);

/// Publicación del vendedor, como llega al Detalle.
Publicacion publicacionDelVendedor({EstadoPublicacion estado = const Disponible(), String? duenoNombre = 'Ana López'}) {
  return Publicacion(
    id: 'pub-1',
    usuarioId: idVendedor,
    titulo: 'Calculadora Casio fx-991',
    descripcion: 'Calculadora científica en buen estado.',
    categoriaId: 2,
    categoriaNombre: 'Calculadoras',
    modalidad: Modalidad.venta,
    precio: 350,
    estado: estado,
    fotos: const ['$idVendedor/1_0.jpg'],
    fotosUrls: const ['https://fotos/1.jpg'],
    portadaUrl: 'https://fotos/1.jpg',
    creadaEn: DateTime.utc(2026, 11, 5),
    duenoNombre: duenoNombre,
    duenoFotoUrl: 'https://avatars/ana.jpg',
  );
}

/// La conversación vista por el comprador.
Conversacion conversacion({
  String id = idConversacion,
  EstadoPublicacion? estado = const Disponible(),
  bool eliminada = false,
  int noLeidos = 0,
  String? ultimoTexto,
  DateTime? ultimoMensajeEn,
  bool soyVendedor = false,
}) {
  return Conversacion(
    id: id,
    soyVendedor: soyVendedor,
    otroId: soyVendedor ? idComprador : idVendedor,
    otroNombre: soyVendedor ? 'Beto Ruiz' : 'Ana López',
    publicacionId: eliminada ? null : 'pub-1',
    publicacionTitulo: eliminada ? null : 'Calculadora Casio fx-991',
    publicacionEstado: eliminada ? null : estado,
    ultimoTexto: ultimoTexto,
    ultimoAutorId: ultimoTexto == null ? null : idVendedor,
    ultimoMensajeEn: ultimoMensajeEn,
    noLeidos: noLeidos,
    creadaEn: hace10,
  );
}

/// Un mensaje [n] minutos después de [hace10].
Mensaje mensaje(String id, {String autor = idVendedor, String conv = idConversacion, int minuto = 0, String? texto}) {
  return Mensaje(
    id: id,
    conversacionId: conv,
    autorId: autor,
    texto: texto ?? 'Mensaje $id',
    creadoEn: hace10.add(Duration(minutes: minuto)),
  );
}

CursorFeed cursorMensaje(String id) => CursorFeed(fecha: '2026-11-06T16:00:00.123456+00:00', id: id);

/// Página con los mensajes de esos [ids], los MÁS NUEVOS primero (como el
/// servidor). Cada id es un minuto más viejo que el anterior.
PaginaMensajes paginaDe(List<String> ids, {bool hayAnteriores = false, int desde = 100}) {
  return PaginaMensajes(
    mensajes: <Mensaje>[for (int i = 0; i < ids.length; i++) mensaje(ids[i], minuto: desde - i)],
    siguiente: hayAnteriores ? cursorMensaje(ids.last) : null,
  );
}
