import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/auth/domain/entities/usuario.dart';
import 'package:utrueque/features/auth/domain/repositories/auth_repository.dart';
import 'package:utrueque/features/auth/domain/usecases/registrar_usuario.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repositorio;
  late RegistrarUsuario registrarUsuario;

  const String correoValido = 'ana.lopez@alumno.utsjr.edu.mx';
  const String contrasenaValida = 'contrasena123';

  setUp(() {
    repositorio = _MockAuthRepository();
    registrarUsuario = RegistrarUsuario(repositorio);
  });

  test('llama al repositorio cuando el correo es institucional y las contraseñas coinciden',
      () async {
    const usuarioEsperado = Usuario(id: '1', correo: correoValido);
    when(() => repositorio.registrar(correo: correoValido, contrasena: contrasenaValida))
        .thenAnswer((_) async => usuarioEsperado);

    final resultado = await registrarUsuario(
      correo: correoValido,
      contrasena: contrasenaValida,
      confirmarContrasena: contrasenaValida,
    );

    expect(resultado, usuarioEsperado);
    verify(() => repositorio.registrar(correo: correoValido, contrasena: contrasenaValida))
        .called(1);
  });

  test('lanza CorreoNoInstitucionalFailure y NO llama al repositorio si el correo no es institucional',
      () async {
    expect(
      () => registrarUsuario(
        correo: 'ana.lopez@gmail.com',
        contrasena: contrasenaValida,
        confirmarContrasena: contrasenaValida,
      ),
      throwsA(isA<CorreoNoInstitucionalFailure>()),
    );
    verifyNever(() => repositorio.registrar(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ));
  });

  test('lanza ServidorFailure si las contraseñas no coinciden', () async {
    expect(
      () => registrarUsuario(
        correo: correoValido,
        contrasena: contrasenaValida,
        confirmarContrasena: 'otra-contrasena',
      ),
      throwsA(isA<ServidorFailure>()),
    );
  });

  test('lanza ServidorFailure si la contraseña es muy corta', () async {
    expect(
      () => registrarUsuario(
        correo: correoValido,
        contrasena: '123',
        confirmarContrasena: '123',
      ),
      throwsA(isA<ServidorFailure>()),
    );
  });
}
