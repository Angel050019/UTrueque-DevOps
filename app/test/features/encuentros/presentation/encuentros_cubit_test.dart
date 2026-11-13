import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/chat/domain/entities/aviso_chat.dart';
import 'package:utrueque/features/chat/domain/entities/conversacion.dart';
import 'package:utrueque/features/chat/domain/entities/mensaje.dart';
import 'package:utrueque/features/chat/domain/errors/chat_failures.dart';
import 'package:utrueque/features/chat/domain/usecases/escuchar_chat.dart';
import 'package:utrueque/features/encuentros/domain/entities/encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/errors/encuentro_failures.dart';
import 'package:utrueque/features/encuentros/domain/factories/creadores_solicitud.dart';
import 'package:utrueque/features/encuentros/domain/usecases/enviar_solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/usecases/obtener_encuentros.dart';
import 'package:utrueque/features/encuentros/presentation/cubit/encuentros_cubit.dart';
import 'package:utrueque/features/encuentros/presentation/cubit/encuentros_state.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';

import '../fixtures.dart';

class _MockObtener extends Mock implements ObtenerEncuentros {}

class _MockEnviar extends Mock implements EnviarSolicitudEncuentro {}

class _MockEscuchar extends Mock implements EscucharChat {}

class _FakeCreador extends Fake implements CreadorSolicitudEncuentro {}

/// Una tarjeta de encuentro que llega por el tiempo real.
Mensaje tarjeta(String id, {String conv = idConversacion, TipoMensaje tipo = TipoMensaje.propuesta}) => Mensaje(
      id: id,
      conversacionId: conv,
      autorId: idVendedor,
      texto: 'Propuso vernos en Biblioteca',
      creadoEn: ahora,
      tipo: tipo,
      encuentroId: 'enc-1',
    );

void main() {
  late _MockObtener obtener;
  late _MockEnviar enviar;
  late _MockEscuchar escuchar;
  late StreamController<AvisoChat> tiempoReal;

  setUpAll(() => registerFallbackValue(_FakeCreador()));

  setUp(() {
    obtener = _MockObtener();
    enviar = _MockEnviar();
    escuchar = _MockEscuchar();
    tiempoReal = StreamController<AvisoChat>.broadcast();
    when(() => escuchar()).thenAnswer((_) => tiempoReal.stream);
    when(() => obtener(any())).thenAnswer((_) async => [encuentro()]);
    // El caso de uso real le pide la solicitud al creador (Factory Method).
    when(() => enviar(any())).thenAnswer(
      (inv) async => (inv.positionalArguments.first as CreadorSolicitudEncuentro).crear(),
    );
  });

  tearDown(() => tiempoReal.close());

  EncuentrosCubit crearCubit({Conversacion? c, String miId = idComprador}) => EncuentrosCubit(
        conversacion: c ?? conversacion(),
        miId: miId,
        obtenerEncuentros: obtener,
        enviarSolicitud: enviar,
        escuchar: escuchar,
        reloj: reloj,
      );

  Future<void> esperar() => Future<void>.delayed(Duration.zero);

  group('Cargar', () {
    blocTest<EncuentrosCubit, EncuentrosState>(
      'carga los encuentros de la conversación y se suscribe al tiempo real',
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => [EncuentrosState(encuentros: [encuentro()], cargado: true)],
      verify: (cubit) {
        verify(() => obtener(idConversacion)).called(1);
        verify(() => escuchar()).called(1);
        expect(cubit.miId, idComprador);
        expect(cubit.conversacion, conversacion());
      },
    );

    test('Escenario 7: con una propuesta pendiente no se puede proponer; sin encuentros, sí', () async {
      final EncuentrosCubit conActivo = crearCubit();
      expect(conActivo.puedeProponer, isFalse); // todavía no carga
      await conActivo.cargar();
      expect(conActivo.puedeProponer, isFalse);
      expect(conActivo.state.activoAl(ahora), encuentro());
      await conActivo.close();

      when(() => obtener(any())).thenAnswer((_) async => [encuentro(estado: EstadoEncuentro.rechazado)]);
      final EncuentrosCubit sinActivo = crearCubit();
      await sinActivo.cargar();
      expect(sinActivo.puedeProponer, isTrue);
      await sinActivo.close();
    });

    test('Escenario 10: con la publicación Vendida no se puede proponer ni responder', () async {
      when(() => obtener(any())).thenAnswer((_) async => []);
      final EncuentrosCubit cubit = crearCubit(c: conversacion(estado: const Vendido()));
      await cubit.cargar();
      expect(cubit.cerrada, isTrue);
      expect(cubit.puedeProponer, isFalse);
      expect(await cubit.responder(encuentro(), acepta: true), isFalse);
      verifyNever(() => enviar(any()));
      await cubit.close();
    });

    test('si falla la carga se conservan los encuentros y no se puede proponer', () async {
      when(() => obtener(any())).thenThrow(const SinConexionFailure());
      final EncuentrosCubit cubit = crearCubit();
      await cubit.cargar();
      expect(cubit.state, const EncuentrosState());
      expect(cubit.puedeProponer, isFalse);
      await cubit.close();
    });
  });

  group('Escenarios 1 y 2: tiempo real (patrón Observer)', () {
    test('una tarjeta de esta conversación vuelve a pedir los encuentros', () async {
      final EncuentrosCubit cubit = crearCubit();
      await cubit.cargar();
      when(() => obtener(any())).thenAnswer((_) async => [encuentro(estado: EstadoEncuentro.aceptado)]);

      tiempoReal.add(MensajeRecibido(tarjeta('m1', tipo: TipoMensaje.aceptado)));
      await esperar();
      await esperar();

      expect(cubit.state.confirmadoAl(ahora), encuentro(estado: EstadoEncuentro.aceptado));
      verify(() => obtener(idConversacion)).called(2);
      await cubit.close();
    });

    test('un mensaje normal o de otra conversación no pide nada; una reconexión sí', () async {
      final EncuentrosCubit cubit = crearCubit();
      await cubit.cargar();

      tiempoReal
        ..add(MensajeRecibido(mensaje('m1')))
        ..add(MensajeRecibido(tarjeta('m2', conv: 'otra')));
      await esperar();
      verify(() => obtener(idConversacion)).called(1);

      tiempoReal.add(const ChatConectado());
      await esperar();
      verify(() => obtener(idConversacion)).called(1);
      await cubit.close();
    });

    test('al cerrarse cancela su suscripción', () async {
      final EncuentrosCubit cubit = crearCubit();
      await cubit.cargar();
      expect(tiempoReal.hasListener, isTrue);
      await cubit.close();
      expect(tiempoReal.hasListener, isFalse);
    });
  });

  group('Responder y cancelar (Factory Method)', () {
    test('Escenario 2: aceptar usa el CreadorRespuesta, avisa y vuelve a cargar', () async {
      final EncuentrosCubit cubit = crearCubit();
      await cubit.cargar();
      when(() => obtener(any())).thenAnswer((_) async => [encuentro(estado: EstadoEncuentro.aceptado)]);

      final bool enviado = await cubit.responder(encuentro(), acepta: true);

      expect(enviado, isTrue);
      final CreadorSolicitudEncuentro creador =
          verify(() => enviar(captureAny())).captured.single as CreadorSolicitudEncuentro;
      expect(creador, isA<CreadorRespuesta>());
      expect(creador.crear(), const RespuestaEncuentro(encuentroId: 'enc-1', acepta: true));
      expect(cubit.state.aviso, 'Punto de encuentro confirmado.');
      expect(cubit.state.avisoEsError, isFalse);
      expect(cubit.state.enviando, isFalse);
      expect(cubit.state.confirmadoAl(ahora), isNotNull);

      cubit.avisoMostrado();
      expect(cubit.state.aviso, isNull);
      await cubit.close();
    });

    test('Escenario 3: rechazar', () async {
      final EncuentrosCubit cubit = crearCubit();
      await cubit.cargar();
      expect(await cubit.responder(encuentro(), acepta: false), isTrue);
      expect(cubit.state.aviso, 'Rechazaste la propuesta.');
      await cubit.close();
    });

    test('Escenario 4: cancelar usa el CreadorCancelacion', () async {
      final EncuentrosCubit cubit = crearCubit(miId: idVendedor);
      await cubit.cargar();
      expect(await cubit.cancelar(encuentro()), isTrue);
      final Object? creador = verify(() => enviar(captureAny())).captured.single;
      expect(creador, isA<CreadorCancelacion>());
      expect(cubit.state.aviso, 'Encuentro cancelado.');
      await cubit.close();
    });

    test('Escenario 8: el creador rechaza aceptar la propia propuesta y se muestra el motivo', () async {
      final EncuentrosCubit cubit = crearCubit(miId: idVendedor);
      await cubit.cargar();
      expect(await cubit.responder(encuentro(), acepta: true), isFalse);
      expect(cubit.state.aviso, const EncuentroPropioFailure().mensaje);
      expect(cubit.state.avisoEsError, isTrue);
      expect(cubit.state.enviando, isFalse);
      await cubit.close();
    });

    test('Escenarios 12 y 14: un rechazo del servidor se muestra y se vuelve a cargar', () async {
      when(() => enviar(any())).thenThrow(const DemasiadosMensajesFailure());
      final EncuentrosCubit cubit = crearCubit();
      await cubit.cargar();
      expect(await cubit.responder(encuentro(), acepta: true), isFalse);
      await esperar();
      expect(cubit.state.aviso, 'Estás enviando muchos mensajes. Espera un momento.');
      verify(() => obtener(idConversacion)).called(2);

      when(() => enviar(any())).thenThrow(StateError('inesperado'));
      expect(await cubit.cancelar(encuentro(estado: EstadoEncuentro.aceptado)), isFalse);
      expect(cubit.state.aviso, 'No pudimos completar la acción. Inténtalo de nuevo.');
      await cubit.close();
    });

    test('Escenario 10: si el servidor dice que se cerró, ya no hay botones', () async {
      when(() => enviar(any())).thenThrow(const ConversacionCerradaFailure());
      final EncuentrosCubit cubit = crearCubit();
      await cubit.cargar();
      expect(await cubit.responder(encuentro(), acepta: true), isFalse);
      expect(cubit.state.cerradaPorServidor, isTrue);
      expect(cubit.cerrada, isTrue);
      expect(cubit.puedeProponer, isFalse);
      await cubit.close();
    });
  });

  group('EncuentrosState', () {
    test('porId, activoAl y confirmadoAl', () {
      final EncuentrosState s = EncuentrosState(encuentros: [
        encuentro(id: 'enc-2', estado: EstadoEncuentro.aceptado),
        encuentro(id: 'enc-1', estado: EstadoEncuentro.rechazado),
      ]);
      expect(s.porId('enc-1')?.estado, EstadoEncuentro.rechazado);
      expect(s.porId('nada'), isNull);
      expect(s.porId(null), isNull);
      expect(s.activoAl(ahora)?.id, 'enc-2');
      expect(s.confirmadoAl(ahora)?.id, 'enc-2');
      // Ya pasó la hora: ya no hay aviso fijo.
      expect(s.confirmadoAl(jueves13.add(const Duration(hours: 1))), isNull);
      expect(EncuentrosState(encuentros: [encuentro()]).confirmadoAl(ahora), isNull);
    });
  });
}
