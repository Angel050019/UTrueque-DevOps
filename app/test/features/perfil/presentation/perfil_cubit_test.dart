import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/perfil/domain/entities/carrera.dart';
import 'package:utrueque/features/perfil/domain/entities/division.dart';
import 'package:utrueque/features/perfil/domain/entities/foto_perfil.dart';
import 'package:utrueque/features/perfil/domain/entities/perfil.dart';
import 'package:utrueque/features/perfil/domain/usecases/actualizar_perfil.dart';
import 'package:utrueque/features/perfil/domain/usecases/obtener_catalogo_academico.dart';
import 'package:utrueque/features/perfil/domain/usecases/obtener_perfil.dart';
import 'package:utrueque/features/perfil/presentation/cubit/perfil_cubit.dart';
import 'package:utrueque/features/perfil/presentation/cubit/perfil_state.dart';

import '../fixtures.dart';

class _MockObtenerPerfil extends Mock implements ObtenerPerfil {}

class _MockObtenerCatalogo extends Mock implements ObtenerCatalogoAcademico {}

class _MockActualizarPerfil extends Mock implements ActualizarPerfil {}

void main() {
  late _MockObtenerPerfil obtenerPerfil;
  late _MockObtenerCatalogo obtenerCatalogo;
  late _MockActualizarPerfil actualizarPerfil;

  setUpAll(() {
    registerFallbackValue(fotoJpg());
    registerFallbackValue(divisionTI);
    registerFallbackValue(carreraSoftware);
  });

  setUp(() {
    obtenerPerfil = _MockObtenerPerfil();
    obtenerCatalogo = _MockObtenerCatalogo();
    actualizarPerfil = _MockActualizarPerfil();
  });

  PerfilCubit crearCubit() => PerfilCubit(
        obtenerPerfil: obtenerPerfil,
        obtenerCatalogo: obtenerCatalogo,
        actualizarPerfil: actualizarPerfil,
      );

  void stubActualizar(Future<Perfil> Function(Invocation) respuesta) {
    when(() => actualizarPerfil(
          nombre: any(named: 'nombre'),
          division: any(named: 'division'),
          carrera: any(named: 'carrera'),
          fotoNueva: any(named: 'fotoNueva'),
        )).thenAnswer(respuesta);
  }

  const PerfilDatos formularioCompleto = PerfilDatos(
    perfil: perfilVacio,
    catalogo: catalogo,
    divisionSeleccionada: divisionTI,
    carreraSeleccionada: carreraSoftware,
  );

  group('cargarMiPerfil', () {
    blocTest<PerfilCubit, PerfilState>(
      'emite [Cargando, Cargado] y preselecciona la división y carrera guardadas',
      setUp: () {
        when(() => obtenerPerfil()).thenAnswer((_) async => perfilCompleto);
        when(() => obtenerCatalogo()).thenAnswer((_) async => catalogo);
      },
      build: crearCubit,
      act: (cubit) => cubit.cargarMiPerfil(),
      expect: () => const [
        PerfilCargando(),
        PerfilCargado(PerfilDatos(
          perfil: perfilCompleto,
          catalogo: catalogo,
          divisionSeleccionada: divisionTI,
          carreraSeleccionada: carreraSoftware,
        )),
      ],
    );

    blocTest<PerfilCubit, PerfilState>(
      'con conCatalogo: false no pide el catálogo (Mi perfil)',
      setUp: () => when(() => obtenerPerfil()).thenAnswer((_) async => perfilCompleto),
      build: crearCubit,
      act: (cubit) => cubit.cargarMiPerfil(conCatalogo: false),
      expect: () => const [
        PerfilCargando(),
        PerfilCargado(PerfilDatos(perfil: perfilCompleto)),
      ],
      verify: (_) => verifyNever(() => obtenerCatalogo()),
    );

    blocTest<PerfilCubit, PerfilState>(
      'sin conexión emite PerfilError con el mensaje en español (Escenario 5)',
      setUp: () => when(() => obtenerPerfil()).thenThrow(const SinConexionFailure()),
      build: crearCubit,
      act: (cubit) => cubit.cargarMiPerfil(),
      expect: () => const [PerfilCargando(), PerfilError(SinConexionFailure())],
    );
  });

  group('selección de división y carrera', () {
    blocTest<PerfilCubit, PerfilState>(
      'al cambiar a una división a la que no pertenece la carrera, la carrera se limpia',
      build: crearCubit,
      seed: () => const PerfilCargado(formularioCompleto),
      act: (cubit) => cubit.seleccionarDivision(divisionIndustrial),
      expect: () => [
        PerfilCargado(formularioCompleto.copyWith(
          divisionSeleccionada: () => divisionIndustrial,
          carreraSeleccionada: () => null,
        )),
      ],
    );

    blocTest<PerfilCubit, PerfilState>(
      'seleccionarCarrera actualiza la carrera',
      build: crearCubit,
      seed: () => const PerfilCargado(formularioCompleto),
      act: (cubit) => cubit.seleccionarCarrera(carreraRedes),
      expect: () => [
        PerfilCargado(formularioCompleto.copyWith(carreraSeleccionada: () => carreraRedes)),
      ],
    );

    test('carrerasDisponibles depende de la división elegida', () {
      expect(formularioCompleto.carrerasDisponibles, [carreraSoftware, carreraRedes]);
      expect(const PerfilDatos(perfil: perfilVacio).carrerasDisponibles, isEmpty);
    });
  });

  group('seleccionarFoto', () {
    final FotoPerfil foto = fotoJpg();

    blocTest<PerfilCubit, PerfilState>(
      'guarda una foto válida en el estado',
      build: crearCubit,
      seed: () => const PerfilCargado(formularioCompleto),
      act: (cubit) => cubit.seleccionarFoto(foto),
      expect: () => [PerfilCargado(formularioCompleto.copyWith(fotoNueva: () => foto))],
    );

    blocTest<PerfilCubit, PerfilState>(
      'rechaza una foto de más de 5 MB y conserva el formulario (Escenario 3)',
      build: crearCubit,
      seed: () => const PerfilCargado(formularioCompleto),
      act: (cubit) => cubit.seleccionarFoto(fotoMayorA5MB()),
      expect: () => const [
        PerfilError(FotoDemasiadoGrandeFailure(), datos: formularioCompleto),
      ],
    );
  });

  group('guardar', () {
    blocTest<PerfilCubit, PerfilState>(
      'emite [Guardando, Guardado] con el perfil devuelto (Escenarios 1 y 4)',
      setUp: () => stubActualizar((_) async => perfilCompleto),
      build: crearCubit,
      seed: () => const PerfilCargado(formularioCompleto),
      act: (cubit) => cubit.guardar(nombre: 'Ana López'),
      expect: () => [
        const PerfilGuardando(formularioCompleto),
        PerfilGuardado(formularioCompleto.copyWith(perfil: perfilCompleto)),
      ],
      verify: (_) => verify(() => actualizarPerfil(
            nombre: 'Ana López',
            division: divisionTI,
            carrera: carreraSoftware,
            fotoNueva: null,
          )).called(1),
    );

    blocTest<PerfilCubit, PerfilState>(
      'si la carrera no pertenece a la división emite PerfilError (Escenario 2)',
      setUp: () => stubActualizar((_) async => throw const CarreraNoPerteneceFailure()),
      build: crearCubit,
      seed: () => const PerfilCargado(formularioCompleto),
      act: (cubit) => cubit.guardar(nombre: 'Ana López'),
      expect: () => const [
        PerfilGuardando(formularioCompleto),
        PerfilError(CarreraNoPerteneceFailure(), datos: formularioCompleto),
      ],
    );

    blocTest<PerfilCubit, PerfilState>(
      'sin conexión emite PerfilError y conserva el formulario (Escenario 5)',
      setUp: () => stubActualizar((_) async => throw const SinConexionFailure()),
      build: crearCubit,
      seed: () => const PerfilCargado(formularioCompleto),
      act: (cubit) => cubit.guardar(nombre: 'Ana López'),
      expect: () => const [
        PerfilGuardando(formularioCompleto),
        PerfilError(SinConexionFailure(), datos: formularioCompleto),
      ],
    );

    blocTest<PerfilCubit, PerfilState>(
      'un error inesperado se muestra como ServidorFailure',
      setUp: () => stubActualizar((_) async => throw Exception('boom')),
      build: crearCubit,
      seed: () => const PerfilCargado(formularioCompleto),
      act: (cubit) => cubit.guardar(nombre: 'Ana López'),
      expect: () => const [
        PerfilGuardando(formularioCompleto),
        PerfilError(ServidorFailure(), datos: formularioCompleto),
      ],
    );

    blocTest<PerfilCubit, PerfilState>(
      'descartarError regresa al formulario',
      build: crearCubit,
      seed: () => const PerfilError(SinConexionFailure(), datos: formularioCompleto),
      act: (cubit) => cubit.descartarError(),
      expect: () => const [PerfilCargado(formularioCompleto)],
    );
  });

  test('las entidades usadas en el formulario se comparan por valor', () {
    expect(
      const Division(id: 1, nombre: 'TI', carreras: [carreraSoftware, carreraRedes]),
      divisionTI,
    );
    expect(const Carrera(id: 1, divisionId: 1, nombre: 'Software'), carreraSoftware);
  });
}
