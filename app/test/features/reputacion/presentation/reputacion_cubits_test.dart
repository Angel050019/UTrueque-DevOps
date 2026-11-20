import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/reputacion/domain/entities/trato.dart';
import 'package:utrueque/features/reputacion/domain/errors/reputacion_failures.dart';
import 'package:utrueque/features/reputacion/domain/usecases/casos_de_uso_reputacion.dart';
import 'package:utrueque/features/reputacion/presentation/cubit/calificaciones_recibidas_cubit.dart';
import 'package:utrueque/features/reputacion/presentation/cubit/elegir_comprador_cubit.dart';
import 'package:utrueque/features/reputacion/presentation/cubit/reputacion_cubit.dart';
import 'package:utrueque/features/reputacion/presentation/cubit/tratos_por_calificar_cubit.dart';

import '../fixtures.dart';

void main() {
  late MockReputacionRepository repo;
  late MockRed red;

  setUpAll(() => registerFallbackValue(recibida('fallback')));

  setUp(() {
    repo = MockReputacionRepository();
    red = MockRed();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  const String sinConexion = 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.';
  const String generico = 'No pudimos completar la acción. Inténtalo de nuevo.';

  group('ReputacionCubit (Escenarios 5 a 8 y 14)', () {
    ReputacionCubit crear() => ReputacionCubit(obtenerReputacion: ObtenerReputacion(repo, red), usuarioId: idVendedor);

    test('Escenario 6: carga la reputación del otro ya calculada', () async {
      when(() => repo.resumen(idVendedor)).thenAnswer((_) async => resumen(cuatro: 1, cinco: 1));
      final ReputacionCubit cubit = crear();
      expect(cubit.state, const ReputacionCargando());

      await cubit.cargar();

      final ReputacionState state = cubit.state;
      expect(state, isA<ReputacionLista>());
      expect((state as ReputacionLista).reputacion.texto, '4.2 · 2 calificaciones');
      await cubit.close();
    });

    test('Escenario 7: sin calificaciones', () async {
      when(() => repo.resumen(idVendedor)).thenAnswer((_) async => resumen());
      final ReputacionCubit cubit = crear();
      await cubit.cargar();
      expect((cubit.state as ReputacionLista).reputacion.sinCalificaciones, isTrue);
      await cubit.close();
    });

    test('Escenario 13: sin conexión', () async {
      when(() => red.estaConectado).thenAnswer((_) async => false);
      final ReputacionCubit cubit = crear();
      await cubit.cargar();
      expect(cubit.state, const ReputacionError(sinConexion, sinConexion: true));
      await cubit.close();
    });

    test('Escenario 14: error del servidor y error inesperado', () async {
      when(() => repo.resumen(idVendedor)).thenThrow(const ReputacionServidorFailure());
      final ReputacionCubit cubit = crear();
      await cubit.cargar();
      expect(cubit.state, const ReputacionError(generico));

      when(() => repo.resumen(idVendedor)).thenThrow(Exception('interno'));
      await cubit.cargar();
      expect(cubit.state, const ReputacionError(generico));
      await cubit.close();
    });

    test('al actualizar no vuelve a "cargando" si ya había datos', () async {
      when(() => repo.resumen(idVendedor)).thenAnswer((_) async => resumen(cinco: 1));
      final ReputacionCubit cubit = crear();
      await cubit.cargar();
      final List<ReputacionState> estados = <ReputacionState>[];
      final sub = cubit.stream.listen(estados.add);

      when(() => repo.resumen(idVendedor)).thenAnswer((_) async => resumen(cinco: 2));
      await cubit.cargar();
      await Future<void>.delayed(Duration.zero);

      expect(estados.whereType<ReputacionCargando>(), isEmpty);
      expect((cubit.state as ReputacionLista).reputacion.total, 2);
      await sub.cancel();
      await cubit.close();
    });
  });

  group('TratosPorCalificarCubit (Escenarios 3, 9 y 10)', () {
    TratosPorCalificarCubit crear() => TratosPorCalificarCubit(ObtenerTratosPorCalificar(repo, red), reloj: relojRep);

    test('carga los tratos y no ofrece los vencidos', () async {
      when(() => repo.tratosPorCalificar())
          .thenAnswer((_) async => [trato(), trato(ventaId: 'vieja', diasDesdeVenta: 15, conversacionId: 'conv-9')]);
      final TratosPorCalificarCubit cubit = crear();

      await cubit.cargar();

      expect(cubit.state.cargando, isFalse);
      expect(cubit.state.tratos, [trato()]);
      expect(cubit.state.deConversacion(idConversacion), trato());
      expect(cubit.state.deConversacion('conv-9'), isNull);
      await cubit.close();
    });

    test('Escenario 9: al calificar el aviso desaparece', () async {
      when(() => repo.tratosPorCalificar()).thenAnswer((_) async => [trato()]);
      final TratosPorCalificarCubit cubit = crear();
      await cubit.cargar();

      cubit.quitar('venta-1');

      expect(cubit.state.tratos, isEmpty);
      expect(cubit.state.deConversacion(idConversacion), isNull);
      await cubit.close();
    });

    test('si falla no muestra avisos y guarda el motivo', () async {
      when(() => repo.tratosPorCalificar()).thenThrow(Exception('x'));
      final TratosPorCalificarCubit cubit = crear();
      await cubit.cargar();
      expect(cubit.state.error, generico);
      expect(cubit.state.tratos, isEmpty);

      when(() => red.estaConectado).thenAnswer((_) async => false);
      await cubit.cargar();
      expect(cubit.state.error, sinConexion);
      await cubit.close();
    });

    test('sin reloj usa la hora del celular', () async {
      when(() => repo.tratosPorCalificar()).thenAnswer((_) async => [trato(diasDesdeVenta: 400)]);
      final TratosPorCalificarCubit cubit = TratosPorCalificarCubit(ObtenerTratosPorCalificar(repo, red));
      await cubit.cargar();
      expect(cubit.state.tratos, isEmpty);
      await cubit.close();
    });
  });

  group('CalificacionesRecibidasCubit (Escenario 5)', () {
    CalificacionesRecibidasCubit crear() => CalificacionesRecibidasCubit(ObtenerCalificacionesRecibidas(repo, red));

    test('primera página y "Ver más" sin repetir', () async {
      when(() => repo.recibidas(despuesDe: null, limite: 20)).thenAnswer(
        (_) async => PaginaCalificaciones(calificaciones: [recibida('c1'), recibida('c2', horas: 2)], hayMas: true),
      );
      when(() => repo.recibidas(despuesDe: recibida('c2', horas: 2), limite: 20)).thenAnswer(
        (_) async => PaginaCalificaciones(calificaciones: [recibida('c2', horas: 2), recibida('c3', horas: 3)], hayMas: false),
      );
      final CalificacionesRecibidasCubit cubit = crear();

      await cubit.cargar();
      expect(cubit.state.calificaciones.map((c) => c.id), ['c1', 'c2']);
      expect(cubit.state.hayMas, isTrue);

      await cubit.cargarMas();
      expect(cubit.state.calificaciones.map((c) => c.id), ['c1', 'c2', 'c3']);
      expect(cubit.state.hayMas, isFalse);

      // Ya no hay más: no pide otra página.
      await cubit.cargarMas();
      verify(() => repo.recibidas(despuesDe: any(named: 'despuesDe'), limite: 20)).called(2);
      await cubit.close();
    });

    test('sin calificaciones', () async {
      when(() => repo.recibidas(despuesDe: null, limite: 20))
          .thenAnswer((_) async => const PaginaCalificaciones(calificaciones: [], hayMas: false));
      final CalificacionesRecibidasCubit cubit = crear();
      await cubit.cargar();
      expect(cubit.state.calificaciones, isEmpty);
      expect(cubit.state.error, isNull);
      await cubit.close();
    });

    test('error en la primera página y en la siguiente (lo cargado se conserva)', () async {
      when(() => repo.recibidas(despuesDe: null, limite: 20)).thenThrow(const ReputacionServidorFailure());
      final CalificacionesRecibidasCubit cubit = crear();
      await cubit.cargar();
      expect(cubit.state.error, generico);

      when(() => repo.recibidas(despuesDe: null, limite: 20))
          .thenAnswer((_) async => PaginaCalificaciones(calificaciones: [recibida('c1')], hayMas: true));
      when(() => repo.recibidas(despuesDe: recibida('c1'), limite: 20)).thenThrow(Exception('x'));
      await cubit.cargar();
      await cubit.cargarMas();

      expect(cubit.state.calificaciones.map((c) => c.id), ['c1']);
      expect(cubit.state.errorMas, generico);
      expect(cubit.state.cargandoMas, isFalse);
      await cubit.close();
    });
  });

  group('ElegirCompradorCubit (Escenarios 1 y 2)', () {
    ElegirCompradorCubit crear() =>
        ElegirCompradorCubit(publicacionId: 'pub-1', obtener: ObtenerCompradoresPosibles(repo, red));

    test('carga quiénes le escribieron y elige a uno', () async {
      when(() => repo.compradoresPosibles('pub-1')).thenAnswer((_) async => [beto, caro]);
      final ElegirCompradorCubit cubit = crear();
      expect(cubit.state.completa, isFalse);

      await cubit.cargar();
      cubit.elegir(caro);

      expect(cubit.state.compradores, [beto, caro]);
      expect(cubit.state.eleccion, const EleccionVenta.a('conv-2', nombre: 'Caro Mena'));
      expect(cubit.state.completa, isTrue);
      await cubit.close();
    });

    test('Escenario 2: "Lo vendí fuera de UTrueque"', () async {
      when(() => repo.compradoresPosibles('pub-1')).thenAnswer((_) async => const []);
      final ElegirCompradorCubit cubit = crear();
      await cubit.cargar();

      cubit.elegirFueraDeUTrueque();

      expect(cubit.state.eleccion?.fueraDeUTrueque, isTrue);
      await cubit.close();
    });

    test('al recargar, si el elegido ya no está, se borra la elección', () async {
      when(() => repo.compradoresPosibles('pub-1')).thenAnswer((_) async => [beto, caro]);
      final ElegirCompradorCubit cubit = crear();
      await cubit.cargar();
      cubit.elegir(caro);

      when(() => repo.compradoresPosibles('pub-1')).thenAnswer((_) async => [beto]);
      await cubit.cargar();
      expect(cubit.state.eleccion, isNull);

      cubit.elegir(beto);
      await cubit.cargar();
      expect(cubit.state.eleccion?.conversacionId, idConversacion);
      await cubit.close();
    });

    test('Escenario 13: sin conexión muestra el error y deja elegir "fuera de UTrueque"', () async {
      when(() => red.estaConectado).thenAnswer((_) async => false);
      final ElegirCompradorCubit cubit = crear();
      await cubit.cargar();

      expect(cubit.state.error, sinConexion);
      cubit.elegirFueraDeUTrueque();
      expect(cubit.state.completa, isTrue);

      when(() => repo.compradoresPosibles('pub-1')).thenThrow(Exception('x'));
      when(() => red.estaConectado).thenAnswer((_) async => true);
      await cubit.cargar();
      expect(cubit.state.error, generico);
      await cubit.close();
    });

    test('SinConexionFailure es un Failure con el mensaje de siempre', () {
      expect(const SinConexionFailure().mensaje, sinConexion);
    });
  });
}
