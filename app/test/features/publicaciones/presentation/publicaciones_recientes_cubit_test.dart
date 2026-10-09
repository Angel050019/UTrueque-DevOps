import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_publicaciones_recientes.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/publicaciones_recientes_cubit.dart';

import '../fixtures.dart';

class _MockObtenerRecientes extends Mock implements ObtenerPublicacionesRecientes {}

void main() {
  late _MockObtenerRecientes obtenerRecientes;
  final List<Publicacion> lista = [publicacionGuardada()];

  setUp(() => obtenerRecientes = _MockObtenerRecientes());

  PublicacionesRecientesCubit crearCubit() => PublicacionesRecientesCubit(obtenerRecientes);

  test('empieza cargando', () {
    expect(crearCubit().state, const RecientesCargando());
  });

  blocTest<PublicacionesRecientesCubit, RecientesState>(
    'cargar emite la lista de publicaciones',
    setUp: () => when(() => obtenerRecientes()).thenAnswer((_) async => lista),
    build: crearCubit,
    act: (cubit) => cubit.cargar(),
    expect: () => [const RecientesCargando(), RecientesCargadas(lista)],
  );

  blocTest<PublicacionesRecientesCubit, RecientesState>(
    'al recargar no quita la lista que ya está en pantalla',
    setUp: () => when(() => obtenerRecientes()).thenAnswer((_) async => const []),
    build: crearCubit,
    seed: () => RecientesCargadas(lista),
    act: (cubit) => cubit.cargar(),
    expect: () => const [RecientesCargadas([])],
  );

  blocTest<PublicacionesRecientesCubit, RecientesState>(
    'sin conexión muestra el mensaje de error',
    setUp: () => when(() => obtenerRecientes()).thenThrow(const SinConexionFailure()),
    build: crearCubit,
    act: (cubit) => cubit.cargar(),
    expect: () => const [RecientesCargando(), RecientesError(SinConexionFailure())],
    verify: (cubit) => expect(
      (cubit.state as RecientesError).mensaje,
      'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.',
    ),
  );

  blocTest<PublicacionesRecientesCubit, RecientesState>(
    'un error inesperado se muestra como ServidorFailure',
    setUp: () => when(() => obtenerRecientes()).thenThrow(StateError('x')),
    build: crearCubit,
    act: (cubit) => cubit.cargar(),
    expect: () => const [RecientesCargando(), RecientesError(ServidorFailure())],
  );
}
