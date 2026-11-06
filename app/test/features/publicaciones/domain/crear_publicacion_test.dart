import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/crear_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/validators/publicacion_validator.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;
  late CrearPublicacion crearPublicacion;

  setUpAll(() {
    registerFallbackValue(fotoJpg());
    registerFallbackValue(Modalidad.intercambio);
  });

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    crearPublicacion = CrearPublicacion(repositorio, red);
    when(() => red.estaConectado).thenAnswer((_) async => true);
    when(() => repositorio.eliminarFotos(any())).thenAnswer((_) async {});
  });

  void stubCrear(Future<Publicacion> Function(Invocation) respuesta) {
    when(() => repositorio.crearPublicacion(
          titulo: any(named: 'titulo'),
          descripcion: any(named: 'descripcion'),
          categoriaId: any(named: 'categoriaId'),
          modalidad: any(named: 'modalidad'),
          precio: any(named: 'precio'),
          fotos: any(named: 'fotos'),
        )).thenAnswer(respuesta);
  }

  void verificarQueNoSeEnvioNada() {
    verifyNever(() => repositorio.subirFoto(any()));
    verifyNever(() => repositorio.crearPublicacion(
          titulo: any(named: 'titulo'),
          descripcion: any(named: 'descripcion'),
          categoriaId: any(named: 'categoriaId'),
          modalidad: any(named: 'modalidad'),
          precio: any(named: 'precio'),
          fotos: any(named: 'fotos'),
        ));
  }

  group('CrearPublicacion (HU-03)', () {
    test(
        'Escenario 1: con datos válidos en Intercambio sube las fotos, crea la '
        'publicación sin precio y la devuelve en estado Disponible', () async {
      // ARRANGE
      int n = 0;
      when(() => repositorio.subirFoto(any())).thenAnswer((_) async => n++ == 0 ? rutaFoto1 : rutaFoto2);
      stubCrear((_) async => publicacionGuardada(fotos: const [rutaFoto1, rutaFoto2]));

      // ACT
      final Publicacion publicacion = await crearPublicacion(borrador(
        titulo: '  $tituloValido  ',
        precioTexto: '999',
        fotos: [fotoJpg(), fotoPng()],
      ));

      // ASSERT
      expect(publicacion.usuarioId, idAlumno);
      expect(publicacion.estado, EstadoPublicacion.inicial);
      verify(() => repositorio.subirFoto(any())).called(2);
      verify(() => repositorio.crearPublicacion(
            titulo: tituloValido,
            descripcion: descripcionValida,
            categoriaId: categoriaCalculadoras.id,
            modalidad: Modalidad.intercambio,
            precio: null,
            fotos: const [rutaFoto1, rutaFoto2],
          )).called(1);
    });

    test('Escenario 1 (Venta): envía el precio convertido a número', () async {
      // ARRANGE
      when(() => repositorio.subirFoto(any())).thenAnswer((_) async => rutaFoto1);
      stubCrear((_) async => publicacionGuardada(modalidad: Modalidad.venta, precio: 250.5));

      // ACT
      await crearPublicacion(borrador(modalidad: Modalidad.venta, precioTexto: r'$250,50'));

      // ASSERT
      verify(() => repositorio.crearPublicacion(
            titulo: any(named: 'titulo'),
            descripcion: any(named: 'descripcion'),
            categoriaId: any(named: 'categoriaId'),
            modalidad: Modalidad.venta,
            precio: 250.5,
            fotos: any(named: 'fotos'),
          )).called(1);
    });

    test('Escenario 2: Venta sin precio no envía nada y marca el campo precio', () async {
      // ACT
      final Future<Publicacion> intento = crearPublicacion(borrador(modalidad: Modalidad.venta));

      // ASSERT
      await expectLater(
        intento,
        throwsA(isA<PublicacionInvalidaFailure>().having(
          (f) => f.errores[CampoPublicacion.precio],
          'error del precio',
          'Debe especificar un costo para la modalidad Venta',
        )),
      );
      verifyNever(() => red.estaConectado);
      verificarQueNoSeEnvioNada();
    });

    test('Escenario 4: una foto de más de 5 MB no se sube', () async {
      // ACT
      final Future<Publicacion> intento =
          crearPublicacion(borrador(fotos: [fotoJpg(), fotoMayorA5MB()]));

      // ASSERT
      await expectLater(
        intento,
        throwsA(isA<PublicacionInvalidaFailure>().having(
          (f) => f.errores[CampoPublicacion.fotos],
          'error de fotos',
          'Cada foto puede pesar máximo 5 MB.',
        )),
      );
      verificarQueNoSeEnvioNada();
    });

    test('Escenario 5: campos obligatorios vacíos no envían nada', () async {
      // ACT
      final Future<Publicacion> intento = crearPublicacion(borrador(
        titulo: '',
        descripcion: '',
        categoria: null,
        fotos: [],
      ));

      // ASSERT
      await expectLater(
        intento,
        throwsA(isA<PublicacionInvalidaFailure>().having(
          (f) => f.errores,
          'errores',
          {
            CampoPublicacion.titulo: PublicacionValidator.mensajeTitulo,
            CampoPublicacion.descripcion: PublicacionValidator.mensajeDescripcion,
            CampoPublicacion.categoria: PublicacionValidator.mensajeCategoria,
            CampoPublicacion.fotos: PublicacionValidator.mensajeSinFotos,
          },
        )),
      );
      verificarQueNoSeEnvioNada();
    });

    test('Escenario 6: sin conexión no sube fotos ni llama al API', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT
      final Future<Publicacion> intento = crearPublicacion(borrador());

      // ASSERT
      await expectLater(intento, throwsA(isA<SinConexionFailure>()));
      verificarQueNoSeEnvioNada();
    });

    test('si el servidor rechaza la publicación, borra las fotos ya subidas', () async {
      // ARRANGE
      when(() => repositorio.subirFoto(any())).thenAnswer((_) async => rutaFoto1);
      stubCrear((_) async => throw const PublicacionRechazadaFailure());

      // ACT
      final Future<Publicacion> intento = crearPublicacion(borrador());

      // ASSERT
      await expectLater(intento, throwsA(isA<PublicacionRechazadaFailure>()));
      verify(() => repositorio.eliminarFotos(const [rutaFoto1])).called(1);
    });

    test('un error inesperado se convierte en ServidorFailure y también limpia', () async {
      // ARRANGE
      when(() => repositorio.subirFoto(any())).thenAnswer((_) async => rutaFoto1);
      when(() => repositorio.eliminarFotos(any())).thenThrow(Exception('sin red'));
      stubCrear((_) async => throw Exception('detalle interno'));

      // ACT
      final Future<Publicacion> intento = crearPublicacion(borrador());

      // ASSERT: el detalle interno NO llega al usuario.
      await expectLater(intento, throwsA(isA<ServidorFailure>()));
      verify(() => repositorio.eliminarFotos(const [rutaFoto1])).called(1);
    });
  });
}
