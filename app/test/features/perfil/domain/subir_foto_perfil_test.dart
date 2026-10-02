import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/perfil/domain/usecases/subir_foto_perfil.dart';

import '../fixtures.dart';

void main() {
  late MockPerfilRepository repositorio;
  late MockNetworkInfo networkInfo;
  late SubirFotoPerfil subirFoto;

  setUpAll(() => registerFallbackValue(fotoJpg()));

  setUp(() {
    repositorio = MockPerfilRepository();
    networkInfo = MockNetworkInfo();
    subirFoto = SubirFotoPerfil(repositorio, networkInfo);
    when(() => networkInfo.estaConectado).thenAnswer((_) async => true);
  });

  test('sube una foto PNG válida y devuelve su URL', () async {
    final foto = fotoPng();
    when(() => repositorio.subirFoto(foto)).thenAnswer((_) async => 'https://x/avatar.png');

    expect(await subirFoto(foto), 'https://x/avatar.png');
  });

  test('rechaza una foto de más de 5 MB (Escenario 3)', () async {
    await expectLater(subirFoto(fotoMayorA5MB()), throwsA(isA<FotoDemasiadoGrandeFailure>()));
    verifyNever(() => repositorio.subirFoto(any()));
  });

  test('rechaza formatos que no son JPG ni PNG', () async {
    await expectLater(subirFoto(fotoGif()), throwsA(isA<FotoFormatoInvalidoFailure>()));
    verifyNever(() => repositorio.subirFoto(any()));
  });

  test('sin conexión lanza SinConexionFailure', () async {
    when(() => networkInfo.estaConectado).thenAnswer((_) async => false);

    await expectLater(subirFoto(fotoJpg()), throwsA(isA<SinConexionFailure>()));
    verifyNever(() => repositorio.subirFoto(any()));
  });
}
