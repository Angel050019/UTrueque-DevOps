import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/auth/domain/entities/usuario.dart';
import 'package:utrueque/features/auth/domain/repositories/auth_repository.dart';
import 'package:utrueque/features/auth/domain/usecases/resolver_destino_inicial.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const String correo = 'ana.lopez@utsjr.edu.mx';
  late _MockAuthRepository repositorio;
  late ResolverDestinoInicial resolver;

  setUp(() {
    repositorio = _MockAuthRepository();
    resolver = ResolverDestinoInicial(repositorio);
  });

  group('DestinoInicial.desde (regla de HU-02 después del login)', () {
    test('sin usuario → login', () {
      expect(DestinoInicial.desde(null), DestinoInicial.login);
    });

    test('perfil incompleto → completar perfil', () {
      expect(
        DestinoInicial.desde(const Usuario(id: '1', correo: correo)),
        DestinoInicial.completarPerfil,
      );
    });

    test('perfil completo → feed', () {
      expect(
        DestinoInicial.desde(const Usuario(id: '1', correo: correo, perfilCompleto: true)),
        DestinoInicial.feed,
      );
    });
  });

  group('ResolverDestinoInicial (Splash)', () {
    test('usa la sesión guardada y su perfil', () async {
      when(() => repositorio.obtenerSesionActual()).thenAnswer(
        (_) async => const Usuario(id: '1', correo: correo),
      );

      expect(await resolver(), DestinoInicial.completarPerfil);
    });

    test('sin sesión → login', () async {
      when(() => repositorio.obtenerSesionActual()).thenAnswer((_) async => null);

      expect(await resolver(), DestinoInicial.login);
    });

    test('si falla la red pero hay sesión, conserva el comportamiento de HU-01 (Feed)',
        () async {
      when(() => repositorio.obtenerSesionActual()).thenThrow(const ServidorFailure());
      when(() => repositorio.usuarioActual).thenReturn(const Usuario(id: '1', correo: correo));

      expect(await resolver(), DestinoInicial.feed);
    });
  });
}
