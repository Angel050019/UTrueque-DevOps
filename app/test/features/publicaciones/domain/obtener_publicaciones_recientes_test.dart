import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_publicaciones_recientes.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;
  late ObtenerPublicacionesRecientes obtenerRecientes;

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    obtenerRecientes = ObtenerPublicacionesRecientes(repositorio, red);
  });

  test('pide al repositorio las 20 más recientes cuando hay conexión', () async {
    // ARRANGE
    final List<Publicacion> lista = [publicacionGuardada()];
    when(() => red.estaConectado).thenAnswer((_) async => true);
    when(() => repositorio.obtenerPublicacionesRecientes(limite: any(named: 'limite')))
        .thenAnswer((_) async => lista);

    // ACT
    final List<Publicacion> resultado = await obtenerRecientes();

    // ASSERT
    expect(resultado, lista);
    verify(() => repositorio.obtenerPublicacionesRecientes(limite: 20)).called(1);
  });

  test('sin conexión no llama al repositorio', () async {
    // ARRANGE
    when(() => red.estaConectado).thenAnswer((_) async => false);

    // ACT + ASSERT
    await expectLater(obtenerRecientes(), throwsA(isA<SinConexionFailure>()));
    verifyNever(() => repositorio.obtenerPublicacionesRecientes(limite: any(named: 'limite')));
  });
}
