import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_detalle_publicacion.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/detalle_publicacion_cubit.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/detalle_publicacion_state.dart';

import '../fixtures.dart';

class _MockObtenerDetalle extends Mock implements ObtenerDetallePublicacion {}

void main() {
  late _MockObtenerDetalle obtenerDetalle;

  setUp(() => obtenerDetalle = _MockObtenerDetalle());

  /// El alumno con sesión es [idAlumno]; la publicación es de otro alumno.
  DetallePublicacionCubit crearCubit() =>
      DetallePublicacionCubit(obtenerDetalle, idPublicacion: 'pub-1', idUsuarioActual: idAlumno);

  void responde(Publicacion publicacion) =>
      when(() => obtenerDetalle('pub-1')).thenAnswer((_) async => publicacion);

  test('empieza cargando', () {
    expect(crearCubit().state, const DetalleCargando());
  });

  group('Escenario 7: ver el detalle', () {
    blocTest<DetallePublicacionCubit, DetalleState>(
      'muestra la publicación de otro alumno y permite contactar',
      setUp: () => responde(publicacionDelFeed('pub-1')),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => [
        const DetalleCargando(),
        DetalleCargado(publicacion: publicacionDelFeed('pub-1'), esMia: false),
      ],
      verify: (cubit) => expect((cubit.state as DetalleCargado).puedeContactar, isTrue),
    );
  });

  group('Escenario 8: mi propia publicación', () {
    blocTest<DetallePublicacionCubit, DetalleState>(
      'marca esMia y no permite contactarme a mí mismo',
      setUp: () => responde(publicacionDelFeed('pub-1', usuarioId: idAlumno)),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      skip: 1,
      expect: () => [
        DetalleCargado(publicacion: publicacionDelFeed('pub-1', usuarioId: idAlumno), esMia: true),
      ],
      verify: (cubit) => expect((cubit.state as DetalleCargado).puedeContactar, isFalse),
    );

    blocTest<DetallePublicacionCubit, DetalleState>(
      'sin sesión ninguna publicación es "mía"',
      setUp: () => responde(publicacionDelFeed('pub-1', usuarioId: idAlumno)),
      build: () => DetallePublicacionCubit(obtenerDetalle, idPublicacion: 'pub-1'),
      act: (cubit) => cubit.cargar(),
      skip: 1,
      verify: (cubit) => expect((cubit.state as DetalleCargado).esMia, isFalse),
    );
  });

  group('Escenario 9: reservada o vendida mientras se ve', () {
    for (final EstadoPublicacion estado in const [Reservado(), Vendido()]) {
      blocTest<DetallePublicacionCubit, DetalleState>(
        '${estado.etiqueta}: muestra su aviso y deshabilita "Contactar al vendedor"',
        setUp: () => responde(publicacionDelFeed('pub-1', estado: estado)),
        build: crearCubit,
        act: (cubit) => cubit.cargar(),
        skip: 1,
        verify: (cubit) {
          final DetalleCargado cargado = cubit.state as DetalleCargado;
          expect(cargado.puedeContactar, isFalse);
          expect(cargado.publicacion.estado.aviso, isNotNull);
        },
      );
    }

    blocTest<DetallePublicacionCubit, DetalleState>(
      'al jalar para actualizar se ve el estado nuevo sin pasar por "cargando"',
      setUp: () => responde(publicacionDelFeed('pub-1', estado: const Vendido())),
      build: crearCubit,
      seed: () => DetalleCargado(publicacion: publicacionDelFeed('pub-1'), esMia: false),
      act: (cubit) => cubit.cargar(),
      expect: () => [
        DetalleCargado(publicacion: publicacionDelFeed('pub-1', estado: const Vendido()), esMia: false),
      ],
    );
  });

  group('Escenario 10: eliminada mientras se ve', () {
    blocTest<DetallePublicacionCubit, DetalleState>(
      'muestra "Esta publicación ya no está disponible."',
      setUp: () => when(() => obtenerDetalle('pub-1')).thenThrow(const PublicacionNoEncontradaFailure()),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [DetalleCargando(), DetalleNoEncontrado()],
      verify: (cubit) => expect(
        (cubit.state as DetalleNoEncontrado).mensaje,
        'Esta publicación ya no está disponible.',
      ),
    );
  });

  group('Escenarios 5 y 6: sin conexión o error del servidor', () {
    blocTest<DetallePublicacionCubit, DetalleState>(
      'sin conexión muestra el error con "Reintentar"',
      setUp: () => when(() => obtenerDetalle('pub-1')).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [DetalleCargando(), DetalleError(SinConexionFailure())],
      verify: (cubit) => expect(
        (cubit.state as DetalleError).mensaje,
        'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.',
      ),
    );

    blocTest<DetallePublicacionCubit, DetalleState>(
      'un error inesperado se muestra con el mensaje genérico',
      setUp: () => when(() => obtenerDetalle('pub-1')).thenThrow(StateError('x')),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [DetalleCargando(), DetalleError(CargarPublicacionesFailure())],
    );

    blocTest<DetallePublicacionCubit, DetalleState>(
      'si ya se veía la publicación, la conserva y avisa una sola vez',
      setUp: () => when(() => obtenerDetalle('pub-1')).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => DetalleCargado(publicacion: publicacionDelFeed('pub-1'), esMia: false),
      act: (cubit) async {
        await cubit.cargar();
        cubit.avisoMostrado();
        cubit.avisoMostrado();
      },
      expect: () => [
        DetalleCargado(
          publicacion: publicacionDelFeed('pub-1'),
          esMia: false,
          aviso: const SinConexionFailure().mensaje,
        ),
        DetalleCargado(publicacion: publicacionDelFeed('pub-1'), esMia: false),
      ],
    );
  });
}
