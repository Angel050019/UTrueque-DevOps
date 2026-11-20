import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/chat/domain/entities/aviso_chat.dart';
import 'package:utrueque/features/chat/domain/entities/conversacion.dart';
import 'package:utrueque/features/chat/domain/entities/mensaje.dart';
import 'package:utrueque/features/chat/domain/entities/pagina_mensajes.dart';
import 'package:utrueque/features/chat/domain/errors/chat_failures.dart';
import 'package:utrueque/features/chat/domain/usecases/enviar_mensaje.dart';
import 'package:utrueque/features/chat/domain/usecases/escuchar_chat.dart';
import 'package:utrueque/features/chat/domain/usecases/iniciar_conversacion.dart';
import 'package:utrueque/features/chat/domain/usecases/marcar_conversacion_leida.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_conversaciones.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_mensajes.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_total_no_leidos.dart';
import 'package:utrueque/features/chat/domain/validators/mensaje_validator.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';

import '../fixtures.dart';

void main() {
  late MockChatRepository repo;
  late MockRed red;

  setUpAll(() => registerFallbackValue(cursorMensaje('x')));

  setUp(() {
    repo = MockChatRepository();
    red = MockRed();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  void sinRed() => when(() => red.estaConectado).thenAnswer((_) async => false);

  group('IniciarConversacion (Escenarios 1, 2 y 4)', () {
    test('abre la conversación y la arma con los datos de la publicación', () async {
      // ARRANGE
      when(() => repo.iniciarConversacion('pub-1')).thenAnswer((_) async => 'conv-9');

      // ACT
      final Conversacion c = await IniciarConversacion(repo, red)(publicacionDelVendedor(), miId: idComprador);

      // ASSERT
      expect(c.id, 'conv-9');
      expect(c.otroNombre, 'Ana López');
      verify(() => repo.iniciarConversacion('pub-1')).called(1);
    });

    test('Escenario 4: una publicación propia no se contacta ni llama al servidor', () async {
      await expectLater(
        IniciarConversacion(repo, red)(publicacionDelVendedor(), miId: idVendedor),
        throwsA(isA<PublicacionPropiaFailure>()),
      );
      verifyNever(() => repo.iniciarConversacion(any()));
    });

    test('Escenario 14: sin conexión no llama al servidor', () async {
      sinRed();
      await expectLater(
        IniciarConversacion(repo, red)(publicacionDelVendedor(), miId: idComprador),
        throwsA(isA<SinConexionFailure>()),
      );
      verifyNever(() => repo.iniciarConversacion(any()));
    });

    test('Escenarios 5 y 6: deja pasar el rechazo del servidor', () async {
      when(() => repo.iniciarConversacion(any())).thenThrow(const PerfilIncompletoChatFailure());
      await expectLater(
        IniciarConversacion(repo, red)(publicacionDelVendedor(), miId: idComprador),
        throwsA(isA<PerfilIncompletoChatFailure>()),
      );
    });
  });

  group('ObtenerConversaciones (Escenario 7)', () {
    test('trae la bandeja', () async {
      when(() => repo.obtenerConversaciones()).thenAnswer((_) async => [conversacion()]);
      expect(await ObtenerConversaciones(repo, red)(), [conversacion()]);
    });

    test('sin conexión no llama al servidor', () async {
      sinRed();
      await expectLater(ObtenerConversaciones(repo, red)(), throwsA(isA<SinConexionFailure>()));
      verifyNever(() => repo.obtenerConversaciones());
    });
  });

  group('ObtenerMensajes (Escenarios 2 y 9)', () {
    test('pide los últimos 30 y, con cursor, los anteriores', () async {
      when(() => repo.obtenerMensajes(any(), antesDe: any(named: 'antesDe'), limite: any(named: 'limite')))
          .thenAnswer((_) async => paginaDe(['m1']));

      await ObtenerMensajes(repo, red)(idConversacion);
      await ObtenerMensajes(repo, red)(idConversacion, antesDe: cursorMensaje('m1'));

      verify(() => repo.obtenerMensajes(idConversacion, antesDe: null, limite: 30)).called(1);
      verify(() => repo.obtenerMensajes(idConversacion, antesDe: cursorMensaje('m1'), limite: 30)).called(1);
    });

    test('sin conexión no llama al servidor', () async {
      sinRed();
      await expectLater(ObtenerMensajes(repo, red)(idConversacion), throwsA(isA<SinConexionFailure>()));
    });
  });

  group('EnviarMensaje (Escenarios 3, 10, 11 y 14)', () {
    test('envía el texto sin espacios de sobra', () async {
      // ARRANGE
      when(() => repo.enviarMensaje(any(), any())).thenAnswer((_) async => mensaje('m1', autor: idComprador));

      // ACT
      final Mensaje m = await EnviarMensaje(repo, red)(conversacion(), '  ¿Sigue disponible?  ');

      // ASSERT
      expect(m.id, 'm1');
      verify(() => repo.enviarMensaje(idConversacion, '¿Sigue disponible?')).called(1);
    });

    test('Escenario 10: un mensaje inválido no llama al servidor', () async {
      await expectLater(
        EnviarMensaje(repo, red)(conversacion(), '<script>'),
        throwsA(const MensajeInvalidoFailure(MensajeValidator.mensajeCaracteres)),
      );
      await expectLater(
        EnviarMensaje(repo, red)(conversacion(), '   '),
        throwsA(const MensajeInvalidoFailure(MensajeValidator.mensajeVacio)),
      );
      verifyNever(() => red.estaConectado);
      verifyNever(() => repo.enviarMensaje(any(), any()));
    });

    test('Escenario 11: en una conversación cerrada no se envía', () async {
      for (final Conversacion c in [conversacion(estado: const Vendido()), conversacion(eliminada: true)]) {
        await expectLater(EnviarMensaje(repo, red)(c, 'Hola'), throwsA(isA<ConversacionCerradaFailure>()));
      }
      verifyNever(() => repo.enviarMensaje(any(), any()));
    });

    test('Escenario 14: sin conexión no se envía', () async {
      sinRed();
      await expectLater(EnviarMensaje(repo, red)(conversacion(), 'Hola'), throwsA(isA<SinConexionFailure>()));
      verifyNever(() => repo.enviarMensaje(any(), any()));
    });
  });

  group('MarcarConversacionLeida (Escenario 8)', () {
    test('la marca y responde true', () async {
      when(() => repo.marcarLeida(any())).thenAnswer((_) async {});
      expect(await MarcarConversacionLeida(repo, red)(idConversacion), isTrue);
      verify(() => repo.marcarLeida(idConversacion)).called(1);
    });

    test('sin conexión o con error responde false y no lanza nada', () async {
      when(() => repo.marcarLeida(any())).thenThrow(const ChatServidorFailure());
      expect(await MarcarConversacionLeida(repo, red)(idConversacion), isFalse);
      sinRed();
      expect(await MarcarConversacionLeida(repo, red)(idConversacion), isFalse);
      verify(() => repo.marcarLeida(any())).called(1);
    });
  });

  group('ObtenerTotalNoLeidos (Escenario 8)', () {
    test('devuelve el total', () async {
      when(() => repo.totalNoLeidos()).thenAnswer((_) async => 3);
      expect(await ObtenerTotalNoLeidos(repo, red)(), 3);
    });

    test('sin conexión o con error devuelve null', () async {
      when(() => repo.totalNoLeidos()).thenThrow(const ChatServidorFailure());
      expect(await ObtenerTotalNoLeidos(repo, red)(), isNull);
      sinRed();
      expect(await ObtenerTotalNoLeidos(repo, red)(), isNull);
    });
  });

  test('EscucharChat entrega los avisos del repositorio (patrón Observer)', () async {
    final StreamController<AvisoChat> sujeto = StreamController<AvisoChat>();
    when(() => repo.avisos()).thenAnswer((_) => sujeto.stream);

    final Future<List<AvisoChat>> recibidos = EscucharChat(repo)().toList();
    sujeto
      ..add(const ChatConectado())
      ..add(MensajeRecibido(mensaje('m1')));
    await sujeto.close();

    expect(await recibidos, [const ChatConectado(), MensajeRecibido(mensaje('m1'))]);
  });

  test('PaginaMensajes sabe si hay anteriores', () {
    expect(paginaDe(['m1'], hayAnteriores: true).hayAnteriores, isTrue);
    expect(const PaginaMensajes(mensajes: []).hayAnteriores, isFalse);
  });
}
