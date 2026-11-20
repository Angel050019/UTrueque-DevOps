import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:utrueque/features/feed/presentation/cubit/feed_state.dart';
import 'package:utrueque/features/feed/presentation/cubit/opciones_filtro.dart';
import 'package:utrueque/features/perfil/domain/entities/carrera.dart';
import 'package:utrueque/features/perfil/domain/entities/division.dart';
import 'package:utrueque/features/perfil/domain/entities/perfil.dart';
import 'package:utrueque/features/perfil/domain/usecases/obtener_catalogo_academico.dart';
import 'package:utrueque/features/perfil/domain/usecases/obtener_perfil.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/filtros_feed.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/buscar_publicaciones.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_categorias.dart';

import '../../publicaciones/fixtures.dart';

class _MockBuscarPublicaciones extends Mock implements BuscarPublicaciones {}

class _MockObtenerCategorias extends Mock implements ObtenerCategorias {}

class _MockObtenerCatalogo extends Mock implements ObtenerCatalogoAcademico {}

class _MockObtenerPerfil extends Mock implements ObtenerPerfil {}

const Carrera _software =
    Carrera(id: 102, divisionId: 11, nombre: 'Ingeniería en Desarrollo y Gestión de Software');
const Carrera _mecatronica = Carrera(id: 101, divisionId: 11, nombre: 'Ingeniería en Mecatrónica');
const Carrera _quimica = Carrera(id: 107, divisionId: 12, nombre: 'Ingeniería Química');

const List<Division> _catalogo = [
  Division(
    id: 11,
    nombre: 'Mecatrónica, Desarrollo de Software e Ingeniería Civil',
    carreras: [_mecatronica, _software],
  ),
  Division(id: 12, nombre: 'Química y Energías Renovables', carreras: [_quimica]),
];

const Perfil _miPerfil = Perfil(
  id: 'yo',
  nombreMostrar: 'Ana López',
  divisionId: 11,
  divisionNombre: 'Mecatrónica, Desarrollo de Software e Ingeniería Civil',
  carreraId: 102,
  carreraNombre: 'Ingeniería en Desarrollo y Gestión de Software',
  perfilCompleto: true,
);

/// Opciones cuando el Cubit no tiene de dónde pedirlas (pruebas de HU-04).
const OpcionesFiltro _sinOpciones = OpcionesFiltro(perfilLeido: true);

/// Opciones completas con el perfil de Ana (Software).
const OpcionesFiltro _opciones = OpcionesFiltro(
  categorias: [categoriaLibros, categoriaCalculadoras],
  divisiones: _catalogo,
  miCarrera: _software,
  perfilLeido: true,
);

const FiltrosFeed _sinFiltros = FiltrosFeed();
const FiltrosFeed _miCarrera = FiltrosFeed(divisionId: 11, carreraId: 102);

void main() {
  late _MockBuscarPublicaciones buscar;
  late _MockObtenerCategorias obtenerCategorias;
  late _MockObtenerCatalogo obtenerCatalogo;
  late _MockObtenerPerfil obtenerPerfil;

  setUp(() {
    buscar = _MockBuscarPublicaciones();
    obtenerCategorias = _MockObtenerCategorias();
    obtenerCatalogo = _MockObtenerCatalogo();
    obtenerPerfil = _MockObtenerPerfil();
  });

  /// Cubit solo con la búsqueda (las pruebas de HU-04).
  FeedCubit crearCubit() => FeedCubit(buscarPublicaciones: buscar);

  /// Cubit con todo: categorías, catálogo y perfil (HU-05).
  FeedCubit crearCubitCompleto({Duration espera = const Duration(milliseconds: 20)}) => FeedCubit(
        buscarPublicaciones: buscar,
        obtenerCategorias: obtenerCategorias,
        obtenerCatalogo: obtenerCatalogo,
        obtenerPerfil: obtenerPerfil,
        espera: espera,
      );

  void opcionesDisponibles() {
    when(() => obtenerCategorias()).thenAnswer((_) async => [categoriaLibros, categoriaCalculadoras]);
    when(() => obtenerCatalogo()).thenAnswer((_) async => _catalogo);
    when(() => obtenerPerfil()).thenAnswer((_) async => _miPerfil);
  }

  List<Publicacion> publicaciones(List<String> ids) => ids.map(publicacionDelFeed).toList();

  /// Feed ya cargado con [ids]; si [hayMas], con cursor a la última.
  FeedCargado cargado(
    List<String> ids, {
    bool hayMas = false,
    FiltrosFeed filtros = _sinFiltros,
    OpcionesFiltro opciones = const OpcionesFiltro(),
  }) =>
      FeedCargado(
        publicaciones: publicaciones(ids),
        siguiente: hayMas ? cursorDe(ids.last) : null,
        filtros: filtros,
        opciones: opciones,
      );

  void responder(FiltrosFeed filtros, PaginaFeed pagina, {CursorFeed? despuesDe}) {
    if (despuesDe == null) {
      when(() => buscar(filtros: filtros)).thenAnswer((_) async => pagina);
    } else {
      when(() => buscar(filtros: filtros, despuesDe: despuesDe)).thenAnswer((_) async => pagina);
    }
  }

  test('empieza cargando, sin filtros', () {
    final FeedCubit cubit = crearCubit();
    expect(cubit.state, const FeedCargando());
    expect(cubit.state.filtros.hayFiltros, isFalse);
  });

  // =======================================================================
  // HU-04: Feed de publicaciones
  // =======================================================================

  group('HU-04, Escenario 1: ver el Feed', () {
    blocTest<FeedCubit, FeedState>(
      'cargar muestra la primera página',
      setUp: () => responder(_sinFiltros, paginaFeed(['a', 'b'], hayMas: true)),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => [
        const FeedCargando(),
        const FeedCargando(opciones: _sinOpciones),
        cargado(['a', 'b'], hayMas: true, opciones: _sinOpciones),
      ],
    );
  });

  group('HU-04, Escenario 2: cargar más al hacer scroll', () {
    blocTest<FeedCubit, FeedState>(
      'agrega la siguiente página al final usando el cursor de la última',
      setUp: () => responder(_sinFiltros, paginaFeed(['c']), despuesDe: cursorDe('b')),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      expect: () => [
        cargado(['a', 'b'], hayMas: true).copyWith(cargandoMas: true),
        cargado(['a', 'b', 'c']),
      ],
      verify: (cubit) {
        verify(() => buscar(filtros: _sinFiltros, despuesDe: cursorDe('b'))).called(1);
        expect((cubit.state as FeedCargado).hayMas, isFalse);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'no repite publicaciones que ya están en la lista',
      setUp: () => responder(_sinFiltros, paginaFeed(['b', 'c']), despuesDe: cursorDe('b')),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      skip: 1,
      expect: () => [cargado(['a', 'b', 'c'])],
    );

    blocTest<FeedCubit, FeedState>(
      'no hace nada si ya no hay más',
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.cargarMas(),
      expect: () => const <FeedState>[],
      verify: (_) => verifyZeroInteractions(buscar),
    );

    blocTest<FeedCubit, FeedState>(
      'no pide dos veces la misma página si ya se está cargando',
      build: crearCubit,
      seed: () => cargado(['a'], hayMas: true).copyWith(cargandoMas: true),
      act: (cubit) => cubit.cargarMas(),
      expect: () => const <FeedState>[],
      verify: (_) => verifyZeroInteractions(buscar),
    );

    blocTest<FeedCubit, FeedState>(
      'si falla al cargar más, conserva la lista y muestra el error al final',
      setUp: () => when(() => buscar(filtros: _sinFiltros, despuesDe: cursorDe('b')))
          .thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      skip: 1,
      expect: () => [
        cargado(['a', 'b'], hayMas: true)
            .copyWith(errorMas: () => const SinConexionFailure().mensaje),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'un error inesperado al cargar más se muestra con el mensaje genérico',
      setUp: () => when(() => buscar(filtros: _sinFiltros, despuesDe: cursorDe('b')))
          .thenThrow(StateError('x')),
      build: crearCubit,
      seed: () => cargado(['a', 'b'], hayMas: true),
      act: (cubit) => cubit.cargarMas(),
      skip: 1,
      expect: () => [
        cargado(['a', 'b'], hayMas: true)
            .copyWith(errorMas: () => const CargarPublicacionesFailure().mensaje),
      ],
    );
  });

  group('HU-04, Escenario 3: jalar para actualizar', () {
    blocTest<FeedCubit, FeedState>(
      'vuelve a cargar desde el inicio sin mostrar el indicador de carga',
      setUp: () => responder(_sinFiltros, paginaFeed(['nueva', 'a'])),
      build: crearCubit,
      seed: () => cargado(['a', 'b', 'c']),
      act: (cubit) => cubit.actualizar(),
      expect: () => [cargado(['nueva', 'a'])],
    );

    test('si se actualiza mientras se cargaba más, la página vieja se ignora', () async {
      // ARRANGE: primera carga con [a, b]; la siguiente página tarda y,
      // mientras, el alumno jala para actualizar y llega [nueva].
      int llamadas = 0;
      when(() => buscar(filtros: _sinFiltros)).thenAnswer(
        (_) async => ++llamadas == 1 ? paginaFeed(['a', 'b'], hayMas: true) : paginaFeed(['nueva']),
      );
      final Completer<PaginaFeed> paginaLenta = Completer<PaginaFeed>();
      when(() => buscar(filtros: _sinFiltros, despuesDe: cursorDe('b')))
          .thenAnswer((_) => paginaLenta.future);
      final FeedCubit cubit = crearCubit();
      await cubit.cargar();

      // ACT
      final Future<void> cargandoMas = cubit.cargarMas();
      await cubit.actualizar();
      paginaLenta.complete(paginaFeed(['c']));
      await cargandoMas;

      // ASSERT
      expect(cubit.state, cargado(['nueva'], opciones: _sinOpciones));
      await cubit.close();
    });
  });

  group('HU-04, Escenario 4: Feed vacío', () {
    blocTest<FeedCubit, FeedState>(
      'sin publicaciones y sin filtros muestra el estado vacío',
      setUp: () => responder(_sinFiltros, const PaginaFeed(publicaciones: [])),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      expect: () => const [
        FeedCargando(),
        FeedCargando(opciones: _sinOpciones),
        FeedVacio(opciones: _sinOpciones),
      ],
    );
  });

  group('HU-04, Escenario 5: sin conexión', () {
    blocTest<FeedCubit, FeedState>(
      'en la primera carga muestra el error con "Reintentar"',
      setUp: () => when(() => buscar(filtros: _sinFiltros)).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      skip: 2,
      expect: () => const [FeedError(SinConexionFailure(), opciones: _sinOpciones)],
      verify: (cubit) {
        final FeedError error = cubit.state as FeedError;
        expect(error.sinConexion, isTrue);
        expect(error.mensaje, 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.');
      },
    );

    blocTest<FeedCubit, FeedState>(
      'al actualizar conserva la lista y avisa una sola vez',
      setUp: () => when(() => buscar(filtros: _sinFiltros)).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) async {
        await cubit.actualizar();
        cubit.avisoMostrado();
        cubit.avisoMostrado(); // la segunda vez ya no hay nada que limpiar
      },
      expect: () => [
        cargado(['a']).copyWith(aviso: () => const SinConexionFailure().mensaje),
        cargado(['a']),
      ],
    );
  });

  group('HU-04, Escenario 6: error del servidor', () {
    blocTest<FeedCubit, FeedState>(
      'muestra el mensaje genérico, también ante un error inesperado',
      setUp: () => when(() => buscar(filtros: _sinFiltros)).thenThrow(StateError('fallo en 10.0.0.8')),
      build: crearCubit,
      act: (cubit) => cubit.cargar(),
      skip: 2,
      expect: () => const [FeedError(CargarPublicacionesFailure(), opciones: _sinOpciones)],
      verify: (cubit) {
        final FeedError error = cubit.state as FeedError;
        expect(error.sinConexion, isFalse);
        expect(error.mensaje, isNot(contains('10.0.0.8')));
      },
    );
  });

  group('HU-04, Escenarios 9 y 10: sincronizar con el detalle', () {
    blocTest<FeedCubit, FeedState>(
      'una publicación borrada desaparece de la lista',
      build: crearCubit,
      seed: () => cargado(['a', 'b']),
      act: (cubit) => cubit.sincronizar('a', null),
      expect: () => [cargado(['b'])],
    );

    blocTest<FeedCubit, FeedState>(
      'una publicación vendida desaparece y, si era la última, queda el Feed vacío',
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.sincronizar('a', publicacionDelFeed('a', estado: const Vendido())),
      expect: () => const [FeedVacio()],
    );

    blocTest<FeedCubit, FeedState>(
      'con filtros puestos, si se va la última queda "sin resultados"',
      build: crearCubit,
      seed: () => cargado(['a'], filtros: _miCarrera),
      act: (cubit) => cubit.sincronizar('a', null),
      expect: () => const [FeedSinResultados(filtros: _miCarrera)],
    );

    blocTest<FeedCubit, FeedState>(
      'una publicación reservada se actualiza en su lugar',
      build: crearCubit,
      seed: () => cargado(['a', 'b']),
      act: (cubit) => cubit.sincronizar('b', publicacionDelFeed('b', estado: const Reservado())),
      expect: () => [
        FeedCargado(publicaciones: [
          publicacionDelFeed('a'),
          publicacionDelFeed('b', estado: const Reservado()),
        ]),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'si el Feed no está cargado no hace nada',
      build: crearCubit,
      act: (cubit) {
        cubit.sincronizar('a', null);
        cubit.avisoMostrado();
      },
      expect: () => const <FeedState>[],
    );
  });

  // =======================================================================
  // HU-05: Búsqueda y filtros
  // =======================================================================

  group('HU-05, Escenario 1: filtro por defecto con mi carrera', () {
    blocTest<FeedCubit, FeedState>(
      'al abrir pone "Mi carrera" y busca solo publicaciones de mi carrera',
      setUp: () {
        opcionesDisponibles();
        responder(_miCarrera, paginaFeed(['a']));
      },
      build: crearCubitCompleto,
      act: (cubit) => cubit.cargar(),
      expect: () => [
        const FeedCargando(),
        const FeedCargando(filtros: _miCarrera, opciones: _opciones),
        cargado(['a'], filtros: _miCarrera, opciones: _opciones),
      ],
      verify: (cubit) {
        expect(cubit.miCarreraActiva, isTrue);
        verify(() => buscar(filtros: _miCarrera)).called(1);
        verifyNever(() => buscar(filtros: _sinFiltros));
      },
    );

    blocTest<FeedCubit, FeedState>(
      'al quitar "Mi carrera" muestra las publicaciones de todas las carreras, y se puede volver a poner',
      setUp: () {
        responder(_sinFiltros, paginaFeed(['a', 'b']));
        responder(_miCarrera, paginaFeed(['a']));
      },
      build: crearCubitCompleto,
      seed: () => cargado(['a'], filtros: _miCarrera, opciones: _opciones),
      act: (cubit) async {
        await cubit.alternarMiCarrera();
        await cubit.alternarMiCarrera();
      },
      expect: () => [
        const FeedCargando(opciones: _opciones),
        cargado(['a', 'b'], opciones: _opciones),
        const FeedCargando(filtros: _miCarrera, opciones: _opciones),
        cargado(['a'], filtros: _miCarrera, opciones: _opciones),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'sin carrera en el perfil (o sin poder leerlo) no hay chip ni filtro',
      setUp: () => responder(_sinFiltros, paginaFeed(['a'])),
      build: crearCubit,
      seed: () => cargado(['a'], opciones: _sinOpciones),
      act: (cubit) => cubit.alternarMiCarrera(),
      expect: () => const <FeedState>[],
      verify: (cubit) => expect(cubit.miCarreraActiva, isFalse),
    );

    test('si al abrir no hay internet, "Reintentar" lee el perfil y pone "Mi carrera"', () async {
      // ARRANGE: la primera vez todo falla por falta de red.
      bool conRed = false;
      when(() => obtenerCategorias()).thenAnswer(
          (_) async => conRed ? [categoriaLibros, categoriaCalculadoras] : throw const SinConexionFailure());
      when(() => obtenerCatalogo())
          .thenAnswer((_) async => conRed ? _catalogo : throw const SinConexionFailure());
      when(() => obtenerPerfil())
          .thenAnswer((_) async => conRed ? _miPerfil : throw const SinConexionFailure());
      when(() => buscar(filtros: _sinFiltros)).thenThrow(const SinConexionFailure());
      responder(_miCarrera, paginaFeed(['a']));
      final FeedCubit cubit = crearCubitCompleto();

      // ACT
      await cubit.cargar();
      final FeedState sinRed = cubit.state;
      conRed = true;
      await cubit.cargar();

      // ASSERT
      expect(sinRed, isA<FeedError>());
      expect(sinRed.filtros, _sinFiltros);
      expect(sinRed.opciones.perfilLeido, isFalse);
      expect(cubit.state, cargado(['a'], filtros: _miCarrera, opciones: _opciones));
      await cubit.close();
    });

    test('si el estudiante ya cambió un filtro, "Mi carrera" no se pone sola después', () async {
      // ARRANGE: el perfil tarda; mientras, el alumno elige una categoría.
      final Completer<Perfil> perfilLento = Completer<Perfil>();
      when(() => obtenerCategorias()).thenAnswer((_) async => [categoriaLibros, categoriaCalculadoras]);
      when(() => obtenerCatalogo()).thenAnswer((_) async => _catalogo);
      when(() => obtenerPerfil()).thenAnswer((_) => perfilLento.future);
      const FiltrosFeed soloCalculadoras = FiltrosFeed(categoriaId: 2);
      responder(soloCalculadoras, paginaFeed(['calc']));
      final FeedCubit cubit = crearCubitCompleto();

      // ACT
      final Future<void> abriendo = cubit.cargar();
      await cubit.elegirCategoria(2);
      perfilLento.complete(_miPerfil);
      await abriendo;
      await cubit.cargar();

      // ASSERT: llegan las opciones (con "Mi carrera"), pero el filtro
      // sigue siendo solo la categoría que eligió.
      expect(cubit.state.filtros, soloCalculadoras);
      expect(cubit.state.opciones.miCarrera, _software);
      expect(cubit.miCarreraActiva, isFalse);
      verifyNever(() => buscar(filtros: _miCarrera));
      await cubit.close();
    });
  });

  group('HU-05, Escenario 2: buscar por palabras', () {
    const FiltrosFeed libro = FiltrosFeed(texto: 'libro');

    blocTest<FeedCubit, FeedState>(
      'escribir rápido manda UNA sola búsqueda al dejar de escribir',
      setUp: () => responder(libro, paginaFeed(['l1'])),
      build: crearCubitCompleto,
      seed: () => cargado(['a']),
      act: (cubit) {
        for (final String parcial in ['l', 'li', 'lib', 'libr', 'libro']) {
          cubit.escribirBusqueda(parcial);
        }
      },
      wait: const Duration(milliseconds: 80),
      expect: () => [const FeedCargando(filtros: libro), cargado(['l1'], filtros: libro)],
      verify: (_) {
        verify(() => buscar(filtros: libro)).called(1);
        verifyNoMoreInteractions(buscar);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'si el texto termina igual que antes (por ejemplo, escribe y borra), no busca',
      build: crearCubitCompleto,
      seed: () => cargado(['a']),
      act: (cubit) {
        cubit.escribirBusqueda('x');
        cubit.escribirBusqueda('   ');
      },
      wait: const Duration(milliseconds: 80),
      expect: () => const <FeedState>[],
      verify: (_) => verifyZeroInteractions(buscar),
    );

    blocTest<FeedCubit, FeedState>(
      'el botón "buscar" del teclado busca de inmediato, sin esperar',
      setUp: () => responder(libro, paginaFeed(['l1'])),
      build: () => crearCubitCompleto(espera: const Duration(hours: 1)),
      seed: () => cargado(['a']),
      act: (cubit) {
        cubit.escribirBusqueda('libr');
        return cubit.buscarAhora('  libro ');
      },
      expect: () => [const FeedCargando(filtros: libro), cargado(['l1'], filtros: libro)],
    );
  });

  group('HU-05, Escenario 3: filtrar por división y carrera', () {
    const FiltrosFeed quimica = FiltrosFeed(divisionId: 12, carreraId: 107);

    blocTest<FeedCubit, FeedState>(
      '"Aplicar" busca con la división y la carrera elegidas',
      setUp: () => responder(quimica, paginaFeed(['q1'])),
      build: crearCubit,
      seed: () => cargado(['a'], opciones: _opciones),
      act: (cubit) => cubit.aplicarDivisionYCarrera(divisionId: 12, carreraId: 107),
      expect: () => [
        const FeedCargando(filtros: quimica, opciones: _opciones),
        cargado(['q1'], filtros: quimica, opciones: _opciones),
      ],
      verify: (cubit) => expect(cubit.miCarreraActiva, isFalse),
    );

    blocTest<FeedCubit, FeedState>(
      'aplicar los mismos filtros que ya están no vuelve a buscar',
      build: crearCubit,
      seed: () => cargado(['q1'], filtros: quimica),
      act: (cubit) => cubit.aplicarDivisionYCarrera(divisionId: 12, carreraId: 107),
      expect: () => const <FeedState>[],
      verify: (_) => verifyZeroInteractions(buscar),
    );
  });

  group('HU-05, Escenario 4: filtrar por categoría', () {
    const FiltrosFeed calculadoras = FiltrosFeed(categoriaId: 2);

    blocTest<FeedCubit, FeedState>(
      'elegir una categoría busca solo esa; "Todo" la quita',
      setUp: () {
        responder(calculadoras, paginaFeed(['c1']));
        responder(_sinFiltros, paginaFeed(['a', 'c1']));
      },
      build: crearCubit,
      seed: () => cargado(['a', 'c1']),
      act: (cubit) async {
        await cubit.elegirCategoria(2);
        await cubit.elegirCategoria(null);
      },
      expect: () => [
        const FeedCargando(filtros: calculadoras),
        cargado(['c1'], filtros: calculadoras),
        const FeedCargando(),
        cargado(['a', 'c1']),
      ],
    );
  });

  group('HU-05, Escenario 5: combinar búsqueda y filtros', () {
    const FiltrosFeed combinados =
        FiltrosFeed(texto: 'calculo', categoriaId: 1, divisionId: 11, carreraId: 102);

    blocTest<FeedCubit, FeedState>(
      'texto + categoría + carrera; cargar más usa el cursor y los MISMOS filtros',
      setUp: () {
        responder(combinados, paginaFeed(['x1', 'x2'], hayMas: true));
        responder(combinados, paginaFeed(['x3']), despuesDe: cursorDe('x2'));
      },
      build: crearCubit,
      seed: () => cargado(['a'], filtros: const FiltrosFeed(categoriaId: 1, divisionId: 11, carreraId: 102)),
      act: (cubit) async {
        await cubit.buscarAhora('calculo');
        await cubit.cargarMas();
      },
      skip: 2,
      expect: () => [
        cargado(['x1', 'x2'], hayMas: true, filtros: combinados).copyWith(cargandoMas: true),
        cargado(['x1', 'x2', 'x3'], filtros: combinados),
      ],
      verify: (_) {
        verify(() => buscar(filtros: combinados)).called(1);
        verify(() => buscar(filtros: combinados, despuesDe: cursorDe('x2'))).called(1);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'jalar para actualizar recarga desde el inicio conservando los filtros',
      setUp: () => responder(combinados, paginaFeed(['nueva', 'x1'])),
      build: crearCubit,
      seed: () => cargado(['x1'], filtros: combinados),
      act: (cubit) => cubit.actualizar(),
      expect: () => [cargado(['nueva', 'x1'], filtros: combinados)],
    );
  });

  group('HU-05, Escenario 6: búsqueda sin resultados', () {
    const FiltrosFeed hp = FiltrosFeed(texto: 'Calculadora Científica HP');

    blocTest<FeedCubit, FeedState>(
      'con filtros y sin coincidencias muestra "sin resultados" (no "Feed vacío")',
      setUp: () => responder(hp, const PaginaFeed(publicaciones: [])),
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.buscarAhora('Calculadora Científica HP'),
      expect: () => const [FeedCargando(filtros: hp), FeedSinResultados(filtros: hp)],
      verify: (_) => expect(
        FeedSinResultados.mensaje,
        'No se encontraron artículos que coincidan con tu búsqueda.',
      ),
    );
  });

  group('HU-05, Escenario 7: limpiar filtros', () {
    const FiltrosFeed todo = FiltrosFeed(texto: 'bata', categoriaId: 3, divisionId: 11, carreraId: 102);

    blocTest<FeedCubit, FeedState>(
      'quita texto, categoría, división y carrera y muestra el Feed como en HU-04',
      setUp: () => responder(_sinFiltros, paginaFeed(['a', 'b'])),
      build: crearCubit,
      seed: () => const FeedSinResultados(filtros: todo, opciones: _opciones),
      act: (cubit) => cubit.limpiarFiltros(),
      expect: () => [
        const FeedCargando(opciones: _opciones),
        cargado(['a', 'b'], opciones: _opciones),
      ],
      verify: (cubit) => expect(cubit.miCarreraActiva, isFalse),
    );

    blocTest<FeedCubit, FeedState>(
      'una búsqueda que estaba por mandarse se cancela',
      setUp: () => responder(_sinFiltros, paginaFeed(['a'])),
      build: crearCubitCompleto,
      seed: () => cargado(['x'], filtros: const FiltrosFeed(categoriaId: 3)),
      act: (cubit) {
        cubit.escribirBusqueda('bata');
        return cubit.limpiarFiltros();
      },
      wait: const Duration(milliseconds: 80),
      expect: () => [const FeedCargando(), cargado(['a'])],
      verify: (_) => verifyNever(() => buscar(filtros: const FiltrosFeed(texto: 'bata', categoriaId: 3))),
    );
  });

  group('HU-05, Escenario 8: sin conexión', () {
    const FiltrosFeed libros = FiltrosFeed(texto: 'libro', categoriaId: 1);
    bool conRed = false;

    blocTest<FeedCubit, FeedState>(
      'se conservan el texto y los filtros, y "Reintentar" repite la misma búsqueda',
      setUp: () {
        conRed = false;
        when(() => buscar(filtros: libros)).thenAnswer(
          (_) async => conRed ? paginaFeed(['l1']) : throw const SinConexionFailure(),
        );
      },
      build: crearCubit,
      seed: () => cargado(['a'], filtros: const FiltrosFeed(categoriaId: 1)),
      act: (cubit) async {
        await cubit.buscarAhora('libro');
        conRed = true;
        await cubit.cargar(); // botón "Reintentar"
      },
      expect: () => [
        const FeedCargando(filtros: libros),
        const FeedError(SinConexionFailure(), filtros: libros),
        const FeedCargando(filtros: libros),
        const FeedCargando(filtros: libros, opciones: _sinOpciones),
        cargado(['l1'], filtros: libros, opciones: _sinOpciones),
      ],
      verify: (_) => verify(() => buscar(filtros: libros)).called(2),
    );
  });

  group('HU-05, Escenario 9: error del servidor', () {
    const FiltrosFeed calculadoras = FiltrosFeed(categoriaId: 2);

    blocTest<FeedCubit, FeedState>(
      'muestra el mensaje genérico, sin detalles internos, y conserva los filtros',
      setUp: () => when(() => buscar(filtros: calculadoras))
          .thenThrow(StateError('relation "publicaciones" at 10.0.0.8')),
      build: crearCubit,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.elegirCategoria(2),
      expect: () => const [
        FeedCargando(filtros: calculadoras),
        FeedError(CargarPublicacionesFailure(), filtros: calculadoras),
      ],
      verify: (cubit) => expect((cubit.state as FeedError).mensaje, isNot(contains('10.0.0.8'))),
    );
  });

  group('HU-05, Escenario 10: escribir rápido no mezcla resultados', () {
    test('la respuesta de "libro" que llega tarde se ignora y quedan los de "bata"', () async {
      // ARRANGE
      final Completer<PaginaFeed> libroLento = Completer<PaginaFeed>();
      when(() => buscar(filtros: const FiltrosFeed(texto: 'libro')))
          .thenAnswer((_) => libroLento.future);
      responder(const FiltrosFeed(texto: 'bata'), paginaFeed(['b1']));
      final FeedCubit cubit = crearCubit();

      // ACT
      final Future<void> buscandoLibro = cubit.buscarAhora('libro');
      await cubit.buscarAhora('bata');
      libroLento.complete(paginaFeed(['l1']));
      await buscandoLibro;

      // ASSERT
      expect(cubit.state, cargado(['b1'], filtros: const FiltrosFeed(texto: 'bata')));
      await cubit.close();
    });
  });

  group('Opciones de los filtros', () {
    blocTest<FeedCubit, FeedState>(
      'recargarOpciones pide lo que falta (por ejemplo, al abrir la hoja sin catálogo)',
      setUp: opcionesDisponibles,
      build: crearCubitCompleto,
      seed: () => cargado(['a']),
      act: (cubit) => cubit.recargarOpciones(),
      expect: () => [cargado(['a'], opciones: _opciones)],
    );

    test('OpcionesFiltro da las carreras de una división y los nombres', () {
      expect(_opciones.completas, isTrue);
      expect(const OpcionesFiltro().completas, isFalse);
      expect(_opciones.carrerasDe(11), [_mecatronica, _software]);
      expect(_opciones.carrerasDe(null), isEmpty);
      expect(_opciones.carrerasDe(99), isEmpty);
      expect(_opciones.nombreDivision(12), 'Química y Energías Renovables');
      expect(_opciones.nombreDivision(null), isNull);
      expect(_opciones.nombreDivision(99), isNull);
      expect(_opciones.nombreCarrera(107), 'Ingeniería Química');
      expect(_opciones.nombreCarrera(102), _software.nombre);
      expect(_opciones.nombreCarrera(null), isNull);
      expect(_opciones.nombreCarrera(999), isNull);
    });

    blocTest<FeedCubit, FeedState>(
      'al cerrar la pantalla, una búsqueda pendiente ya no se manda',
      build: crearCubitCompleto,
      seed: () => cargado(['a']),
      act: (cubit) async {
        cubit.escribirBusqueda('libro');
        await cubit.close();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      },
      expect: () => const <FeedState>[],
      verify: (_) => verifyZeroInteractions(buscar),
    );
  });
}
