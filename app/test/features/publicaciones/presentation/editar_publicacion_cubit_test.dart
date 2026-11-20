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
import 'package:utrueque/features/publicaciones/domain/usecases/editar_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_categorias.dart';
import 'package:utrueque/features/publicaciones/domain/validators/publicacion_validator.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/publicacion_cubit.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/publicacion_state.dart';

import '../fixtures.dart';

class _MockObtenerCategorias extends Mock implements ObtenerCategorias {}

class _MockCrearPublicacion extends Mock implements CrearPublicacion {}

class _MockEditarPublicacion extends Mock implements EditarPublicacion {}

/// HU-06: el formulario de "Publicar artículo" en modo "Editar publicación".
void main() {
  late _MockObtenerCategorias obtenerCategorias;
  late _MockCrearPublicacion crearPublicacion;
  late _MockEditarPublicacion editarPublicacion;

  final Publicacion original = miPublicacion('p1');
  final List<FotoArticulo> fotosOriginales = [
    FotoArticulo.guardada(ruta: rutaFoto1, url: 'https://fotos/1.jpg'),
    FotoArticulo.guardada(ruta: rutaFoto2, url: 'https://fotos/2.jpg'),
  ];

  /// El formulario como debe quedar al abrir "Editar publicación".
  PublicacionDatos datosOriginales() => PublicacionDatos(
        categorias: categorias,
        categoria: categoriaCalculadoras,
        modalidad: Modalidad.venta,
        fotos: fotosOriginales,
      );

  setUpAll(() {
    registerFallbackValue(borrador());
    registerFallbackValue(original);
  });

  setUp(() {
    obtenerCategorias = _MockObtenerCategorias();
    crearPublicacion = _MockCrearPublicacion();
    editarPublicacion = _MockEditarPublicacion();
    when(() => obtenerCategorias()).thenAnswer((_) async => categorias);
  });

  PublicacionCubit crearCubit() => PublicacionCubit(
        obtenerCategorias: obtenerCategorias,
        crearPublicacion: crearPublicacion,
        editarPublicacion: editarPublicacion,
        original: original,
      );

  test('sabe que está editando', () {
    expect(crearCubit().editando, isTrue);
    expect(
      PublicacionCubit(obtenerCategorias: obtenerCategorias, crearPublicacion: crearPublicacion)
          .editando,
      isFalse,
    );
  });

  group('Escenario 6: editar una publicación Disponible', () {
    blocTest<PublicacionCubit, PublicacionState>(
      'el formulario empieza con la categoría, la modalidad y las fotos actuales',
      build: crearCubit,
      act: (cubit) => cubit.cargarCategorias(),
      expect: () => [const PublicacionCargando(), PublicacionEditando(datosOriginales())],
      verify: (cubit) {
        final List<FotoArticulo> fotos = cubit.state.datos!.fotos;
        expect(fotos.every((f) => f.yaGuardada), isTrue);
        expect(fotos.first.url, 'https://fotos/1.jpg');
      },
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'si la categoría ya no está en el catálogo, queda sin elegir',
      setUp: () => when(() => obtenerCategorias()).thenAnswer((_) async => [categoriaLibros]),
      build: crearCubit,
      act: (cubit) => cubit.cargarCategorias(),
      skip: 1,
      verify: (cubit) => expect(cubit.state.datos!.categoria, isNull),
    );

    blocTest<PublicacionCubit, PublicacionState>(
      'guardar llama a EditarPublicacion (no crea otra) con lo capturado',
      setUp: () => when(() => editarPublicacion(any(), any()))
          .thenAnswer((_) async => miPublicacion('p1', titulo: 'Calculadora Casio')),
      build: crearCubit,
      seed: () => PublicacionEditando(datosOriginales()),
      act: (cubit) => cubit.publicar(
        titulo: 'Calculadora Casio',
        descripcion: descripcionValida,
        precioTexto: '300',
      ),
      expect: () => [
        PublicacionEnviando(datosOriginales()),
        PublicacionPublicada(datosOriginales(), miPublicacion('p1', titulo: 'Calculadora Casio')),
      ],
      verify: (_) {
        final BorradorPublicacion enviado =
            verify(() => editarPublicacion(original, captureAny())).captured.single
                as BorradorPublicacion;
        expect(enviado.titulo, 'Calculadora Casio');
        expect(enviado.precioTexto, '300');
        expect(enviado.fotos, fotosOriginales);
        verifyNever(() => crearPublicacion(any()));
      },
    );
  });

  group('Escenarios 7, 9 y 12: errores al guardar', () {
    blocTest<PublicacionCubit, PublicacionState>(
      'Escenario 7: los errores por campo se marcan en rojo y el formulario se conserva',
      setUp: () => when(() => editarPublicacion(any(), any())).thenThrow(
        const PublicacionInvalidaFailure(
          {CampoPublicacion.precio: PublicacionValidator.mensajePrecioVacio},
        ),
      ),
      build: crearCubit,
      seed: () => PublicacionEditando(datosOriginales()),
      act: (cubit) => cubit.publicar(titulo: tituloValido, descripcion: descripcionValida),
      skip: 1,
      verify: (cubit) => expect(
        cubit.state.datos!.errorDe(CampoPublicacion.precio),
        PublicacionValidator.mensajePrecioVacio,
      ),
    );

    for (final Failure falla in const [AccionNoPermitidaFailure(), SinConexionFailure()]) {
      blocTest<PublicacionCubit, PublicacionState>(
        'Escenarios 9 y 12: "${falla.mensaje}" se muestra y el formulario se conserva',
        setUp: () => when(() => editarPublicacion(any(), any())).thenThrow(falla),
        build: crearCubit,
        seed: () => PublicacionEditando(datosOriginales()),
        act: (cubit) => cubit.publicar(titulo: tituloValido, descripcion: descripcionValida),
        skip: 1,
        expect: () => [PublicacionError(falla, datos: datosOriginales())],
      );
    }
  });
}
