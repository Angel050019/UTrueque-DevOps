import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_categorias.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  group('ObtenerCategorias', () {
    test('devuelve el catálogo cuando hay conexión', () async {
      // ARRANGE
      when(() => repositorio.obtenerCategorias()).thenAnswer((_) async => categorias);

      // ACT + ASSERT
      expect(await ObtenerCategorias(repositorio, red)(), categorias);
    });

    test('Escenario 6: sin conexión no llama al repositorio', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(ObtenerCategorias(repositorio, red)(), throwsA(isA<SinConexionFailure>()));
      verifyNever(() => repositorio.obtenerCategorias());
    });
  });
}
