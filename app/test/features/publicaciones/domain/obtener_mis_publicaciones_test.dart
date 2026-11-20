import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_mis_publicaciones.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;
  late ObtenerMisPublicaciones obtener;

  setUpAll(() => registerFallbackValue(cursorDe('x')));

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    obtener = ObtenerMisPublicaciones(repositorio, red);
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  void responde(PaginaFeed pagina) {
    when(() => repositorio.obtenerMisPublicaciones(
          finalizadas: any(named: 'finalizadas'),
          despuesDe: any(named: 'despuesDe'),
          limite: any(named: 'limite'),
        )).thenAnswer((_) async => pagina);
  }

  group('ObtenerMisPublicaciones (HU-06)', () {
    test('Escenario 1: pide la primera página de Activas, de 20 en 20', () async {
      // ARRANGE
      responde(paginaMias(['a', 'b'], hayMas: true));

      // ACT
      final PaginaFeed pagina = await obtener();

      // ASSERT
      expect(pagina.publicaciones.map((p) => p.id), ['a', 'b']);
      expect(pagina.hayMas, isTrue);
      verify(() => repositorio.obtenerMisPublicaciones(finalizadas: false, despuesDe: null, limite: 20))
          .called(1);
    });

    test('Escenario 1: la siguiente página manda el cursor de la última', () async {
      // ARRANGE
      responde(paginaMias(['c']));

      // ACT
      await obtener(despuesDe: cursorDe('b'));

      // ASSERT
      verify(() => repositorio.obtenerMisPublicaciones(
            finalizadas: false,
            despuesDe: cursorDe('b'),
            limite: ObtenerMisPublicaciones.publicacionesPorPagina,
          )).called(1);
    });

    test('Escenario 2: pide las Finalizadas (historial de Vendidas)', () async {
      // ARRANGE
      responde(paginaMias(['v']));

      // ACT
      await obtener(finalizadas: true);

      // ASSERT
      verify(() => repositorio.obtenerMisPublicaciones(finalizadas: true, despuesDe: null, limite: 20))
          .called(1);
    });

    test('Escenario 12: sin conexión no llama al servidor', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(obtener(), throwsA(isA<SinConexionFailure>()));
      verifyNever(() => repositorio.obtenerMisPublicaciones(
            finalizadas: any(named: 'finalizadas'),
            despuesDe: any(named: 'despuesDe'),
            limite: any(named: 'limite'),
          ));
    });

    test('Escenario 13: deja pasar el error del servidor', () async {
      // ARRANGE
      when(() => repositorio.obtenerMisPublicaciones(
            finalizadas: any(named: 'finalizadas'),
            despuesDe: any(named: 'despuesDe'),
            limite: any(named: 'limite'),
          )).thenThrow(const CargarMisPublicacionesFailure());

      // ACT + ASSERT
      await expectLater(obtener(), throwsA(isA<CargarMisPublicacionesFailure>()));
    });
  });
}
