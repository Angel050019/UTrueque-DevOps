import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/features/reputacion/domain/errors/reputacion_failures.dart';
import 'package:utrueque/features/reputacion/domain/usecases/casos_de_uso_reputacion.dart';
import 'package:utrueque/features/reputacion/domain/validators/calificacion_validator.dart';
import 'package:utrueque/features/reputacion/presentation/cubit/calificar_cubit.dart';

import '../fixtures.dart';

void main() {
  late MockReputacionRepository repo;
  late MockRed red;

  setUp(() {
    repo = MockReputacionRepository();
    red = MockRed();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  CalificarCubit crear({int diasDesdeVenta = 1}) => CalificarCubit(
        trato: trato(diasDesdeVenta: diasDesdeVenta),
        calificar: Calificar(repo, red, reloj: relojRep),
      );

  void servidor(Future<void> Function() respuesta) => when(() => repo.calificar(
        ventaId: any(named: 'ventaId'),
        estrellas: any(named: 'estrellas'),
        comentario: any(named: 'comentario'),
      )).thenAnswer((_) => respuesta());

  test('empieza sin estrellas y con "Enviar calificación" deshabilitado', () async {
    final CalificarCubit cubit = crear();
    expect(cubit.state.estrellas, isNull);
    expect(cubit.state.completa, isFalse);
    await cubit.close();
  });

  group('Escenario 3: el comprador califica al vendedor', () {
    test('elige 5 estrellas, escribe y envía: queda enviada', () async {
      servidor(() async {});
      final CalificarCubit cubit = crear();

      cubit.elegirEstrellas(5);
      cubit.cambiarComentario('Muy puntual');
      expect(cubit.state.completa, isTrue);
      expect(cubit.state.largoComentario, 11);

      final bool enviada = await cubit.enviar();

      expect(enviada, isTrue);
      expect(cubit.state.enviada, isTrue);
      expect(cubit.state.enviando, isFalse);
      verify(() => repo.calificar(ventaId: 'venta-1', estrellas: 5, comentario: 'Muy puntual')).called(1);
      expect(CalificarCubit.mensajeGracias, '¡Gracias! Tu calificación ayuda a la comunidad.');

      // No se envía dos veces.
      expect(await cubit.enviar(), isFalse);
      await cubit.close();
    });

    test('estrellas fuera de 1 a 5 se ignoran', () async {
      final CalificarCubit cubit = crear();
      cubit.elegirEstrellas(0);
      cubit.elegirEstrellas(6);
      expect(cubit.state.estrellas, isNull);
      await cubit.close();
    });
  });

  test('Escenario 4: sin comentario también se envía', () async {
    servidor(() async {});
    final CalificarCubit cubit = crear()..elegirEstrellas(4);

    expect(await cubit.enviar(), isTrue);
    verify(() => repo.calificar(ventaId: 'venta-1', estrellas: 4, comentario: null)).called(1);
    await cubit.close();
  });

  test('Escenario 12: comentario no válido marca el campo y deshabilita el botón', () async {
    final CalificarCubit cubit = crear()..elegirEstrellas(5);

    cubit.cambiarComentario('<b>hola</b>');
    expect(cubit.state.errorComentario, CalificacionValidator.mensajeCaracteres);
    expect(cubit.state.completa, isFalse);

    cubit.cambiarComentario('a' * 201);
    expect(cubit.state.errorComentario, CalificacionValidator.mensajeLargo);

    cubit.cambiarComentario('Bien');
    expect(cubit.state.errorComentario, isNull);
    expect(cubit.state.completa, isTrue);
    await cubit.close();
  });

  test('Escenario 9: ya calificado en otro dispositivo → mensaje y el trato se cierra', () async {
    servidor(() async => throw const CalificacionDuplicadaFailure());
    final CalificarCubit cubit = crear()..elegirEstrellas(5);

    expect(await cubit.enviar(), isFalse);
    expect(cubit.state.error, 'Ya calificaste este trato.');
    expect(cubit.state.tratoCerrado, isTrue);
    await cubit.close();
  });

  test('Escenario 10: plazo vencido → mensaje y el trato se cierra', () async {
    final CalificarCubit cubit = crear(diasDesdeVenta: 15)..elegirEstrellas(5);

    expect(await cubit.enviar(), isFalse);
    expect(cubit.state.error, 'Ya pasaron los 14 días para calificar este trato.');
    expect(cubit.state.tratoCerrado, isTrue);
    await cubit.close();
  });

  test('el servidor dice que el plazo venció → también se cierra', () async {
    servidor(() async => throw const PlazoVencidoFailure());
    final CalificarCubit cubit = crear()..elegirEstrellas(5);

    expect(await cubit.enviar(), isFalse);
    expect(cubit.state.tratoCerrado, isTrue);
    await cubit.close();
  });

  test('Escenario 13: sin conexión conserva las estrellas y el comentario', () async {
    when(() => red.estaConectado).thenAnswer((_) async => false);
    final CalificarCubit cubit = crear()
      ..elegirEstrellas(3)
      ..cambiarComentario('Regular');

    expect(await cubit.enviar(), isFalse);
    expect(cubit.state.error, 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.');
    expect(cubit.state.estrellas, 3);
    expect(cubit.state.comentario, 'Regular');
    expect(cubit.state.tratoCerrado, isFalse);

    // Al cambiar algo se borra el error.
    cubit.elegirEstrellas(4);
    expect(cubit.state.error, isNull);
    await cubit.close();
  });

  test('Escenario 14: error inesperado → mensaje genérico sin detalles', () async {
    servidor(() async => throw Exception('tabla calificaciones en 10.0.0.8'));
    final CalificarCubit cubit = crear()..elegirEstrellas(5);

    expect(await cubit.enviar(), isFalse);
    expect(cubit.state.error, 'No pudimos completar la acción. Inténtalo de nuevo.');
    await cubit.close();
  });

  test('Escenario 14: un Failure del servidor se muestra tal cual', () async {
    servidor(() async => throw const ReputacionServidorFailure());
    final CalificarCubit cubit = crear()..elegirEstrellas(5);

    expect(await cubit.enviar(), isFalse);
    expect(cubit.state.error, 'No pudimos completar la acción. Inténtalo de nuevo.');
    expect(cubit.state.tratoCerrado, isFalse);
    await cubit.close();
  });

  test('no emite después de cerrarse', () async {
    final CalificarCubit cubit = crear();
    await cubit.close();
    cubit.elegirEstrellas(5);
    expect(cubit.state.estrellas, isNull);
  });
}
