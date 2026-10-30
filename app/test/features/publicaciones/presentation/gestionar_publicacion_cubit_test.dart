import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/borrar_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/cambiar_estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_detalle_publicacion.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/gestionar_publicacion_cubit.dart';
import 'package:utrueque/features/publicaciones/presentation/cubit/gestionar_publicacion_state.dart';

import '../fixtures.dart';

class _MockCambiarEstado extends Mock implements CambiarEstadoPublicacion {}

class _MockBorrar extends Mock implements BorrarPublicacion {}

class _MockObtenerDetalle extends Mock implements ObtenerDetallePublicacion {}

void main() {
  late _MockCambiarEstado cambiarEstado;
  late _MockBorrar borrar;
  late _MockObtenerDetalle obtenerDetalle;

  final Publicacion disponible = miPublicacion('p1');
  final Publicacion reservada = miPublicacion('p1', estado: const Reservado());
  final Publicacion vendida = miPublicacion('p1', estado: const Vendido());

  setUpAll(() {
    registerFallbackValue(disponible);
    registerFallbackValue(AccionEstado.reservar);
  });

  setUp(() {
    cambiarEstado = _MockCambiarEstado();
    borrar = _MockBorrar();
    obtenerDetalle = _MockObtenerDetalle();
  });

  GestionarPublicacionCubit crearCubit(Publicacion publicacion) => GestionarPublicacionCubit(
        publicacion: publicacion,
        cambiarEstado: cambiarEstado,
        borrarPublicacion: borrar,
        obtenerDetalle: obtenerDetalle,
      );

  group('Escenario 9: solo las acciones que permite el estado', () {
    test('Disponible: Reservar, Vender y Borrar; también se edita', () {
      final GestionState estado = crearCubit(disponible).state;
      expect(estado, GestionLista(disponible));
      expect(estado.operaciones, [
        OperacionGestion.reservar,
        OperacionGestion.marcarVendido,
        OperacionGestion.borrar,
      ]);
      expect(estado.sePuedeEditar, isTrue);
    });

    test('Reservado: Volver a Disponible y Vender; no se edita ni se borra', () {
      final GestionState estado = crearCubit(reservada).state;
      expect(estado.operaciones, [OperacionGestion.liberar, OperacionGestion.marcarVendido]);
      expect(estado.sePuedeEditar, isFalse);
    });

    test('Vendido: ninguna acción', () {
      final GestionState estado = crearCubit(vendida).state;
      expect(estado.operaciones, isEmpty);
      expect(estado.sePuedeEditar, isFalse);
    });

    blocTest<GestionarPublicacionCubit, GestionState>(
      'pedir una operación que el estado no permite no llama al servidor',
      build: () => crearCubit(vendida),
      act: (cubit) => cubit.elegir(OperacionGestion.reservar),
      expect: () => [GestionError(vendida, const AccionNoPermitidaFailure())],
      verify: (_) => verifyNever(() => cambiarEstado(any(), any())),
    );
  });

  group('Escenarios 3 y 4: Reservar y volver a Disponible', () {
    blocTest<GestionarPublicacionCubit, GestionState>(
      'Reservar se envía sin confirmación y termina con la publicación Reservada',
      setUp: () => when(() => cambiarEstado(disponible, AccionEstado.reservar))
          .thenAnswer((_) async => reservada),
      build: () => crearCubit(disponible),
      act: (cubit) => cubit.elegir(OperacionGestion.reservar),
      expect: () => [
        GestionEnviando(disponible, OperacionGestion.reservar),
        GestionTerminada(disponible, OperacionGestion.reservar, actualizada: reservada),
      ],
      verify: (cubit) => expect(
        (cubit.state as GestionTerminada).mensaje,
        'Tu publicación ahora está Reservada.',
      ),
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'Volver a Disponible desde Reservado',
      setUp: () => when(() => cambiarEstado(reservada, AccionEstado.liberar))
          .thenAnswer((_) async => disponible),
      build: () => crearCubit(reservada),
      act: (cubit) => cubit.elegir(OperacionGestion.liberar),
      expect: () => [
        GestionEnviando(reservada, OperacionGestion.liberar),
        GestionTerminada(reservada, OperacionGestion.liberar, actualizada: disponible),
      ],
    );
  });

  group('Escenario 5: Marcar como Vendido con confirmación', () {
    blocTest<GestionarPublicacionCubit, GestionState>(
      'primero pide confirmar y no llama al servidor',
      build: () => crearCubit(reservada),
      act: (cubit) => cubit.elegir(OperacionGestion.marcarVendido),
      expect: () => [GestionConfirmando(reservada, OperacionGestion.marcarVendido)],
      verify: (cubit) {
        verifyNever(() => cambiarEstado(any(), any()));
        final GestionConfirmando estado = cubit.state as GestionConfirmando;
        expect(estado.operacion.textoConfirmacion, 'Ya no podrás cambiar su estado ni editarla.');
      },
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'al confirmar se envía y la publicación queda Vendida',
      setUp: () => when(() => cambiarEstado(reservada, AccionEstado.marcarVendido))
          .thenAnswer((_) async => vendida),
      build: () => crearCubit(reservada),
      seed: () => GestionConfirmando(reservada, OperacionGestion.marcarVendido),
      act: (cubit) => cubit.confirmar(),
      expect: () => [
        GestionEnviando(reservada, OperacionGestion.marcarVendido),
        GestionTerminada(reservada, OperacionGestion.marcarVendido, actualizada: vendida),
      ],
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'al cancelar la publicación no cambia',
      build: () => crearCubit(reservada),
      seed: () => GestionConfirmando(reservada, OperacionGestion.marcarVendido),
      act: (cubit) => cubit.cancelar(),
      expect: () => [GestionLista(reservada)],
      verify: (_) => verifyNever(() => cambiarEstado(any(), any())),
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'confirmar o cancelar sin una confirmación pendiente no hace nada',
      build: () => crearCubit(disponible),
      act: (cubit) async {
        await cubit.confirmar();
        cubit.cancelar();
      },
      expect: () => const <GestionState>[],
    );
  });

  group('Escenario 8: Borrar con confirmación', () {
    blocTest<GestionarPublicacionCubit, GestionState>(
      'pide confirmar con el aviso de que no se puede deshacer',
      build: () => crearCubit(disponible),
      act: (cubit) => cubit.elegir(OperacionGestion.borrar),
      expect: () => [GestionConfirmando(disponible, OperacionGestion.borrar)],
      verify: (cubit) => expect(
        (cubit.state as GestionConfirmando).operacion.textoConfirmacion,
        'Se borrará la publicación y sus fotos. No se puede deshacer.',
      ),
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'al confirmar la borra y termina sin publicación actualizada',
      setUp: () => when(() => borrar(disponible)).thenAnswer((_) async {}),
      build: () => crearCubit(disponible),
      seed: () => GestionConfirmando(disponible, OperacionGestion.borrar),
      act: (cubit) => cubit.confirmar(),
      expect: () => [
        GestionEnviando(disponible, OperacionGestion.borrar),
        GestionTerminada(disponible, OperacionGestion.borrar),
      ],
      verify: (cubit) => expect((cubit.state as GestionTerminada).mensaje, 'Publicación borrada.'),
    );
  });

  group('Escenarios 9, 10, 12 y 13: errores', () {
    blocTest<GestionarPublicacionCubit, GestionState>(
      'Escenario 9: si el servidor dice que el estado cambió, muestra el estado actual',
      setUp: () {
        when(() => cambiarEstado(any(), any())).thenThrow(const AccionNoPermitidaFailure());
        when(() => obtenerDetalle('p1')).thenAnswer((_) async => vendida);
      },
      build: () => crearCubit(disponible),
      act: (cubit) => cubit.elegir(OperacionGestion.reservar),
      expect: () => [
        GestionEnviando(disponible, OperacionGestion.reservar),
        GestionError(vendida, const AccionNoPermitidaFailure()),
      ],
      verify: (cubit) => expect(
        (cubit.state as GestionError).mensaje,
        'Esa acción ya no es posible: la publicación cambió de estado.',
      ),
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'Escenario 9: si tampoco se puede recargar, conserva la publicación que tenía',
      setUp: () {
        when(() => cambiarEstado(any(), any())).thenThrow(const AccionNoPermitidaFailure());
        when(() => obtenerDetalle('p1')).thenThrow(const SinConexionFailure());
      },
      build: () => crearCubit(disponible),
      act: (cubit) => cubit.elegir(OperacionGestion.reservar),
      skip: 1,
      expect: () => [GestionError(disponible, const AccionNoPermitidaFailure())],
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'Escenario 10: publicación de otro estudiante',
      setUp: () => when(() => cambiarEstado(any(), any())).thenThrow(const ModificarSinPermisoFailure()),
      build: () => crearCubit(disponible),
      act: (cubit) => cubit.elegir(OperacionGestion.reservar),
      skip: 1,
      expect: () => [GestionError(disponible, const ModificarSinPermisoFailure())],
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'Escenario 12: sin conexión, la publicación se conserva con el mensaje',
      setUp: () => when(() => borrar(any())).thenThrow(const SinConexionFailure()),
      build: () => crearCubit(disponible),
      seed: () => GestionConfirmando(disponible, OperacionGestion.borrar),
      act: (cubit) => cubit.confirmar(),
      skip: 1,
      expect: () => [GestionError(disponible, const SinConexionFailure())],
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'Escenario 13: un error inesperado se muestra con el mensaje genérico',
      setUp: () => when(() => cambiarEstado(any(), any())).thenThrow(StateError('x')),
      build: () => crearCubit(disponible),
      act: (cubit) => cubit.elegir(OperacionGestion.reservar),
      skip: 1,
      expect: () => [GestionError(disponible, const GestionarPublicacionFailure())],
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'descartarError regresa a la lista de acciones y se puede intentar otra vez',
      setUp: () => when(() => cambiarEstado(disponible, AccionEstado.reservar))
          .thenAnswer((_) async => reservada),
      build: () => crearCubit(disponible),
      seed: () => GestionError(disponible, const SinConexionFailure()),
      act: (cubit) async {
        cubit.descartarError();
        await cubit.elegir(OperacionGestion.reservar);
      },
      expect: () => [
        GestionLista(disponible),
        GestionEnviando(disponible, OperacionGestion.reservar),
        GestionTerminada(disponible, OperacionGestion.reservar, actualizada: reservada),
      ],
    );

    blocTest<GestionarPublicacionCubit, GestionState>(
      'mientras se envía no se puede elegir otra operación',
      build: () => crearCubit(disponible),
      seed: () => GestionEnviando(disponible, OperacionGestion.reservar),
      act: (cubit) => cubit.elegir(OperacionGestion.borrar),
      expect: () => const <GestionState>[],
    );
  });

  test('sin el caso de uso de detalle, un rechazo conserva la publicación', () async {
    // ARRANGE
    when(() => cambiarEstado(any(), any())).thenThrow(const AccionNoPermitidaFailure());
    final GestionarPublicacionCubit cubit = GestionarPublicacionCubit(
      publicacion: disponible,
      cambiarEstado: cambiarEstado,
      borrarPublicacion: borrar,
    );

    // ACT
    await cubit.elegir(OperacionGestion.reservar);

    // ASSERT
    expect(cubit.state, GestionError(disponible, const AccionNoPermitidaFailure()));
    await cubit.close();
  });

  test('cada operación tiene su texto de botón y de confirmación', () {
    expect(OperacionGestion.reservar.etiqueta, 'Marcar como Reservado');
    expect(OperacionGestion.borrar.etiqueta, 'Borrar publicación');
    expect(OperacionGestion.reservar.requiereConfirmacion, isFalse);
    expect(OperacionGestion.marcarVendido.botonConfirmacion, 'Sí, marcar como Vendido');
    expect(OperacionGestion.borrar.tituloConfirmacion, '¿Borrar publicación?');
  });
}
