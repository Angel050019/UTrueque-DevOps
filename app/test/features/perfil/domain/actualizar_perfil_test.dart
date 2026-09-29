import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/perfil/domain/usecases/actualizar_perfil.dart';

import '../fixtures.dart';

void main() {
  late MockPerfilRepository repositorio;
  late MockNetworkInfo networkInfo;
  late ActualizarPerfil actualizarPerfil;

  setUpAll(() => registerFallbackValue(fotoJpg()));

  setUp(() {
    repositorio = MockPerfilRepository();
    networkInfo = MockNetworkInfo();
    actualizarPerfil = ActualizarPerfil(repositorio, networkInfo);
    when(() => networkInfo.estaConectado).thenAnswer((_) async => true);
  });

  void verificarQueNoGuardo() {
    verifyNever(() => repositorio.subirFoto(any()));
    verifyNever(() => repositorio.actualizarPerfil(
          nombreMostrar: any(named: 'nombreMostrar'),
          divisionId: any(named: 'divisionId'),
          carreraId: any(named: 'carreraId'),
          fotoUrl: any(named: 'fotoUrl'),
        ));
  }

  test('Escenario 1: completa el perfil con nombre, división, carrera y foto', () async {
    final foto = fotoJpg();
    when(() => repositorio.subirFoto(foto)).thenAnswer((_) async => 'https://x/u1/avatar.jpg');
    when(() => repositorio.actualizarPerfil(
          nombreMostrar: 'Ana López',
          divisionId: 1,
          carreraId: 1,
          fotoUrl: 'https://x/u1/avatar.jpg',
        )).thenAnswer((_) async => perfilCompleto);

    final resultado = await actualizarPerfil(
      nombre: '  Ana López  ',
      division: divisionTI,
      carrera: carreraSoftware,
      fotoNueva: foto,
    );

    expect(resultado, perfilCompleto);
    verify(() => repositorio.subirFoto(foto)).called(1);
  });

  test('Escenario 2: rechaza una carrera que no pertenece a la división', () async {
    await expectLater(
      actualizarPerfil(nombre: 'Ana López', division: divisionTI, carrera: carreraMecatronica),
      throwsA(isA<CarreraNoPerteneceFailure>()),
    );
    verificarQueNoGuardo();
  });

  test('Escenario 3: rechaza una foto mayor a 5 MB sin subir ni guardar nada', () async {
    await expectLater(
      actualizarPerfil(
        nombre: 'Ana López',
        division: divisionTI,
        carrera: carreraSoftware,
        fotoNueva: fotoMayorA5MB(),
      ),
      throwsA(isA<FotoDemasiadoGrandeFailure>()),
    );
    verificarQueNoGuardo();
  });

  test('Escenario 4: edita el perfil sin foto nueva y conserva la foto actual', () async {
    when(() => repositorio.actualizarPerfil(
          nombreMostrar: 'Ana L.',
          divisionId: 1,
          carreraId: 2,
          fotoUrl: null,
        )).thenAnswer((_) async => perfilCompleto);

    await actualizarPerfil(nombre: 'Ana L.', division: divisionTI, carrera: carreraRedes);

    verifyNever(() => repositorio.subirFoto(any()));
    verify(() => repositorio.actualizarPerfil(
          nombreMostrar: 'Ana L.',
          divisionId: 1,
          carreraId: 2,
          fotoUrl: null,
        )).called(1);
  });

  test('Escenario 5: sin conexión lanza SinConexionFailure y no llama al repositorio',
      () async {
    when(() => networkInfo.estaConectado).thenAnswer((_) async => false);

    await expectLater(
      actualizarPerfil(nombre: 'Ana López', division: divisionTI, carrera: carreraSoftware),
      throwsA(isA<SinConexionFailure>()),
    );
    verificarQueNoGuardo();
  });

  test('rechaza nombre inválido antes de revisar la conexión', () async {
    await expectLater(
      actualizarPerfil(nombre: 'Al', division: divisionTI, carrera: carreraSoftware),
      throwsA(isA<NombreInvalidoFailure>()),
    );
    verifyNever(() => networkInfo.estaConectado);
    verificarQueNoGuardo();
  });

  test('exige división y carrera', () async {
    await expectLater(
      actualizarPerfil(nombre: 'Ana López', division: null, carrera: null),
      throwsA(isA<DivisionRequeridaFailure>()),
    );
    await expectLater(
      actualizarPerfil(nombre: 'Ana López', division: divisionTI, carrera: null),
      throwsA(isA<CarreraRequeridaFailure>()),
    );
    verificarQueNoGuardo();
  });
}
