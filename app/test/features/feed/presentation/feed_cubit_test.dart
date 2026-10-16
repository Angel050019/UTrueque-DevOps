import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:utrueque/features/feed/presentation/cubit/feed_state.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_feed.dart';

import '../../publicaciones/fixtures.dart';

class _MockObtenerFeed extends Mock implements ObtenerFeed {}

void main() {
  late _MockObtenerFeed obtenerFeed;

  setUp(() => obtenerFeed = _MockObtenerFeed());

  FeedCubit crearCubit() => FeedCubit(obtenerFeed);

  List<Publicacion> publicaciones(List<String> ids) => ids.map(publicacionDelFeed).toList();

  /// Feed ya cargado con [ids]; si [hayMas], con cursor a la última.
  FeedCargado cargado(List<String> ids, {bool hayMas = false}) => FeedCargado(
        publicaciones: publicaciones(ids),
        siguiente: hayMas ? cursorDe(ids.last) : null,
      );

  void primeraPagina(PaginaFeed pagina) =>
      when(() => obtenerFeed()).thenAnswer((_) async => pagina);

  test('empieza cargando', () {
    expect(crearCubit().state, const FeedCargando());
  });

  group('Escenario 1: ver el Feed', () {
    blocTest<FeedCubit, FeedState>(
      'cargar muestra la primera página',
      setUp: () => primeraPagina(paginaFeed(['a', 'b'], hayMas: true)),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => [const FeedCargando(), cargado(['a', 'b'], hayMas: true)],
    );
  });

  group('Escenario 2: cargar más al hacer scroll', () {
    blocTest<FeedCubit, FeedState>(
      'agrega la siguiente página al final usando el cursor de la última',
      setUp: () => when(() => obtenerFeed(despuesDe: cursorDe('b')))
          .thenAnswer((_) async => paginaFeed(['c'])),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      expect: () => [
        cargado(['a', 'b'], hayMas: true).copyWith(cargandoMas: true),
        cargado(['a', 'b', 'c']),
      ],
      verify: (cubit) {
        verify(() => obtenerFeed(despuesDe: cursorDe('b'))).called(1);
        // Ya no hay más: se muestra "Ya viste todas las publicaciones."
        expect((cubit.state as FeedCargado).hayMas, isFalse);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'no repite publicaciones que ya están en la lista',
      setUp: () => when(() => obtenerFeed(despuesDe: cursorDe('b')))
          .thenAnswer((_) async => paginaFeed(['b', 'c'])),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      skip: 1,
      expect: () => [cargado(['a', 'b', 'c'])],
    );

    blocTest<FeedCubit, FeedState>(
      'no hace nada si ya no hay más',
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.cargarMas(),
      expect: () => const <FeedState>[],
      verify: (_) => verifyZeroInteractions(obtenerFeed),
    );

    blocTest<FeedCubit, FeedState>(
      'no pide dos veces la misma página si ya se está cargando',
      build: crearCubit,
      seed: () => cargado(['a'], hayMas: true).copyWith(cargandoMas: true),
      act: (cubit) => cubit.cargarMas(),
      expect: () => const <FeedState>[],
      verify: (_) => verifyZeroInteractions(obtenerFeed),
    );

    blocTest<FeedCubit, FeedState>(
      'Escenario 5: si falla al cargar más, conserva la lista y muestra el error al final',
      setUp: () => when(() => obtenerFeed(despuesDe: cursorDe('b')))
          .thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      skip: 1,
      expect: () => [
        cargado(['a', 'b'], hayMas: true)
            .copyWith(errorMas: () => const SinConexionFailure().mensaje),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'un error inesperado al cargar más se muestra con el mensaje genérico',
      setUp: () => when(() => obtenerFeed(despuesDe: cursorDe('b'))).thenThrow(StateError('x')),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      skip: 1,
      expect: () => [
        cargado(['a', 'b'], hayMas: true)
            .copyWith(errorMas: () => const CargarPublicacionesFailure().mensaje),
      ],
    );
  });

  group('Escenario 3: jalar para actualizar', () {
    blocTest<FeedCubit, FeedState>(
      'vuelve a cargar desde el inicio sin mostrar el indicador de carga',
      setUp: () => primeraPagina(paginaFeed(['nueva', 'a'])),
      build: crearCubit,
      seed: () => cargado(['a', 'b', 'c']),
      act: (cubit) => cubit.actualizar(),
      expect: () => [cargado(['nueva', 'a'])],
    );

    test('si se actualiza mientras se cargaba más, la página vieja se ignora', () async {
      // ARRANGE: primera carga con [a, b]; la siguiente página tarda y,
      // mientras, el alumno jala para actualizar y llega [nueva].
      int llamadas = 0;
      when(() => obtenerFeed()).thenAnswer(
        (_) async => ++llamadas == 1 ? paginaFeed(['a', 'b'], hayMas: true) : paginaFeed(['nueva']),
      );
      final Completer<PaginaFeed> paginaLenta = Completer<PaginaFeed>();
      when(() => obtenerFeed(despuesDe: cursorDe('b'))).thenAnswer((_) => paginaLenta.future);
      final FeedCubit cubit = crearCubit();
      await cubit.cargar();

      // ACT
      final Future<void> cargandoMas = cubit.cargarMas();
      await cubit.actualizar();
      paginaLenta.complete(paginaFeed(['c']));
      await cargandoMas;

      // ASSERT
      expect(cubit.state, cargado(['nueva']));
      await cubit.close();
    });
  });

  group('Escenario 4: Feed vacío', () {
    blocTest<FeedCubit, FeedState>(
      'sin publicaciones muestra el estado vacío',
      setUp: () => primeraPagina(const PaginaFeed(publicaciones: [])),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [FeedCargando(), FeedVacio()],
    );
  });

  group('Escenario 5: sin conexión', () {
    blocTest<FeedCubit, FeedState>(
      'en la primera carga muestra el error con "Reintentar"',
      setUp: () => when(() => obtenerFeed()).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [FeedCargando(), FeedError(SinConexionFailure())],
      verify: (cubit) {
        final FeedError error = cubit.state as FeedError;
        expect(error.sinConexion, isTrue);
        expect(error.mensaje, 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.');
      },
    );

    blocTest<FeedCubit, FeedState>(
      'al actualizar conserva la lista y avisa una sola vez',
      setUp: () => when(() => obtenerFeed()).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) async {
        await cubit.actualizar();
        cubit.avisoMostrado();
        cubit.avisoMostrado(); // la segunda vez ya no hay nada que limpiar
      },
      expect: () => [
        cargado(['a']).copyWith(aviso: () => const SinConexionFailure().mensaje),
        cargado(['a']),
      ],
    );
  });

  group('Escenario 6: error del servidor', () {
    blocTest<FeedCubit, FeedState>(
      'muestra el mensaje genérico, también ante un error inesperado',
      setUp: () => when(() => obtenerFeed()).thenThrow(StateError('fallo en 10.0.0.8')),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [FeedCargando(), FeedError(CargarPublicacionesFailure())],
      verify: (cubit) {
        final FeedError error = cubit.state as FeedError;
        expect(error.sinConexion, isFalse);
        expect(error.mensaje, isNot(contains('10.0.0.8')));
      },
    );
  });

  group('Escenarios 9 y 10: sincronizar con el detalle', () {
    blocTest<FeedCubit, FeedState>(
      'una publicación borrada desaparece de la lista',
      build: crearCubit,
      seed: () => cargado(['a', 'b']),
      act: (cubit) => cubit.sincronizar('a', null),
      expect: () => [cargado(['b'])],
    );

    blocTest<FeedCubit, FeedState>(
      'una publicación vendida desaparece y, si era la última, queda el Feed vacío',
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.sincronizar('a', publicacionDelFeed('a', estado: const Vendido())),
      expect: () => const [FeedVacio()],
    );

    blocTest<FeedCubit, FeedState>(
      'una publicación reservada se actualiza en su lugar',
      build: crearCubit,
      seed: () => cargado(['a', 'b']),
      act: (cubit) => cubit.sincronizar('b', publicacionDelFeed('b', estado: const Reservado())),
      expect: () => [
        FeedCargado(publicaciones: [
          publicacionDelFeed('a'),
          publicacionDelFeed('b', estado: const Reservado()),
        ]),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'si el Feed no está cargado no hace nada',
      build: crearCubit,
      act: (cubit) {
        cubit.sincronizar('a', null);
        cubit.avisoMostrado();
      },
      expect: () => const <FeedState>[],
    );
  });
}
