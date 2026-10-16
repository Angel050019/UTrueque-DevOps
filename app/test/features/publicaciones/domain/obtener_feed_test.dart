import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_feed.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  group('ObtenerFeed (HU-04)', () {
    test('Escenario 1: pide la primera página de 20 sin cursor', () async {
      // ARRANGE
      final PaginaFeed pagina = paginaFeed(['a', 'b'], hayMas: true);
      when(() => repositorio.obtenerFeed(despuesDe: null, limite: 20)).thenAnswer((_) async => pagina);

      // ACT
      final PaginaFeed resultado = await ObtenerFeed(repositorio, red)();

      // ASSERT
      expect(resultado, pagina);
      expect(resultado.hayMas, isTrue);
      verify(() => repositorio.obtenerFeed(despuesDe: null, limite: ObtenerFeed.publicacionesPorPagina))
          .called(1);
    });

    test('Escenario 2: la siguiente página manda el cursor de la última publicación', () async {
      // ARRANGE
      final CursorFeed cursor = cursorDe('b');
      when(() => repositorio.obtenerFeed(despuesDe: cursor, limite: 20))
          .thenAnswer((_) async => paginaFeed(['c']));

      // ACT
      final PaginaFeed resultado = await ObtenerFeed(repositorio, red)(despuesDe: cursor);

      // ASSERT
      expect(resultado.publicaciones.single.id, 'c');
      expect(resultado.hayMas, isFalse);
      verify(() => repositorio.obtenerFeed(despuesDe: cursor, limite: 20)).called(1);
    });

    test('Escenario 5: sin conexión no llama al repositorio', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(ObtenerFeed(repositorio, red)(), throwsA(isA<SinConexionFailure>()));
      verifyZeroInteractions(repositorio);
    });

    test('Escenario 6: el error del servidor llega tal cual a la pantalla', () async {
      // ARRANGE
      when(() => repositorio.obtenerFeed(despuesDe: null, limite: 20))
          .thenThrow(const CargarPublicacionesFailure());

      // ACT + ASSERT
      await expectLater(
        ObtenerFeed(repositorio, red)(),
        throwsA(isA<CargarPublicacionesFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          'No pudimos cargar las publicaciones. Inténtalo de nuevo.',
        )),
      );
    });
  });
}
