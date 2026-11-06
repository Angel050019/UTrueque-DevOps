import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/filtros_feed.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/buscar_publicaciones.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  const FiltrosFeed sinFiltros = FiltrosFeed();
  const FiltrosFeed combinados =
      FiltrosFeed(texto: 'calculo', categoriaId: 1, divisionId: 11, carreraId: 102);

  group('BuscarPublicaciones (HU-04 y HU-05)', () {
    test('HU-04, Escenario 1: sin filtros pide la primera página de 20 sin cursor', () async {
      // ARRANGE
      final PaginaFeed pagina = paginaFeed(['a', 'b'], hayMas: true);
      when(() => repositorio.buscarPublicaciones(filtros: sinFiltros, despuesDe: null, limite: 20))
          .thenAnswer((_) async => pagina);

      // ACT
      final PaginaFeed resultado = await BuscarPublicaciones(repositorio, red)();

      // ASSERT
      expect(resultado, pagina);
      expect(resultado.hayMas, isTrue);
      verify(() => repositorio.buscarPublicaciones(
            filtros: sinFiltros,
            despuesDe: null,
            limite: BuscarPublicaciones.publicacionesPorPagina,
          )).called(1);
    });

    test('HU-05, Escenario 2: manda el texto y los filtros al repositorio', () async {
      // ARRANGE
      when(() => repositorio.buscarPublicaciones(filtros: combinados, despuesDe: null, limite: 20))
          .thenAnswer((_) async => paginaFeed(['a']));

      // ACT
      final PaginaFeed resultado = await BuscarPublicaciones(repositorio, red)(filtros: combinados);

      // ASSERT
      expect(resultado.publicaciones.single.id, 'a');
      verify(() => repositorio.buscarPublicaciones(filtros: combinados, despuesDe: null, limite: 20))
          .called(1);
    });

    test('HU-05, Escenario 5: la siguiente página manda el cursor y los MISMOS filtros', () async {
      // ARRANGE
      final CursorFeed cursor = cursorDe('b');
      when(() => repositorio.buscarPublicaciones(filtros: combinados, despuesDe: cursor, limite: 20))
          .thenAnswer((_) async => paginaFeed(['c']));

      // ACT
      final PaginaFeed resultado =
          await BuscarPublicaciones(repositorio, red)(filtros: combinados, despuesDe: cursor);

      // ASSERT
      expect(resultado.publicaciones.single.id, 'c');
      expect(resultado.hayMas, isFalse);
      verify(() => repositorio.buscarPublicaciones(filtros: combinados, despuesDe: cursor, limite: 20))
          .called(1);
    });

    test('HU-05, Escenario 6: sin coincidencias regresa una página vacía', () async {
      // ARRANGE
      when(() => repositorio.buscarPublicaciones(filtros: combinados, despuesDe: null, limite: 20))
          .thenAnswer((_) async => const PaginaFeed(publicaciones: []));

      // ACT
      final PaginaFeed resultado = await BuscarPublicaciones(repositorio, red)(filtros: combinados);

      // ASSERT
      expect(resultado.publicaciones, isEmpty);
      expect(resultado.hayMas, isFalse);
    });

    test('HU-05, Escenario 8: sin conexión no llama al repositorio', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(
        BuscarPublicaciones(repositorio, red)(filtros: combinados),
        throwsA(isA<SinConexionFailure>()),
      );
      verifyZeroInteractions(repositorio);
    });

    test('HU-05, Escenario 9: el error del servidor llega tal cual a la pantalla', () async {
      // ARRANGE
      when(() => repositorio.buscarPublicaciones(filtros: sinFiltros, despuesDe: null, limite: 20))
          .thenThrow(const CargarPublicacionesFailure());

      // ACT + ASSERT
      await expectLater(
        BuscarPublicaciones(repositorio, red)(),
        throwsA(isA<CargarPublicacionesFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          'No pudimos cargar las publicaciones. Inténtalo de nuevo.',
        )),
      );
    });
  });
}
