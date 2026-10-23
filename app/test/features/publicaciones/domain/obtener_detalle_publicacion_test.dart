import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_detalle_publicacion.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  group('ObtenerDetallePublicacion (HU-04)', () {
    test('Escenario 7: trae la publicación con sus fotos y el perfil del dueño', () async {
      // ARRANGE
      final Publicacion publicacion = publicacionDelFeed('pub-1');
      when(() => repositorio.obtenerDetalle('pub-1')).thenAnswer((_) async => publicacion);

      // ACT
      final Publicacion resultado = await ObtenerDetallePublicacion(repositorio, red)('pub-1');

      // ASSERT
      expect(resultado, publicacion);
      expect(resultado.fotosUrls, hasLength(2));
      expect(resultado.duenoCarrera, isNotNull);
    });

    test('Escenario 10: si ya se borró lanza PublicacionNoEncontradaFailure', () async {
      // ARRANGE
      when(() => repositorio.obtenerDetalle('borrada'))
          .thenThrow(const PublicacionNoEncontradaFailure());

      // ACT + ASSERT
      await expectLater(
        ObtenerDetallePublicacion(repositorio, red)('borrada'),
        throwsA(isA<PublicacionNoEncontradaFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          'Esta publicación ya no está disponible.',
        )),
      );
    });

    test('Escenario 5: sin conexión no llama al repositorio', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(
        ObtenerDetallePublicacion(repositorio, red)('pub-1'),
        throwsA(isA<SinConexionFailure>()),
      );
      verifyZeroInteractions(repositorio);
    });
  });
}
