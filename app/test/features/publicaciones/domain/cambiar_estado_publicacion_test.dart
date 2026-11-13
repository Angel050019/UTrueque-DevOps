import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/cambiar_estado_publicacion.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;
  late CambiarEstadoPublicacion cambiarEstado;

  setUpAll(() => registerFallbackValue(const Disponible()));

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    cambiarEstado = CambiarEstadoPublicacion(repositorio, red);
    when(() => red.estaConectado).thenAnswer((_) async => true);
    when(() => repositorio.cambiarEstado(any(), any())).thenAnswer(
      (invocacion) async => miPublicacion(
        invocacion.positionalArguments[0] as String,
        estado: invocacion.positionalArguments[1] as EstadoPublicacion,
      ),
    );
  });

  group('CambiarEstadoPublicacion (HU-06, patrón State)', () {
    test('Escenario 3: Reservar manda Reservado y devuelve la publicación actualizada', () async {
      // ACT
      final Publicacion resultado = await cambiarEstado(miPublicacion('p1'), AccionEstado.reservar);

      // ASSERT
      expect(resultado.estado, const Reservado());
      verify(() => repositorio.cambiarEstado('p1', const Reservado())).called(1);
    });

    test('Escenario 4: Volver a Disponible desde Reservado', () async {
      // ACT
      await cambiarEstado(miPublicacion('p1', estado: const Reservado()), AccionEstado.liberar);

      // ASSERT
      verify(() => repositorio.cambiarEstado('p1', const Disponible())).called(1);
    });

    test('Escenario 5: Vender desde Disponible o desde Reservado', () async {
      // ACT
      await cambiarEstado(miPublicacion('p1'), AccionEstado.marcarVendido);
      await cambiarEstado(miPublicacion('p2', estado: const Reservado()), AccionEstado.marcarVendido);

      // ASSERT
      verify(() => repositorio.cambiarEstado('p1', const Vendido())).called(1);
      verify(() => repositorio.cambiarEstado('p2', const Vendido())).called(1);
    });

    test('Escenario 9: una transición no permitida no llama al servidor', () async {
      // ACT + ASSERT
      await expectLater(
        cambiarEstado(miPublicacion('p1', estado: const Vendido()), AccionEstado.liberar),
        throwsA(isA<TransicionNoPermitidaFailure>()),
      );
      await expectLater(
        cambiarEstado(miPublicacion('p2'), AccionEstado.liberar),
        throwsA(isA<TransicionNoPermitidaFailure>()),
      );
      verifyNever(() => red.estaConectado);
      verifyNever(() => repositorio.cambiarEstado(any(), any()));
    });

    test('Escenario 9: si el servidor la rechaza, deja pasar el fallo', () async {
      // ARRANGE
      when(() => repositorio.cambiarEstado(any(), any())).thenThrow(const AccionNoPermitidaFailure());

      // ACT + ASSERT
      await expectLater(
        cambiarEstado(miPublicacion('p1'), AccionEstado.reservar),
        throwsA(isA<AccionNoPermitidaFailure>()),
      );
    });

    test('Escenario 12: sin conexión no llama al servidor', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(
        cambiarEstado(miPublicacion('p1'), AccionEstado.reservar),
        throwsA(isA<SinConexionFailure>()),
      );
      verifyNever(() => repositorio.cambiarEstado(any(), any()));
    });
  });
}
