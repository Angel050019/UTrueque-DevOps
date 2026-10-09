import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/borrador_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/foto_articulo.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/crear_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_categorias.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/publicacion_cubit.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/publicacion_state.dart';

import '../fixtures.dart';

class _MockObtenerCategorias extends Mock implements ObtenerCategorias {}

class _MockCrearPublicacion extends Mock implements CrearPublicacion {}

void main() {
  late _MockObtenerCategorias obtenerCategorias;
  late _MockCrearPublicacion crearPublicacion;

  final FotoArticulo foto1 = fotoJpg(1024, 'uno.jpg');
  final FotoArticulo foto2 = fotoJpg(2048, 'dos.jpg');

  setUpAll(() => registerFallbackValue(borrador()));

  setUp(() {
    obtenerCategorias = _MockObtenerCategorias();
    crearPublicacion = _MockCrearPublicacion();
  });

  PublicacionCubit crearCubit() => PublicacionCubit(
        obtenerCategorias: obtenerCategorias,
        crearPublicacion: crearPublicacion,
      );

  const PublicacionDatos vacio = PublicacionDatos(categorias: categorias);

  PublicacionDatos formularioListo() => PublicacionDatos(
        categorias: categorias,
        categoria: categoriaCalculadoras,
        modalidad: Modalidad.intercambio,
        fotos: [foto1],
      );

  group('cargarCategorias', () {
    blocTest<PublicacionCubit, PublicacionState>(
      'emite [Cargando, Editando] con el catálogo',
      setUp: () => when(() => obtenerCategorias()).thenAnswer((_) async => categorias),
      build: crearCubit,
      act: (cubit) => cubit.cargarCategorias(),
      expect: () => const [PublicacionCargando(), PublicacionEditando(vacio)],
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'Escenario 6: sin conexión emite un error de carga sin formulario',
      setUp: () => when(() => obtenerCategorias()).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      act: (cubit) => cubit.cargarCategorias(),
      expect: () => const [PublicacionCargando(), PublicacionError(SinConexionFailure())],
      verify: (cubit) => expect(
        (cubit.state as PublicacionError).mensaje,
        'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.',
      ),
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'un error inesperado se muestra como ServidorFailure',
      setUp: () => when(() => obtenerCategorias()).thenThrow(Exception('x')),
      build: crearCubit,
      act: (cubit) => cubit.cargarCategorias(),
      expect: () => const [PublicacionCargando(), PublicacionError(ServidorFailure())],
    );
  });

  group('selección de categoría y modalidad', () {
    blocTest<PublicacionCubit, PublicacionState>(
      'guarda la elección y quita el rojo de esos campos',
      build: crearCubit,
      seed: () => const PublicacionEditando(PublicacionDatos(
        categorias: categorias,
        errores: {
          CampoPublicacion.categoria: 'Elige una categoría.',
          CampoPublicacion.modalidad: 'Elige una modalidad.',
        },
      )),
      act: (cubit) => cubit
        ..seleccionarCategoria(categoriaLibros)
        ..seleccionarModalidad(Modalidad.venta),
      expect: () => const [
        PublicacionEditando(PublicacionDatos(
          categorias: categorias,
          categoria: categoriaLibros,
          errores: {CampoPublicacion.modalidad: 'Elige una modalidad.'},
        )),
        PublicacionEditando(PublicacionDatos(
          categorias: categorias,
          categoria: categoriaLibros,
          modalidad: Modalidad.venta,
        )),
      ],
      verify: (cubit) => expect(cubit.state.datos!.muestraPrecio, isTrue),
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'al cambiar de Venta a Gratis desaparece el error del precio',
      build: crearCubit,
      seed: () => const PublicacionEditando(PublicacionDatos(
        modalidad: Modalidad.venta,
        errores: {CampoPublicacion.precio: 'Debe especificar un costo para la modalidad Venta'},
      )),
      act: (cubit) => cubit.seleccionarModalidad(Modalidad.gratis),
      expect: () => const [PublicacionEditando(PublicacionDatos(modalidad: Modalidad.gratis))],
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'campoEditado quita el rojo solo si el campo lo tenía',
      build: crearCubit,
      seed: () => const PublicacionEditando(PublicacionDatos(
        errores: {CampoPublicacion.titulo: 'Escribe un título de 3 a 80 caracteres.'},
      )),
      act: (cubit) => cubit
        ..campoEditado(CampoPublicacion.descripcion)
        ..campoEditado(CampoPublicacion.titulo),
      expect: () => const [PublicacionEditando(PublicacionDatos())],
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'no hace nada mientras no hay formulario',
      build: crearCubit,
      act: (cubit) => cubit
        ..seleccionarCategoria(categoriaLibros)
        ..seleccionarModalidad(Modalidad.venta)
        ..agregarFotos([foto1])
        ..quitarFoto(0)
        ..campoEditado(CampoPublicacion.titulo)
        ..descartarError(),
      expect: () => const <PublicacionState>[],
    );
  });

  group('fotos', () {
    blocTest<PublicacionCubit, PublicacionState>(
      'agrega fotos válidas y quita el error de fotos',
      build: crearCubit,
      seed: () => const PublicacionEditando(PublicacionDatos(
        errores: {CampoPublicacion.fotos: 'Agrega al menos una foto.'},
      )),
      act: (cubit) => cubit.agregarFotos([foto1, foto2]),
      expect: () => [PublicacionEditando(PublicacionDatos(fotos: [foto1, foto2]))],
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'Escenario 4: una foto de más de 5 MB no se agrega, se avisa y lo demás se conserva',
      build: crearCubit,
      seed: () => PublicacionEditando(formularioListo()),
      act: (cubit) => cubit.agregarFotos([fotoMayorA5MB(), foto2]),
      expect: () => [
        PublicacionError(
          const FotoArticuloDemasiadoGrandeFailure(),
          datos: formularioListo().copyWith(fotos: [foto1, foto2]),
        ),
      ],
      verify: (cubit) =>
          expect((cubit.state as PublicacionError).mensaje, 'Cada foto puede pesar máximo 5 MB.'),
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'no deja pasar de 5 fotos',
      build: crearCubit,
      seed: () => PublicacionEditando(
        PublicacionDatos(fotos: List.generate(4, (i) => fotoJpg(1024 + i))),
      ),
      act: (cubit) => cubit.agregarFotos([foto1, foto2]),
      verify: (cubit) {
        final PublicacionError estado = cubit.state as PublicacionError;
        expect(estado.failure, const DemasiadasFotosFailure());
        expect(estado.datos!.fotos, hasLength(5));
      },
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'un archivo que no es JPG ni PNG se rechaza',
      build: crearCubit,
      seed: () => const PublicacionEditando(PublicacionDatos()),
      act: (cubit) => cubit.agregarFotos([fotoGif()]),
      expect: () => const [
        PublicacionError(FotoFormatoInvalidoFailure(), datos: PublicacionDatos()),
      ],
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'quitarFoto quita la foto indicada e ignora índices fuera de rango',
      build: crearCubit,
      seed: () => PublicacionEditando(PublicacionDatos(fotos: [foto1, foto2])),
      act: (cubit) => cubit
        ..quitarFoto(7)
        ..quitarFoto(0),
      expect: () => [PublicacionEditando(PublicacionDatos(fotos: [foto2]))],
    );
  });

  group('publicar', () {
    blocTest<PublicacionCubit, PublicacionState>(
      'Escenario 1: emite [Enviando, Publicada] y manda lo capturado al caso de uso',
      setUp: () => when(() => crearPublicacion(any()))
          .thenAnswer((_) async => publicacionGuardada()),
      build: crearCubit,
      seed: () => PublicacionEditando(formularioListo()),
      act: (cubit) => cubit.publicar(titulo: tituloValido, descripcion: descripcionValida),
      expect: () => [
        PublicacionEnviando(formularioListo()),
        PublicacionPublicada(formularioListo(), publicacionGuardada()),
      ],
      verify: (_) {
        final BorradorPublicacion enviado =
            verify(() => crearPublicacion(captureAny())).captured.single as BorradorPublicacion;
        expect(enviado.titulo, tituloValido);
        expect(enviado.categoria, categoriaCalculadoras);
        expect(enviado.modalidad, Modalidad.intercambio);
        expect(enviado.fotos, [foto1]);
      },
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'Escenario 2: Venta sin precio marca en rojo el campo precio',
      setUp: () => when(() => crearPublicacion(any())).thenThrow(const PublicacionInvalidaFailure(
        {CampoPublicacion.precio: 'Debe especificar un costo para la modalidad Venta'},
      )),
      build: crearCubit,
      seed: () => PublicacionEditando(formularioListo().copyWith(modalidad: () => Modalidad.venta)),
      act: (cubit) => cubit.publicar(titulo: tituloValido, descripcion: descripcionValida),
      skip: 1,
      expect: () => [
        isA<PublicacionError>().having(
          (e) => e.datos!.errorDe(CampoPublicacion.precio),
          'error del precio',
          'Debe especificar un costo para la modalidad Venta',
        ),
      ],
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'Escenario 6: sin conexión avisa y conserva el formulario',
      setUp: () => when(() => crearPublicacion(any())).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => PublicacionEditando(formularioListo()),
      act: (cubit) => cubit.publicar(titulo: tituloValido, descripcion: descripcionValida),
      expect: () => [
        PublicacionEnviando(formularioListo()),
        PublicacionError(const SinConexionFailure(), datos: formularioListo()),
      ],
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'un error inesperado se muestra como ServidorFailure',
      setUp: () => when(() => crearPublicacion(any())).thenThrow(StateError('x')),
      build: crearCubit,
      seed: () => PublicacionEditando(formularioListo()),
      act: (cubit) => cubit.publicar(titulo: tituloValido, descripcion: descripcionValida),
      skip: 1,
      expect: () => [PublicacionError(const ServidorFailure(), datos: formularioListo())],
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'no envía dos veces mientras ya se está enviando',
      build: crearCubit,
      seed: () => PublicacionEnviando(formularioListo()),
      act: (cubit) => cubit.publicar(titulo: tituloValido, descripcion: descripcionValida),
      expect: () => const <PublicacionState>[],
      verify: (_) => verifyNever(() => crearPublicacion(any())),
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'descartarError vuelve al formulario conservando los campos en rojo',
      build: crearCubit,
      seed: () => const PublicacionError(
        PublicacionInvalidaFailure({CampoPublicacion.titulo: 'Escribe un título de 3 a 80 caracteres.'}),
        datos: PublicacionDatos(
          errores: {CampoPublicacion.titulo: 'Escribe un título de 3 a 80 caracteres.'},
        ),
      ),
      act: (cubit) => cubit.descartarError(),
      expect: () => const [
        PublicacionEditando(PublicacionDatos(
          errores: {CampoPublicacion.titulo: 'Escribe un título de 3 a 80 caracteres.'},
        )),
      ],
    );
  });

  test('PublicacionPublicada guarda la publicación creada', () {
    final Publicacion publicacion = publicacionGuardada();
    final PublicacionPublicada estado = PublicacionPublicada(formularioListo(), publicacion);
    expect(estado.publicacion.usuarioId, idAlumno);
    expect(estado.datos.errorDe(CampoPublicacion.titulo), isNull);
  });
}
