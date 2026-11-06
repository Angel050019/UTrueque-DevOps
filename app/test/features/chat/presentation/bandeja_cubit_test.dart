import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/chat/domain/entities/aviso_chat.dart';
import 'package:utrueque/features/chat/domain/entities/conversacion.dart';
import 'package:utrueque/features/chat/domain/errors/chat_failures.dart';
import 'package:utrueque/features/chat/domain/usecases/escuchar_chat.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_conversaciones.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_total_no_leidos.dart';
import 'package:utrueque/features/chat/presentation/cubit/bandeja_cubit.dart';
import 'package:utrueque/features/chat/presentation/cubit/bandeja_state.dart';
import 'package:utrueque/features/chat/presentation/cubit/no_leidos_cubit.dart';

import '../fixtures.dart';

class _MockObtener extends Mock implements ObtenerConversaciones {}

class _MockTotal extends Mock implements ObtenerTotalNoLeidos {}

class _MockEscuchar extends Mock implements EscucharChat {}

void main() {
  late _MockObtener obtener;
  late _MockEscuchar escuchar;
  late StreamController<AvisoChat> tiempoReal;

  final Conversacion c1 = conversacion(id: 'c1', ultimoTexto: 'Hola');
  final Conversacion c2 = conversacion(id: 'c2', ultimoTexto: 'Buenas', noLeidos: 1);

  setUp(() {
    obtener = _MockObtener();
    escuchar = _MockEscuchar();
    tiempoReal = StreamController<AvisoChat>.broadcast();
    when(() => escuchar()).thenAnswer((_) => tiempoReal.stream);
    when(() => obtener()).thenAnswer((_) async => [c1, c2]);
  });

  tearDown(() => tiempoReal.close());

  Future<void> esperar() => Future<void>.delayed(Duration.zero);

  BandejaCubit crearCubit() => BandejaCubit(obtenerConversaciones: obtener, escuchar: escuchar, miId: idComprador);

  group('BandejaCubit (Escenario 7)', () {
    blocTest<BandejaCubit, BandejaState>(
      'carga las conversaciones',
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => [const BandejaCargando(), BandejaCargada([c1, c2])],
      verify: (cubit) => expect(cubit.miId, idComprador),
    );

    blocTest<BandejaCubit, BandejaState>(
      'sin conversaciones muestra "Aún no tienes mensajes."',
      setUp: () => when(() => obtener()).thenAnswer((_) async => []),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [BandejaCargando(), BandejaVacia()],
      verify: (_) => expect(BandejaVacia.mensaje, 'Aún no tienes mensajes.'),
    );

    blocTest<BandejaCubit, BandejaState>(
      'Escenarios 14 y 15: sin nada en pantalla muestra el error',
      setUp: () => when(() => obtener()).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      skip: 1,
      expect: () => const [BandejaError(SinConexionFailure())],
      verify: (cubit) => expect((cubit.state as BandejaError).sinConexion, isTrue),
    );

    blocTest<BandejaCubit, BandejaState>(
      'un error inesperado usa el mensaje genérico',
      setUp: () => when(() => obtener()).thenThrow(StateError('x')),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      skip: 1,
      expect: () => const [BandejaError(ChatServidorFailure())],
    );

    blocTest<BandejaCubit, BandejaState>(
      'si "jalar para actualizar" falla, la lista se conserva y avisa; avisoMostrado lo limpia',
      setUp: () => when(() => obtener()).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => BandejaCargada([c1]),
      act: (cubit) async {
        await cubit.actualizar();
        cubit.avisoMostrado();
      },
      expect: () => [
        BandejaCargada([c1], aviso: const SinConexionFailure().mensaje),
        BandejaCargada([c1]),
      ],
    );

    blocTest<BandejaCubit, BandejaState>(
      'Escenario 8: al abrir una conversación su globo se apaga',
      build: crearCubit,
      seed: () => BandejaCargada([c1, c2]),
      act: (cubit) => cubit.marcarLeida('c2'),
      expect: () => [BandejaCargada([c1, c2.leida()])],
    );
  });

  group('BandejaCubit en tiempo real (Escenario 3, patrón Observer)', () {
    blocTest<BandejaCubit, BandejaState>(
      'un mensaje sube su conversación al primer lugar con el texto y un no leído más',
      build: crearCubit,
      act: (cubit) async {
        await cubit.cargar();
        tiempoReal.add(MensajeRecibido(mensaje('m9', conv: 'c2', texto: '¿Sigue?')));
        await esperar();
      },
      skip: 2,
      verify: (cubit) {
        final List<Conversacion> lista = (cubit.state as BandejaCargada).conversaciones;
        expect(lista.map((c) => c.id), ['c2', 'c1']);
        expect(lista.first.ultimoTexto, '¿Sigue?');
        expect(lista.first.noLeidos, 2);
      },
    );

    blocTest<BandejaCubit, BandejaState>(
      'un mensaje de una conversación nueva recarga la bandeja',
      build: crearCubit,
      act: (cubit) async {
        await cubit.cargar();
        when(() => obtener()).thenAnswer((_) async => [conversacion(id: 'c3'), c1, c2]);
        tiempoReal.add(MensajeRecibido(mensaje('m9', conv: 'c3')));
        await esperar();
      },
      verify: (cubit) => expect((cubit.state as BandejaCargada).conversaciones.first.id, 'c3'),
    );

    blocTest<BandejaCubit, BandejaState>(
      'la primera conexión no recarga; una reconexión sí',
      build: crearCubit,
      act: (cubit) async {
        await cubit.cargar();
        tiempoReal.add(const ChatConectado());
        await esperar();
        tiempoReal.add(const ChatConectado());
        await esperar();
      },
      verify: (_) => verify(() => obtener()).called(2),
    );

    test('al cerrarse cancela su suscripción', () async {
      final BandejaCubit cubit = crearCubit();
      await cubit.cargar();
      expect(tiempoReal.hasListener, isTrue);
      await cubit.close();
      expect(tiempoReal.hasListener, isFalse);
    });
  });

  group('NoLeidosCubit (Escenario 8)', () {
    late _MockTotal total;

    setUp(() {
      total = _MockTotal();
      when(() => total()).thenAnswer((_) async => 2);
    });

    NoLeidosCubit crearNoLeidos() => NoLeidosCubit(obtenerTotal: total, escuchar: escuchar, miId: idComprador);

    blocTest<NoLeidosCubit, int>(
      'al iniciar pide el total',
      build: crearNoLeidos,
      act: (cubit) => cubit.iniciar(),
      expect: () => [2],
    );

    blocTest<NoLeidosCubit, int>(
      'sin conexión conserva el número que tenía',
      setUp: () => when(() => total()).thenAnswer((_) async => null),
      build: crearNoLeidos,
      seed: () => 5,
      act: (cubit) => cubit.actualizar(),
      expect: () => const <int>[],
    );

    blocTest<NoLeidosCubit, int>(
      'un mensaje del otro o una reconexión vuelven a pedir el total; uno mío no',
      build: crearNoLeidos,
      act: (cubit) async {
        await cubit.iniciar();
        when(() => total()).thenAnswer((_) async => 3);
        tiempoReal.add(MensajeRecibido(mensaje('m1')));
        await esperar();
        tiempoReal.add(MensajeRecibido(mensaje('m2', autor: idComprador)));
        await esperar();
        when(() => total()).thenAnswer((_) async => 0);
        tiempoReal.add(const ChatConectado());
        await esperar();
      },
      expect: () => [2, 3, 0],
      verify: (_) => verify(() => total()).called(3),
    );

    test('al cerrarse cancela su suscripción', () async {
      final NoLeidosCubit cubit = crearNoLeidos();
      await cubit.iniciar();
      expect(tiempoReal.hasListener, isTrue);
      await cubit.close();
      expect(tiempoReal.hasListener, isFalse);
    });
  });
}
