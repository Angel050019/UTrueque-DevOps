import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/encuentros/domain/entities/solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/errors/encuentro_failures.dart';
import 'package:utrueque/features/encuentros/domain/factories/creadores_solicitud.dart';
import 'package:utrueque/features/encuentros/domain/usecases/enviar_solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/usecases/obtener_encuentros.dart';
import 'package:utrueque/features/encuentros/domain/usecases/obtener_puntos_encuentro.dart';

import '../fixtures.dart';

void main() {
  late MockEncuentrosRepository repo;
  late MockRed red;

  setUpAll(() => registerFallbackValue(const CancelacionEncuentro(encuentroId: 'x')));

  setUp(() {
    repo = MockEncuentrosRepository();
    red = MockRed();
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  CreadorPropuesta creador({DateTime? fechaHora}) => CreadorPropuesta(
        conversacion: conversacion(),
        punto: biblioteca,
        fechaHora: fechaHora ?? jueves13,
        catalogo: catalogo,
        reloj: reloj,
      );

  group('EnviarSolicitudEncuentro (patrón Factory Method)', () {
    test('Escenario 1: le pide la solicitud al creador y la envía', () async {
      when(() => repo.enviar(any())).thenAnswer((_) async {});

      final SolicitudEncuentro enviada = await EnviarSolicitudEncuentro(repo, red)(creador());

      final SolicitudEncuentro esperada =
          PropuestaEncuentro(conversacionId: idConversacion, puntoId: 'biblioteca', fechaHora: jueves13);
      expect(enviada, esperada);
      verify(() => repo.enviar(esperada)).called(1);
    });

    test('Escenario 6: si el creador rechaza, no revisa la red ni llama al servidor', () async {
      await expectLater(
        EnviarSolicitudEncuentro(repo, red)(creador(fechaHora: sabado10)),
        throwsA(isA<HorarioNoPermitidoFailure>()),
      );
      verifyNever(() => red.estaConectado);
      verifyNever(() => repo.enviar(any()));
    });

    test('Escenario 13: sin conexión no se envía nada', () async {
      when(() => red.estaConectado).thenAnswer((_) async => false);
      await expectLater(EnviarSolicitudEncuentro(repo, red)(creador()), throwsA(isA<SinConexionFailure>()));
      verifyNever(() => repo.enviar(any()));
    });

    test('Escenarios 12 y 14: el fallo del servidor llega tal cual', () async {
      when(() => repo.enviar(any())).thenThrow(const EncuentroActivoFailure());
      await expectLater(EnviarSolicitudEncuentro(repo, red)(creador()), throwsA(isA<EncuentroActivoFailure>()));
    });
  });

  group('ObtenerPuntosEncuentro y ObtenerEncuentros', () {
    test('Escenario 5: piden el catálogo y los encuentros al repositorio', () async {
      when(() => repo.obtenerPuntos()).thenAnswer((_) async => catalogo);
      when(() => repo.obtenerEncuentros(idConversacion)).thenAnswer((_) async => [encuentro()]);

      expect(await ObtenerPuntosEncuentro(repo, red)(), catalogo);
      expect(await ObtenerEncuentros(repo, red)(idConversacion), [encuentro()]);
    });

    test('Escenario 13: sin conexión no piden nada', () async {
      when(() => red.estaConectado).thenAnswer((_) async => false);
      await expectLater(ObtenerPuntosEncuentro(repo, red)(), throwsA(isA<SinConexionFailure>()));
      await expectLater(ObtenerEncuentros(repo, red)(idConversacion), throwsA(isA<SinConexionFailure>()));
      verifyZeroInteractions(repo);
    });
  });
}
