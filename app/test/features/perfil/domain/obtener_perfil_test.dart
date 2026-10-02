import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/perfil/domain/usecases/obtener_perfil.dart';

import '../fixtures.dart';

void main() {
  late MockPerfilRepository repositorio;
  late MockNetworkInfo networkInfo;
  late ObtenerPerfil obtenerPerfil;

  setUp(() {
    repositorio = MockPerfilRepository();
    networkInfo = MockNetworkInfo();
    obtenerPerfil = ObtenerPerfil(repositorio, networkInfo);
    when(() => networkInfo.estaConectado).thenAnswer((_) async => true);
  });

  test('sin id devuelve el perfil propio', () async {
    when(() => repositorio.obtenerPerfilPropio()).thenAnswer((_) async => perfilCompleto);

    expect(await obtenerPerfil(), perfilCompleto);
    verifyNever(() => repositorio.obtenerPerfilPorId(any()));
  });

  test('con id devuelve el perfil de otro estudiante', () async {
    when(() => repositorio.obtenerPerfilPorId('u2'))
        .thenAnswer((_) async => perfilCompleto);

    expect(await obtenerPerfil(id: 'u2'), perfilCompleto);
  });

  test('sin conexión lanza SinConexionFailure (Escenario 5)', () async {
    when(() => networkInfo.estaConectado).thenAnswer((_) async => false);

    await expectLater(obtenerPerfil(), throwsA(isA<SinConexionFailure>()));
    verifyNever(() => repositorio.obtenerPerfilPropio());
  });
}
