import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/perfil/domain/usecases/obtener_catalogo_academico.dart';

import '../fixtures.dart';

void main() {
  late MockPerfilRepository repositorio;
  late MockNetworkInfo networkInfo;
  late ObtenerCatalogoAcademico obtenerCatalogo;

  setUp(() {
    repositorio = MockPerfilRepository();
    networkInfo = MockNetworkInfo();
    obtenerCatalogo = ObtenerCatalogoAcademico(repositorio, networkInfo);
  });

  test('devuelve las divisiones con sus carreras', () async {
    when(() => networkInfo.estaConectado).thenAnswer((_) async => true);
    when(() => repositorio.obtenerCatalogoAcademico()).thenAnswer((_) async => catalogo);

    final resultado = await obtenerCatalogo();

    expect(resultado, catalogo);
    expect(resultado.first.carreras, contains(carreraSoftware));
  });

  test('sin conexión lanza SinConexionFailure', () async {
    when(() => networkInfo.estaConectado).thenAnswer((_) async => false);

    await expectLater(obtenerCatalogo(), throwsA(isA<SinConexionFailure>()));
    verifyNever(() => repositorio.obtenerCatalogoAcademico());
  });
}
