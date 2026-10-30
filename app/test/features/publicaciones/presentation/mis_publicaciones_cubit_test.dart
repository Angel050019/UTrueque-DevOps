import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_mis_publicaciones.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/mis_publicaciones_cubit.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/mis_publicaciones_state.dart';

import '../fixtures.dart';

class _MockObtenerMisPublicaciones extends Mock implements ObtenerMisPublicaciones {}

void main() {
  late _MockObtenerMisPublicaciones obtener;

  setUpAll(() => registerFallbackValue(cursorDe('x')));

  setUp(() => obtener = _MockObtenerMisPublicaciones());

  MisPublicacionesCubit crearCubit() => MisPublicacionesCubit(obtener);

  void responde(PaginaFeed pagina, {bool finalizadas = false}) {
    when(() => obtener(finalizadas: finalizadas, despuesDe: any(named: 'despuesDe')))
        .thenAnswer((_) async => pagina);
  }

  void falla(Failure falla, {bool finalizadas = false}) {
    when(() => obtener(finalizadas: finalizadas, despuesDe: any(named: 'despuesDe'))).thenThrow(falla);
  }

  MisPublicacionesCargado cargado(
    List<String> ids, {
    bool hayMas = false,
    bool finalizadas = false,
    EstadoPublicacion estado = const Disponible(),
  }) {
    final PaginaFeed pagina = paginaMias(ids, hayMas: hayMas, estado: estado);
    return MisPublicacionesCargado(
      publicaciones: pagina.publicaciones,
      siguiente: pagina.siguiente,
      finalizadas: finalizadas,
    );
  }

  test('empieza cargando la pestaña Activas', () {
    expect(crearCubit().state, const MisPublicacionesCargando());
  });

  group('Escenario 1: mis publicaciones activas', () {
    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'carga la primera página de Activas',
      setUp: () => responde(paginaMias(['a', 'b'], hayMas: true)),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => [const MisPublicacionesCargando(), cargado(['a', 'b'], hayMas: true)],
      verify: (_) => verify(() => obtener(finalizadas: false)).called(1),
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'cargarMas agrega la siguiente página sin repetir',
      setUp: () => when(() => obtener(finalizadas: false, despuesDe: cursorDe('b')))
          .thenAnswer((_) async => paginaMias(['b', 'c'])),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      expect: () => [
        cargado(['a', 'b'], hayMas: true).copyWith(cargandoMas: true),
        cargado(['a', 'b', 'c']),
      ],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'cargarMas no hace nada si ya no hay más',
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.cargarMas(),
      expect: () => const <MisPublicacionesState>[],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'si falla cargarMas, la lista se conserva con el error al final',
      setUp: () => when(() => obtener(finalizadas: false, despuesDe: any(named: 'despuesDe')))
          .thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => cargado(['a'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      skip: 1,
      expect: () => [
        cargado(['a'], hayMas: true).copyWith(errorMas: () => const SinConexionFailure().mensaje),
      ],
    );
  });

  group('Escenario 2: historial de finalizadas', () {
    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'cambiar a Finalizadas pide las Vendidas',
      setUp: () => responde(paginaMias(['v'], estado: const Vendido()), finalizadas: true),
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.cambiarPestana(finalizadas: true),
      expect: () => [
        const MisPublicacionesCargando(finalizadas: true),
        cargado(['v'], finalizadas: true, estado: const Vendido()),
      ],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'sin Vendidas muestra el mensaje de Finalizadas vacía',
      setUp: () => responde(const PaginaFeed(publicaciones: []), finalizadas: true),
      build: crearCubit,
      act: (cubit) => cubit.cambiarPestana(finalizadas: true),
      expect: () => const [
        MisPublicacionesCargando(finalizadas: true),
        MisPublicacionesVacio(finalizadas: true),
      ],
      verify: (cubit) => expect(
        (cubit.state as MisPublicacionesVacio).mensaje,
        'Aún no tienes publicaciones finalizadas.',
      ),
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'tocar la pestaña que ya se ve no vuelve a cargar',
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.cambiarPestana(finalizadas: false),
      expect: () => const <MisPublicacionesState>[],
    );

    test('si cambia de pestaña mientras llegaba la respuesta vieja, esa se ignora', () async {
      // ARRANGE: Activas tarda; Finalizadas responde de inmediato.
      final Completer<PaginaFeed> lenta = Completer<PaginaFeed>();
      when(() => obtener(finalizadas: false)).thenAnswer((_) => lenta.future);
      responde(paginaMias(['v'], estado: const Vendido()), finalizadas: true);
      final MisPublicacionesCubit cubit = crearCubit();

      // ACT
      final Future<void> primera = cubit.cargar();
      await cubit.cambiarPestana(finalizadas: true);
      lenta.complete(paginaMias(['a']));
      await primera;

      // ASSERT
      expect(cubit.state, cargado(['v'], finalizadas: true, estado: const Vendido()));
      await cubit.close();
    });
  });

  group('Escenario 11: sin publicaciones', () {
    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'muestra que aún no tiene publicaciones activas',
      setUp: () => responde(const PaginaFeed(publicaciones: [])),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [MisPublicacionesCargando(), MisPublicacionesVacio()],
      verify: (cubit) => expect(
        (cubit.state as MisPublicacionesVacio).mensaje,
        'Aún no tienes publicaciones activas.',
      ),
    );
  });

  group('Escenarios 12 y 13: sin conexión y error del servidor', () {
    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'sin nada en pantalla, muestra el error de sin conexión',
      setUp: () => falla(const SinConexionFailure()),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [
        MisPublicacionesCargando(),
        MisPublicacionesError(SinConexionFailure()),
      ],
      verify: (cubit) => expect((cubit.state as MisPublicacionesError).sinConexion, isTrue),
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'un error inesperado se muestra con el mensaje genérico',
      setUp: () => when(() => obtener(finalizadas: false)).thenThrow(StateError('x')),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      skip: 1,
      expect: () => const [MisPublicacionesError(CargarMisPublicacionesFailure())],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'si "jalar para actualizar" falla, la lista se conserva y avisa',
      setUp: () => falla(const CargarMisPublicacionesFailure()),
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.actualizar(),
      expect: () => [
        cargado(['a']).copyWith(aviso: () => const CargarMisPublicacionesFailure().mensaje),
      ],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'avisoMostrado limpia el aviso',
      build: crearCubit,
      seed: () => cargado(['a']).copyWith(aviso: () => 'x'),
      act: (cubit) => cubit.avisoMostrado(),
      expect: () => [cargado(['a'])],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'después de un error, tocar la misma pestaña vuelve a intentar',
      setUp: () => responde(paginaMias(['a'])),
      build: crearCubit,
      seed: () => const MisPublicacionesError(SinConexionFailure()),
      act: (cubit) => cubit.cambiarPestana(finalizadas: false),
      expect: () => [const MisPublicacionesCargando(), cargado(['a'])],
    );
  });

  group('Escenario 14: la lista se actualiza cuando una publicación cambia', () {
    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'una Reservada sigue en Activas con su estado nuevo',
      build: crearCubit,
      seed: () => cargado(['a', 'b']),
      act: (cubit) => cubit.sincronizar('a', miPublicacion('a', estado: const Reservado())),
      expect: () => [
        MisPublicacionesCargado(
          publicaciones: [miPublicacion('a', estado: const Reservado()), miPublicacion('b')],
        ),
      ],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'una Vendida sale de Activas',
      build: crearCubit,
      seed: () => cargado(['a', 'b']),
      act: (cubit) => cubit.sincronizar('a', miPublicacion('a', estado: const Vendido())),
      expect: () => [cargado(['b'])],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'una borrada sale de la lista; si era la última, queda vacía',
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.sincronizar('a', null),
      expect: () => const [MisPublicacionesVacio()],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'una recién vendida que no estaba en Finalizadas hace que se recargue',
      setUp: () => responde(paginaMias(['a', 'v'], estado: const Vendido()), finalizadas: true),
      build: crearCubit,
      seed: () => cargado(['v'], finalizadas: true, estado: const Vendido()),
      act: (cubit) => cubit.sincronizar('a', miPublicacion('a', estado: const Vendido())),
      wait: const Duration(milliseconds: 10),
      expect: () => [cargado(['a', 'v'], finalizadas: true, estado: const Vendido())],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'con Finalizadas vacía, una recién vendida hace que se recargue',
      setUp: () => responde(paginaMias(['a'], estado: const Vendido()), finalizadas: true),
      build: crearCubit,
      seed: () => const MisPublicacionesVacio(finalizadas: true),
      act: (cubit) => cubit.sincronizar('a', miPublicacion('a', estado: const Vendido())),
      wait: const Duration(milliseconds: 10),
      expect: () => [cargado(['a'], finalizadas: true, estado: const Vendido())],
    );

    blocTest<MisPublicacionesCubit, MisPublicacionesState>(
      'un cambio de una publicación que no está en esta pestaña no hace nada',
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.sincronizar('z', miPublicacion('z', estado: const Vendido())),
      expect: () => const <MisPublicacionesState>[],
    );
  });
}
