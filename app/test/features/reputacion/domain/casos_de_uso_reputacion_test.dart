import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/reputacion/domain/entities/reputacion.dart';
import 'package:utrueque/features/reputacion/domain/entities/trato.dart';
import 'package:utrueque/features/reputacion/domain/errors/reputacion_failures.dart';
import 'package:utrueque/features/reputacion/domain/strategies/estrategias_reputacion.dart';
import 'package:utrueque/features/reputacion/domain/usecases/casos_de_uso_reputacion.dart';
import 'package:utrueque/features/reputacion/domain/validators/calificacion_validator.dart';

import '../fixtures.dart';

void main() {
  late MockReputacionRepository repo;
  late MockRed red;

  setUp(() {
    repo = MockReputacionRepository();
    red = MockRed();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  void sinRed() => when(() => red.estaConectado).thenAnswer((_) async => false);

  group('ObtenerCompradoresPosibles (Escenario 1)', () {
    test('pide quiénes le escribieron por la publicación', () async {
      when(() => repo.compradoresPosibles('pub-1')).thenAnswer((_) async => [beto, caro]);

      expect(await ObtenerCompradoresPosibles(repo, red)('pub-1'), [beto, caro]);
    });

    test('Escenario 13: sin conexión no llama al servidor', () async {
      sinRed();
      await expectLater(ObtenerCompradoresPosibles(repo, red)('pub-1'), throwsA(isA<SinConexionFailure>()));
      verifyNever(() => repo.compradoresPosibles(any()));
    });
  });

  group('MarcarVendida (Escenarios 1 y 2)', () {
    test('vende a quien eligió: manda la conversación y regresa la publicación Vendida', () async {
      when(() => repo.marcarVendida('pub-1', conversacionId: idConversacion)).thenAnswer((_) async => 'venta-1');

      final ResultadoVenta r = await MarcarVendida(repo, red)(
        publicacionDelVendedor(),
        const EleccionVenta.a(idConversacion),
      );

      expect(r.ventaId, 'venta-1');
      expect(r.hayTrato, isTrue);
      expect(r.mensaje, 'Listo. Ya pueden calificarse.');
      expect(r.publicacion.estado, const Vendido());
      expect(r.publicacion.id, 'pub-1');
      expect(r.publicacion.titulo, publicacionDelVendedor().titulo);
    });

    test('desde Reservada también se puede vender', () async {
      when(() => repo.marcarVendida('pub-1', conversacionId: idConversacion)).thenAnswer((_) async => 'venta-1');

      final ResultadoVenta r = await MarcarVendida(repo, red)(
        publicacionDelVendedor(estado: const Reservado()),
        const EleccionVenta.a(idConversacion),
      );
      expect(r.publicacion.estado, const Vendido());
    });

    test('Escenario 2: fuera de UTrueque no manda conversación y no hay trato', () async {
      when(() => repo.marcarVendida('pub-1', conversacionId: null)).thenAnswer((_) async => null);

      final ResultadoVenta r =
          await MarcarVendida(repo, red)(publicacionDelVendedor(), const EleccionVenta.fueraDeUTrueque());

      expect(r.hayTrato, isFalse);
      expect(r.mensaje, 'Tu publicación se marcó como Vendida.');
      verify(() => repo.marcarVendida('pub-1', conversacionId: null)).called(1);
    });

    test('patrón State: una Vendida no se vuelve a vender y no se llama al servidor', () async {
      await expectLater(
        MarcarVendida(repo, red)(publicacionDelVendedor(estado: const Vendido()), const EleccionVenta.a(idConversacion)),
        throwsA(isA<TransicionNoPermitidaFailure>()),
      );
      verifyNever(() => repo.marcarVendida(any(), conversacionId: any(named: 'conversacionId')));
    });

    test('Escenario 13: sin conexión no llama al servidor', () async {
      sinRed();
      await expectLater(
        MarcarVendida(repo, red)(publicacionDelVendedor(), const EleccionVenta.a(idConversacion)),
        throwsA(isA<SinConexionFailure>()),
      );
      verifyNever(() => repo.marcarVendida(any(), conversacionId: any(named: 'conversacionId')));
    });
  });

  group('ObtenerTratosPorCalificar (Escenario 3)', () {
    test('pide mis tratos por calificar', () async {
      when(() => repo.tratosPorCalificar()).thenAnswer((_) async => [trato()]);
      expect(await ObtenerTratosPorCalificar(repo, red)(), [trato()]);
    });

    test('sin conexión', () async {
      sinRed();
      await expectLater(ObtenerTratosPorCalificar(repo, red)(), throwsA(isA<SinConexionFailure>()));
    });
  });

  group('Calificar (Escenarios 3, 4, 10, 12 y 13)', () {
    Calificar calificar() => Calificar(repo, red, reloj: relojRep);

    void aceptaCalificar() => when(() => repo.calificar(
          ventaId: any(named: 'ventaId'),
          estrellas: any(named: 'estrellas'),
          comentario: any(named: 'comentario'),
        )).thenAnswer((_) async {});

    void nuncaSeEnvia() => verifyNever(() => repo.calificar(
          ventaId: any(named: 'ventaId'),
          estrellas: any(named: 'estrellas'),
          comentario: any(named: 'comentario'),
        ));

    test('envía la venta, las estrellas y el comentario sin espacios de más', () async {
      aceptaCalificar();

      await calificar()(trato(), estrellas: 5, comentario: '  Muy puntual  ');

      verify(() => repo.calificar(ventaId: 'venta-1', estrellas: 5, comentario: 'Muy puntual')).called(1);
    });

    test('Escenario 4: sin comentario manda null', () async {
      aceptaCalificar();

      await calificar()(trato(soyVendedor: true), estrellas: 4, comentario: '   ');

      verify(() => repo.calificar(ventaId: 'venta-1', estrellas: 4, comentario: null)).called(1);
    });

    test('sin estrellas no se envía', () async {
      await expectLater(
        calificar()(trato(), estrellas: null),
        throwsA(isA<CalificacionInvalidaFailure>().having((f) => f.mensaje, 'mensaje', CalificacionValidator.mensajeEstrellas)),
      );
      nuncaSeEnvia();
    });

    test('Escenario 12: comentario con caracteres no permitidos no se envía', () async {
      await expectLater(
        calificar()(trato(), estrellas: 5, comentario: '<script>'),
        throwsA(isA<CalificacionInvalidaFailure>().having((f) => f.mensaje, 'mensaje', CalificacionValidator.mensajeCaracteres)),
      );
      nuncaSeEnvia();
    });

    test('Escenario 10: un trato vencido no se envía', () async {
      await expectLater(calificar()(trato(diasDesdeVenta: 15), estrellas: 5), throwsA(isA<PlazoVencidoFailure>()));
      nuncaSeEnvia();
    });

    test('Escenario 13: sin conexión no se envía', () async {
      sinRed();
      await expectLater(calificar()(trato(), estrellas: 5), throwsA(isA<SinConexionFailure>()));
      nuncaSeEnvia();
    });

    test('sin reloj usa la hora del celular', () async {
      aceptaCalificar();
      final TratoPorCalificar vigente = TratoPorCalificar(
        ventaId: 'v',
        publicacionId: 'p',
        publicacionTitulo: 'T',
        soyVendedor: false,
        otroId: idVendedor,
        otroNombre: 'Ana',
        vendidaEn: DateTime.now(),
        venceEn: DateTime.now().add(const Duration(days: 14)),
      );
      await Calificar(repo, red)(vigente, estrellas: 3);
      verify(() => repo.calificar(ventaId: 'v', estrellas: 3, comentario: null)).called(1);
    });
  });

  group('ObtenerReputacion (patrón Strategy)', () {
    test('calcula la reputación con la estrategia que toca', () async {
      when(() => repo.resumen(idVendedor)).thenAnswer((_) async => resumen(cinco: 1));

      final Reputacion r = await ObtenerReputacion(repo, red)(idVendedor);

      expect(r.texto, '4.3 · 1 calificación');
      expect(r.ajustada, isTrue);
    });

    test('se le puede dar otro selector', () async {
      when(() => repo.resumen(idVendedor)).thenAnswer((_) async => resumen(cinco: 1));

      final Reputacion r = await ObtenerReputacion(
        repo,
        red,
        selector: const ElegirEstrategiaReputacion(minimoParaReal: 1),
      )(idVendedor);

      expect(r.texto, '5.0 · 1 calificación');
    });

    test('sin conexión', () async {
      sinRed();
      await expectLater(ObtenerReputacion(repo, red)(idVendedor), throwsA(isA<SinConexionFailure>()));
    });
  });

  group('ObtenerCalificacionesRecibidas (Escenario 5)', () {
    test('primera página y siguiente con la última como cursor', () async {
      final PaginaCalificaciones p1 = PaginaCalificaciones(calificaciones: [recibida('c1')], hayMas: true);
      when(() => repo.recibidas(despuesDe: null, limite: 20)).thenAnswer((_) async => p1);
      when(() => repo.recibidas(despuesDe: recibida('c1'), limite: 20))
          .thenAnswer((_) async => const PaginaCalificaciones(calificaciones: [], hayMas: false));

      final ObtenerCalificacionesRecibidas obtener = ObtenerCalificacionesRecibidas(repo, red);
      expect(await obtener(), p1);
      expect((await obtener(despuesDe: recibida('c1'))).hayMas, isFalse);
    });

    test('sin conexión', () async {
      sinRed();
      await expectLater(ObtenerCalificacionesRecibidas(repo, red)(), throwsA(isA<SinConexionFailure>()));
    });
  });
}
