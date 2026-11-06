import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
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
import 'package:utrueque/features/chat/domain/usecases/marcar_conversacion_leida.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_mensajes.dart';
import 'package:utrueque/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:utrueque/features/chat/presentation/cubit/chat_state.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';

import '../fixtures.dart';

class _MockObtener extends Mock implements ObtenerMensajes {}

class _MockEnviar extends Mock implements EnviarMensaje {}

class _MockMarcar extends Mock implements MarcarConversacionLeida {}

class _MockEscuchar extends Mock implements EscucharChat {}

void main() {
  late _MockObtener obtener;
  late _MockEnviar enviar;
  late _MockMarcar marcar;
  late _MockEscuchar escuchar;
  late StreamController<AvisoChat> tiempoReal;

  setUpAll(() {
    registerFallbackValue(cursorMensaje('x'));
    registerFallbackValue(conversacion());
  });

  setUp(() {
    obtener = _MockObtener();
    enviar = _MockEnviar();
    marcar = _MockMarcar();
    escuchar = _MockEscuchar();
    tiempoReal = StreamController<AvisoChat>.broadcast();
    when(() => escuchar()).thenAnswer((_) => tiempoReal.stream);
    when(() => marcar(any())).thenAnswer((_) async => true);
    when(() => obtener(any())).thenAnswer((_) async => paginaDe(['m2', 'm1']));
  });

  tearDown(() => tiempoReal.close());

  ChatCubit crearCubit({Conversacion? c}) => ChatCubit(
        conversacion: c ?? conversacion(),
        miId: idComprador,
        obtenerMensajes: obtener,
        enviarMensaje: enviar,
        marcarLeida: marcar,
        escuchar: escuchar,
      );

  /// Los mensajes m1 (minuto 99) y m2 (minuto 100), del más viejo al más nuevo.
  List<Mensaje> m1m2() => [mensaje('m1', minuto: 99), mensaje('m2', minuto: 100)];

  ChatListo listo({List<Mensaje>? mensajes, Conversacion? c}) => ChatListo(c ?? conversacion(), mensajes: mensajes ?? m1m2());

  Future<void> esperar() => Future<void>.delayed(Duration.zero);

  group('Escenarios 1 y 2: abrir', () {
    blocTest<ChatCubit, ChatState>(
      'carga los últimos mensajes del más viejo al más nuevo y marca la conversación como leída',
      build: crearCubit,
      act: (cubit) => cubit.abrir(),
      expect: () => [ChatCargando(conversacion()), listo()],
      verify: (cubit) {
        verify(() => obtener(idConversacion)).called(1);
        verify(() => marcar(idConversacion)).called(1);
        verify(() => escuchar()).called(1);
        expect(cubit.miId, idComprador);
      },
    );

    blocTest<ChatCubit, ChatState>(
      'una conversación nueva queda lista y vacía',
      setUp: () => when(() => obtener(any())).thenAnswer((_) async => const PaginaMensajes(mensajes: [])),
      build: crearCubit,
      act: (cubit) => cubit.abrir(),
      skip: 1,
      expect: () => [listo(mensajes: const [])],
    );

    blocTest<ChatCubit, ChatState>(
      'Escenarios 14 y 15: si falla, muestra el error; "Reintentar" vuelve a cargar',
      setUp: () => when(() => obtener(any())).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      act: (cubit) => cubit.abrir(),
      skip: 1,
      expect: () => [ChatError(conversacion(), const SinConexionFailure())],
      verify: (cubit) {
        expect((cubit.state as ChatError).sinConexion, isTrue);
        verifyNever(() => marcar(any()));
      },
    );

    blocTest<ChatCubit, ChatState>(
      'un error inesperado se muestra con el mensaje genérico',
      setUp: () => when(() => obtener(any())).thenThrow(StateError('x')),
      build: crearCubit,
      act: (cubit) => cubit.abrir(),
      skip: 1,
      expect: () => [ChatError(conversacion(), const ChatServidorFailure())],
    );

    test('un mensaje que llega mientras se carga no se pierde', () async {
      // ARRANGE: la carga tarda.
      final Completer<PaginaMensajes> lenta = Completer<PaginaMensajes>();
      when(() => obtener(any())).thenAnswer((_) => lenta.future);
      final ChatCubit cubit = crearCubit();

      // ACT
      final Future<void> abriendo = cubit.abrir();
      await esperar();
      tiempoReal.add(MensajeRecibido(mensaje('m3', minuto: 101)));
      await esperar();
      lenta.complete(paginaDe(['m2', 'm1']));
      await abriendo;

      // ASSERT
      expect((cubit.state as ChatListo).mensajes.map((m) => m.id), ['m1', 'm2', 'm3']);
      await cubit.close();
    });
  });

  group('Escenario 3: tiempo real (patrón Observer)', () {
    blocTest<ChatCubit, ChatState>(
      'un mensaje del otro aparece abajo sin recargar y se marca como leído',
      build: crearCubit,
      seed: listo,
      act: (cubit) async {
        await cubit.abrir();
        tiempoReal.add(MensajeRecibido(mensaje('m3', minuto: 101)));
        await esperar();
      },
      skip: 2,
      expect: () => [listo(mensajes: [...m1m2(), mensaje('m3', minuto: 101)])],
      verify: (_) => verify(() => marcar(idConversacion)).called(2),
    );

    blocTest<ChatCubit, ChatState>(
      'un mensaje de otra conversación se ignora',
      build: crearCubit,
      act: (cubit) async {
        await cubit.abrir();
        tiempoReal.add(MensajeRecibido(mensaje('x1', conv: 'otra')));
        await esperar();
      },
      skip: 2,
      expect: () => const <ChatState>[],
    );

    blocTest<ChatCubit, ChatState>(
      'mi propio mensaje no se duplica (llega como respuesta y por el tiempo real)',
      setUp: () => when(() => enviar(any(), any())).thenAnswer((_) async => mensaje('m3', autor: idComprador, minuto: 101)),
      build: crearCubit,
      act: (cubit) async {
        await cubit.abrir();
        await cubit.enviar('Hola');
        tiempoReal.add(MensajeRecibido(mensaje('m3', autor: idComprador, minuto: 101)));
        await esperar();
      },
      verify: (cubit) {
        expect((cubit.state as ChatListo).mensajes.map((m) => m.id), ['m1', 'm2', 'm3']);
        // Solo se marcó al abrir: el mensaje era mío.
        verify(() => marcar(idConversacion)).called(1);
      },
    );

    blocTest<ChatCubit, ChatState>(
      'al reconectarse pide los últimos mensajes y agrega los que faltaban',
      build: crearCubit,
      act: (cubit) async {
        await cubit.abrir();
        when(() => obtener(any())).thenAnswer((_) async => paginaDe(['m4', 'm2']));
        tiempoReal.add(const ChatConectado());
        await esperar();
        await esperar();
      },
      verify: (cubit) => expect((cubit.state as ChatListo).mensajes.map((m) => m.id), ['m1', 'm2', 'm4']),
    );

    blocTest<ChatCubit, ChatState>(
      'si al reconectarse no hay nada nuevo (o no hay red), no cambia',
      build: crearCubit,
      act: (cubit) async {
        await cubit.abrir();
        tiempoReal.add(const ChatConectado());
        await esperar();
        when(() => obtener(any())).thenThrow(const SinConexionFailure());
        tiempoReal.add(const ChatConectado());
        await esperar();
      },
      skip: 2,
      expect: () => const <ChatState>[],
    );

    blocTest<ChatCubit, ChatState>(
      'si estaba en error y se recupera la conexión, vuelve a abrir',
      build: crearCubit,
      act: (cubit) async {
        when(() => obtener(any())).thenThrow(const SinConexionFailure());
        await cubit.abrir();
        when(() => obtener(any())).thenAnswer((_) async => paginaDe(['m2', 'm1']));
        tiempoReal.add(const ChatConectado());
        await esperar();
        await esperar();
      },
      verify: (cubit) => expect(cubit.state, listo()),
    );

    test('al cerrarse cancela su suscripción', () async {
      final ChatCubit cubit = crearCubit();
      await cubit.abrir();
      expect(tiempoReal.hasListener, isTrue);
      await cubit.close();
      expect(tiempoReal.hasListener, isFalse);
    });
  });

  group('Escenario 9: historial', () {
    blocTest<ChatCubit, ChatState>(
      'cargarAnteriores agrega los mensajes viejos arriba sin repetir',
      setUp: () => when(() => obtener(any(), antesDe: cursorMensaje('m1')))
          .thenAnswer((_) async => PaginaMensajes(mensajes: [mensaje('m1', minuto: 99), mensaje('m0', minuto: 98)])),
      build: crearCubit,
      seed: () => ChatListo(conversacion(), mensajes: m1m2(), siguiente: cursorMensaje('m1')),
      act: (cubit) => cubit.cargarAnteriores(),
      expect: () => [
        ChatListo(conversacion(), mensajes: m1m2(), siguiente: cursorMensaje('m1'), cargandoAnteriores: true),
        ChatListo(conversacion(), mensajes: [mensaje('m0', minuto: 98), ...m1m2()]),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'si ya no hay anteriores, no hace nada',
      build: crearCubit,
      seed: listo,
      act: (cubit) => cubit.cargarAnteriores(),
      expect: () => const <ChatState>[],
    );

    blocTest<ChatCubit, ChatState>(
      'si falla, conserva los mensajes y muestra el error arriba',
      setUp: () => when(() => obtener(any(), antesDe: any(named: 'antesDe'))).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => ChatListo(conversacion(), mensajes: m1m2(), siguiente: cursorMensaje('m1')),
      act: (cubit) => cubit.cargarAnteriores(),
      skip: 1,
      expect: () => [
        ChatListo(conversacion(), mensajes: m1m2(), siguiente: cursorMensaje('m1'), errorAnteriores: const SinConexionFailure().mensaje),
      ],
    );
  });

  group('Enviar (Escenarios 3, 10, 11, 13 y 14)', () {
    blocTest<ChatCubit, ChatState>(
      'envía, agrega el mensaje abajo y responde true',
      setUp: () => when(() => enviar(any(), any())).thenAnswer((_) async => mensaje('m3', autor: idComprador, minuto: 101)),
      build: crearCubit,
      seed: listo,
      act: (cubit) async => expect(await cubit.enviar('Hola'), isTrue),
      expect: () => [
        ChatListo(conversacion(), mensajes: m1m2(), enviando: true),
        listo(mensajes: [...m1m2(), mensaje('m3', autor: idComprador, minuto: 101)]),
      ],
      verify: (_) => verify(() => enviar(conversacion(), 'Hola')).called(1),
    );

    for (final Failure falla in const [
      SinConexionFailure(),
      DemasiadosMensajesFailure(),
      MensajeInvalidoFailure('El mensaje solo puede tener…'),
      ChatServidorFailure(),
    ]) {
      blocTest<ChatCubit, ChatState>(
        '"${falla.mensaje}": avisa, responde false y la pantalla conserva el texto',
        setUp: () => when(() => enviar(any(), any())).thenThrow(falla),
        build: crearCubit,
        seed: listo,
        act: (cubit) async => expect(await cubit.enviar('Hola'), isFalse),
        skip: 1,
        expect: () => [ChatListo(conversacion(), mensajes: m1m2(), aviso: falla.mensaje)],
      );
    }

    blocTest<ChatCubit, ChatState>(
      'un error inesperado avisa con el mensaje genérico',
      setUp: () => when(() => enviar(any(), any())).thenThrow(StateError('x')),
      build: crearCubit,
      seed: listo,
      act: (cubit) => cubit.enviar('Hola'),
      skip: 1,
      expect: () => [ChatListo(conversacion(), mensajes: m1m2(), aviso: const ChatServidorFailure().mensaje)],
    );

    blocTest<ChatCubit, ChatState>(
      'Escenario 11: si el servidor dice que se cerró, se quita el campo de texto',
      setUp: () => when(() => enviar(any(), any())).thenThrow(const ConversacionCerradaFailure()),
      build: crearCubit,
      seed: listo,
      act: (cubit) => cubit.enviar('Hola'),
      skip: 1,
      expect: () => [
        ChatListo(conversacion(), mensajes: m1m2(), cerradaPorServidor: true, aviso: const ConversacionCerradaFailure().mensaje),
      ],
      verify: (cubit) => expect((cubit.state as ChatListo).cerrada, isTrue),
    );

    test('Escenario 11: una conversación Vendida o borrada ya llega cerrada y no envía', () async {
      for (final Conversacion c in [conversacion(estado: const Vendido()), conversacion(eliminada: true)]) {
        final ChatCubit cubit = crearCubit(c: c);
        await cubit.abrir();
        expect((cubit.state as ChatListo).cerrada, isTrue);
        expect(await cubit.enviar('Hola'), isFalse);
        await cubit.close();
      }
      verifyNever(() => enviar(any(), any()));
    });

    blocTest<ChatCubit, ChatState>(
      'mientras se envía no se puede enviar otro',
      build: crearCubit,
      seed: () => ChatListo(conversacion(), mensajes: m1m2(), enviando: true),
      act: (cubit) async => expect(await cubit.enviar('Otro'), isFalse),
      expect: () => const <ChatState>[],
    );

    blocTest<ChatCubit, ChatState>(
      'avisoMostrado limpia el aviso',
      build: crearCubit,
      seed: () => ChatListo(conversacion(), mensajes: m1m2(), aviso: 'x'),
      act: (cubit) => cubit.avisoMostrado(),
      expect: () => [listo()],
    );
  });
}
