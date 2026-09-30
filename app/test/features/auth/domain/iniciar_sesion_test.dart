import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/auth/domain/entities/usuario.dart';
import 'package:utrueque/features/auth/domain/repositories/auth_repository.dart';
import 'package:utrueque/features/auth/domain/usecases/iniciar_sesion.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockAuthRepository repositorio;
  late _MockNetworkInfo networkInfo;
  late IniciarSesion iniciarSesion;

  const String correo = 'ana.lopez@alumno.utsjr.edu.mx';
  const String contrasena = 'contrasena123';

  setUp(() {
    repositorio = _MockAuthRepository();
    networkInfo = _MockNetworkInfo();
    iniciarSesion = IniciarSesion(repositorio, networkInfo);
  });

  test('lanza SinConexionFailure y NO llama al repositorio si no hay internet (Escenario 3)',
      () async {
    when(() => networkInfo.estaConectado).thenAnswer((_) async => false);

    expect(
      () => iniciarSesion(correo: correo, contrasena: contrasena),
      throwsA(isA<SinConexionFailure>()),
    );
    verifyNever(() => repositorio.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ));
  });

  test('retorna el usuario si hay conexión y las credenciales son correctas (Escenario 4)',
      () async {
    const usuarioEsperado = Usuario(id: '1', correo: correo);
    when(() => networkInfo.estaConectado).thenAnswer((_) async => true);
    when(() => repositorio.iniciarSesion(correo: correo, contrasena: contrasena))
        .thenAnswer((_) async => usuarioEsperado);

    final resultado = await iniciarSesion(correo: correo, contrasena: contrasena);

    expect(resultado, usuarioEsperado);
  });

  test('propaga CredencialesInvalidasFailure del repositorio (Escenario 5)', () async {
    when(() => networkInfo.estaConectado).thenAnswer((_) async => true);
    when(() => repositorio.iniciarSesion(correo: correo, contrasena: contrasena))
        .thenThrow(const CredencialesInvalidasFailure());

    expect(
      () => iniciarSesion(correo: correo, contrasena: contrasena),
      throwsA(isA<CredencialesInvalidasFailure>()),
    );
  });
}
