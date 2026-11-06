import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:utrueque/features/chat/data/datasources/mensajes_tiempo_real.dart';
import 'package:utrueque/features/chat/data/models/conversacion_model.dart';
import 'package:utrueque/features/chat/data/models/mensaje_model.dart';
import 'package:utrueque/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:utrueque/features/chat/domain/entities/aviso_chat.dart';
import 'package:utrueque/features/chat/domain/entities/mensaje.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';

import '../fixtures.dart';

class _MockDataSource extends Mock implements ChatRemoteDataSource {}

Map<String, dynamic> filaMensaje(String id) => <String, dynamic>{
      'id': id,
      'conversacion_id': idConversacion,
      'autor_id': idVendedor,
      'texto': 'Hola',
      'created_at': '2026-11-06T16:00:00.123456+00:00',
    };

void main() {
  group('MensajeModel', () {
    test('lee una fila del servidor o de Realtime (mismas columnas)', () {
      final MensajeModel m = MensajeModel.fromMap(filaMensaje('m1'));
      expect(m.id, 'm1');
      expect(m.conversacionId, idConversacion);
      expect(m.autorId, idVendedor);
      expect(m.texto, 'Hola');
      expect(m.creadoEn, DateTime.utc(2026, 11, 6, 16, 0, 0, 123, 456));
    });

    test('paraEnviar no manda el autor ni la fecha (los pone el servidor)', () {
      expect(MensajeModel.paraEnviar(idConversacion, 'Hola'), {'conversacion_id': idConversacion, 'texto': 'Hola'});
    });
  });

  group('ConversacionModel', () {
    Map<String, dynamic> fila({String? foto = 'v/1_0.jpg', String? estado = 'reservado', String? nombre = ' Ana '}) =>
        <String, dynamic>{
          'id': idConversacion,
          'publicacion_id': estado == null ? null : 'pub-1',
          'publicacion_titulo': estado == null ? null : 'Calculadora',
          'publicacion_foto': foto,
          'publicacion_estado': estado,
          'soy_vendedor': true,
          'otro_id': idComprador,
          'otro_nombre': nombre,
          'otro_foto_url': 'https://avatars/beto.jpg',
          'ultimo_texto': 'Hola',
          'ultimo_autor_id': idComprador,
          'ultimo_mensaje_en': '2026-11-06T16:05:00+00:00',
          'no_leidos': 2,
          'created_at': '2026-11-06T16:00:00+00:00',
        };

    test('lee la fila de mis_conversaciones y arma la URL de la portada', () {
      final ConversacionModel c = ConversacionModel.fromMap(fila(), urlFoto: (r) => 'https://bucket/$r');
      expect(c.publicacionFotoUrl, 'https://bucket/v/1_0.jpg');
      expect(c.publicacionEstado, const Reservado());
      expect(c.soyVendedor, isTrue);
      expect(c.otroNombre, 'Ana');
      expect(c.otroFotoUrl, 'https://avatars/beto.jpg');
      expect(c.noLeidos, 2);
      expect(c.ultimoMensajeEn, DateTime.utc(2026, 11, 6, 16, 5));
      expect(c.creadaEn, DateTime.utc(2026, 11, 6, 16));
    });

    test('publicación borrada, sin foto, sin nombre y sin mensajes', () {
      final Map<String, dynamic> m = fila(foto: null, estado: null, nombre: '  ')
        ..remove('no_leidos')
        ..['ultimo_mensaje_en'] = null
        ..['soy_vendedor'] = null;
      final ConversacionModel c = ConversacionModel.fromMap(m, urlFoto: (r) => r);
      expect(c.publicacionEliminada, isTrue);
      expect(c.publicacionFotoUrl, isNull);
      expect(c.publicacionEstado, isNull);
      expect(c.otroNombre, 'Estudiante');
      expect(c.noLeidos, 0);
      expect(c.ultimoMensajeEn, isNull);
      expect(c.soyVendedor, isFalse);
    });
  });

  group('ChatRepositoryImpl.avisos (patrón Observer)', () {
    late _MockDataSource fuente;
    late StreamController<EventoTiempoReal> eventos;

    setUp(() {
      fuente = _MockDataSource();
      eventos = StreamController<EventoTiempoReal>();
      when(() => fuente.eventos()).thenAnswer((_) => eventos.stream);
    });

    test('convierte registros en mensajes y la conexión en ChatConectado; ignora registros rotos', () async {
      // ARRANGE
      final Future<List<AvisoChat>> recibidos = ChatRepositoryImpl(fuente).avisos().toList();

      // ACT
      eventos
        ..add(const EventoTiempoReal.conectado())
        ..add(EventoTiempoReal.registro(filaMensaje('m1')))
        ..add(const EventoTiempoReal.registro(<String, dynamic>{'id': 'roto'}));
      await eventos.close();

      // ASSERT
      final List<AvisoChat> lista = await recibidos;
      expect(lista, hasLength(2));
      expect(lista.first, const ChatConectado());
      final Mensaje m = (lista.last as MensajeRecibido).mensaje;
      expect(m.id, 'm1');
    });
  });
}
