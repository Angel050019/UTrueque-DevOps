import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/foto_articulo.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/editar_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/validators/publicacion_validator.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;
  late EditarPublicacion editar;

  const String rutaNueva = '$idAlumno/9_0.jpg';
  final FotoArticulo foto1Guardada =
      FotoArticulo.guardada(ruta: rutaFoto1, url: 'https://fotos/1.jpg');
  final FotoArticulo foto2Guardada =
      FotoArticulo.guardada(ruta: rutaFoto2, url: 'https://fotos/2.jpg');

  setUpAll(() {
    registerFallbackValue(fotoJpg());
    registerFallbackValue(Modalidad.intercambio);
  });

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    editar = EditarPublicacion(repositorio, red);
    when(() => red.estaConectado).thenAnswer((_) async => true);
    when(() => repositorio.subirFoto(any())).thenAnswer((_) async => rutaNueva);
    when(() => repositorio.eliminarFotos(any())).thenAnswer((_) async {});
  });

  void stubEditar(Future<Publicacion> Function(Invocation) respuesta) {
    when(() => repositorio.editarPublicacion(
          id: any(named: 'id'),
          titulo: any(named: 'titulo'),
          descripcion: any(named: 'descripcion'),
          categoriaId: any(named: 'categoriaId'),
          modalidad: any(named: 'modalidad'),
          precio: any(named: 'precio'),
          fotos: any(named: 'fotos'),
        )).thenAnswer(respuesta);
  }

  void verificarQueNoSeGuardo() {
    verifyNever(() => repositorio.subirFoto(any()));
    verifyNever(() => repositorio.editarPublicacion(
          id: any(named: 'id'),
          titulo: any(named: 'titulo'),
          descripcion: any(named: 'descripcion'),
          categoriaId: any(named: 'categoriaId'),
          modalidad: any(named: 'modalidad'),
          precio: any(named: 'precio'),
          fotos: any(named: 'fotos'),
        ));
  }

  group('EditarPublicacion (HU-06)', () {
    test(
        'Escenario 6: conserva la foto que se queda, sube solo la nueva, guarda y borra la '
        'que se quitó', () async {
      // ARRANGE
      stubEditar((_) async => miPublicacion('p1', titulo: 'Calculadora Casio'));

      // ACT: se quita la foto 2 y se agrega una nueva.
      final Publicacion resultado = await editar(
        miPublicacion('p1'),
        borrador(
          titulo: '  Calculadora Casio  ',
          modalidad: Modalidad.venta,
          precioTexto: r'$300',
          fotos: [foto1Guardada, fotoJpg()],
        ),
      );

      // ASSERT
      expect(resultado.titulo, 'Calculadora Casio');
      verify(() => repositorio.subirFoto(any())).called(1);
      verify(() => repositorio.editarPublicacion(
            id: 'p1',
            titulo: 'Calculadora Casio',
            descripcion: descripcionValida,
            categoriaId: categoriaCalculadoras.id,
            modalidad: Modalidad.venta,
            precio: 300,
            fotos: const [rutaFoto1, rutaNueva],
          )).called(1);
      verify(() => repositorio.eliminarFotos(const [rutaFoto2])).called(1);
    });

    test('Escenario 6: sin cambios en las fotos no sube ni borra ninguna', () async {
      // ARRANGE
      stubEditar((_) async => miPublicacion('p1'));

      // ACT: pasa a Gratis, así que el precio ya no se guarda.
      await editar(
        miPublicacion('p1'),
        borrador(modalidad: Modalidad.gratis, precioTexto: '350', fotos: [foto1Guardada, foto2Guardada]),
      );

      // ASSERT
      verifyNever(() => repositorio.subirFoto(any()));
      verifyNever(() => repositorio.eliminarFotos(any()));
      verify(() => repositorio.editarPublicacion(
            id: 'p1',
            titulo: tituloValido,
            descripcion: descripcionValida,
            categoriaId: categoriaCalculadoras.id,
            modalidad: Modalidad.gratis,
            precio: null,
            fotos: const [rutaFoto1, rutaFoto2],
          )).called(1);
    });

    test('Escenario 7: con datos inválidos no envía nada y marca cada campo', () async {
      // ACT + ASSERT: Venta sin precio y sin fotos.
      await expectLater(
        editar(miPublicacion('p1'), borrador(modalidad: Modalidad.venta, fotos: const [])),
        throwsA(isA<PublicacionInvalidaFailure>().having(
          (f) => f.errores,
          'errores',
          {
            CampoPublicacion.precio: PublicacionValidator.mensajePrecioVacio,
            CampoPublicacion.fotos: PublicacionValidator.mensajeSinFotos,
          },
        )),
      );
      verificarQueNoSeGuardo();
    });

    test('Escenario 9: una Reservada o una Vendida no se editan', () async {
      for (final EstadoPublicacion estado in const [Reservado(), Vendido()]) {
        await expectLater(
          editar(miPublicacion('p1', estado: estado), borrador(fotos: [foto1Guardada])),
          throwsA(isA<AccionNoPermitidaFailure>()),
        );
      }
      verificarQueNoSeGuardo();
    });

    test('Escenario 12: sin conexión no sube ni guarda nada', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(
        editar(miPublicacion('p1'), borrador(fotos: [foto1Guardada, fotoJpg()])),
        throwsA(isA<SinConexionFailure>()),
      );
      verificarQueNoSeGuardo();
    });

    test(
        'Escenario 13: si el guardado falla, borra solo la foto nueva y conserva las que ya '
        'estaban', () async {
      // ARRANGE
      stubEditar((_) async => throw const GestionarPublicacionFailure());

      // ACT + ASSERT
      await expectLater(
        editar(miPublicacion('p1'), borrador(fotos: [foto1Guardada, fotoJpg()])),
        throwsA(isA<GestionarPublicacionFailure>()),
      );
      verify(() => repositorio.eliminarFotos(const [rutaNueva])).called(1);
      verifyNever(() => repositorio.eliminarFotos(const [rutaFoto2]));
    });

    test('un error inesperado al guardar se traduce y limpia la foto nueva', () async {
      // ARRANGE
      stubEditar((_) async => throw StateError('falla rara'));

      // ACT + ASSERT
      await expectLater(
        editar(miPublicacion('p1'), borrador(fotos: [fotoJpg()])),
        throwsA(isA<GestionarPublicacionFailure>()),
      );
      verify(() => repositorio.eliminarFotos(const [rutaNueva])).called(1);
    });

    test('Escenario 10: si no es suya, el fallo del servidor pasa tal cual', () async {
      // ARRANGE
      stubEditar((_) async => throw const ModificarSinPermisoFailure());

      // ACT + ASSERT
      await expectLater(
        editar(miPublicacion('p1'), borrador(fotos: [foto1Guardada])),
        throwsA(isA<ModificarSinPermisoFailure>()),
      );
      verifyNever(() => repositorio.eliminarFotos(any()));
    });
  });

  group('Fotos ya guardadas (HU-06)', () {
    test('no se validan de nuevo: el validador las acepta', () {
      expect(const PublicacionValidator().validarFoto(foto1Guardada), isNull);
      expect(const PublicacionValidator().validarFotos([foto1Guardada]), isNull);
    });

    test('saben su ruta y su URL, y una foto nueva no', () {
      expect(foto1Guardada.yaGuardada, isTrue);
      expect(foto1Guardada.url, 'https://fotos/1.jpg');
      expect(fotoJpg().yaGuardada, isFalse);
      expect(fotoJpg().ruta, isNull);
    });
  });
}
