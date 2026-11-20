import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/chat/domain/errors/chat_failures.dart';
import 'package:utrueque/features/encuentros/domain/entities/encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/punto_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/errors/encuentro_failures.dart';
import 'package:utrueque/features/encuentros/domain/factories/creadores_solicitud.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';

import '../fixtures.dart';

void main() {
  CreadorPropuesta propuesta({
    PuntoEncuentro? punto = biblioteca,
    DateTime? fechaHora,
    bool usarFecha = true,
    Encuentro? activo,
    EstadoPublicacion? estado = const Disponible(),
    bool eliminada = false,
  }) =>
      CreadorPropuesta(
        conversacion: conversacion(estado: estado, eliminada: eliminada),
        punto: punto,
        fechaHora: usarFecha ? (fechaHora ?? jueves13) : null,
        catalogo: catalogo,
        encuentroActivo: activo,
        reloj: reloj,
      );

  group('Factory Method: todos los creadores tienen el mismo método crear()', () {
    test('cada creador fabrica su propia clase de solicitud', () {
      final List<CreadorSolicitudEncuentro> creadores = <CreadorSolicitudEncuentro>[
        propuesta(),
        CreadorRespuesta(encuentro: encuentro(), miId: idComprador, acepta: true, reloj: reloj),
        CreadorCancelacion(encuentro: encuentro(), miId: idVendedor, reloj: reloj),
      ];
      expect(creadores.map((c) => c.crear().runtimeType), [PropuestaEncuentro, RespuestaEncuentro, CancelacionEncuentro]);
    });
  });

  group('CreadorPropuesta (Escenarios 1, 5, 6, 7 y 10)', () {
    test('Escenario 1: fabrica la propuesta con el lugar y la hora en UTC', () {
      expect(
        propuesta().crear(),
        PropuestaEncuentro(conversacionId: idConversacion, puntoId: 'biblioteca', fechaHora: jueves13),
      );
    });

    test('Escenario 5: un lugar fuera del catálogo o sin elegir se rechaza', () {
      const PuntoEncuentro externo = PuntoEncuentro(id: 'plaza', nombre: 'Plaza comercial', referencia: '');
      expect(() => propuesta(punto: externo).crear(), throwsA(isA<PuntoNoPermitidoFailure>()));
      expect(
        () => propuesta(punto: null).crear(),
        throwsA(isA<PuntoNoPermitidoFailure>()
            .having((f) => f.mensaje, 'mensaje', 'Solo se permiten zonas seguras dentro de la UTSJR.')),
      );
    });

    test('Escenario 6: un horario no permitido o sin elegir se rechaza', () {
      expect(() => propuesta(fechaHora: sabado10).crear(), throwsA(isA<HorarioNoPermitidoFailure>()));
      expect(() => propuesta(usarFecha: false).crear(), throwsA(isA<HorarioNoPermitidoFailure>()));
    });

    test('Escenario 7: con un encuentro activo no se puede proponer otro', () {
      expect(() => propuesta(activo: encuentro()).crear(), throwsA(isA<EncuentroActivoFailure>()));
    });

    test('Escenario 10: con la publicación Vendida o borrada no se puede proponer', () {
      expect(() => propuesta(estado: const Vendido()).crear(), throwsA(isA<ConversacionCerradaFailure>()));
      expect(() => propuesta(eliminada: true).crear(), throwsA(isA<ConversacionCerradaFailure>()));
      expect(propuesta(estado: const Reservado()).crear(), isA<PropuestaEncuentro>());
    });
  });

  group('CreadorRespuesta (Escenarios 2, 3, 8 y 9)', () {
    test('Escenarios 2 y 3: el otro estudiante acepta o rechaza', () {
      expect(
        CreadorRespuesta(encuentro: encuentro(), miId: idComprador, acepta: true, reloj: reloj).crear(),
        const RespuestaEncuentro(encuentroId: 'enc-1', acepta: true),
      );
      expect(
        CreadorRespuesta(encuentro: encuentro(), miId: idComprador, acepta: false, reloj: reloj).crear(),
        const RespuestaEncuentro(encuentroId: 'enc-1', acepta: false),
      );
    });

    test('Escenario 8: nadie responde su propia propuesta', () {
      expect(
        () => CreadorRespuesta(encuentro: encuentro(), miId: idVendedor, acepta: true, reloj: reloj).crear(),
        throwsA(isA<EncuentroPropioFailure>()),
      );
    });

    test('Escenario 9: una propuesta vencida no se puede aceptar', () {
      expect(
        () => CreadorRespuesta(
          encuentro: encuentro(fechaHora: ahora.subtract(const Duration(minutes: 5))),
          miId: idComprador,
          acepta: true,
          reloj: reloj,
        ).crear(),
        throwsA(isA<EncuentroVencidoFailure>()),
      );
    });

    test('una propuesta ya respondida no se vuelve a responder', () {
      expect(
        () => CreadorRespuesta(
          encuentro: encuentro(estado: EstadoEncuentro.aceptado),
          miId: idComprador,
          acepta: true,
          reloj: reloj,
        ).crear(),
        throwsA(isA<EncuentroNoPendienteFailure>()),
      );
    });

    test('sin reloj usa la hora actual', () {
      final Encuentro futuro = encuentro(fechaHora: DateTime.now().toUtc().add(const Duration(days: 1)));
      expect(CreadorRespuesta(encuentro: futuro, miId: idComprador, acepta: true).crear(), isA<RespuestaEncuentro>());
      expect(CreadorCancelacion(encuentro: futuro, miId: idVendedor).crear(), isA<CancelacionEncuentro>());
    });
  });

  group('CreadorCancelacion (Escenario 4)', () {
    test('quien propuso cancela su propuesta; el otro no (la rechaza)', () {
      expect(
        CreadorCancelacion(encuentro: encuentro(), miId: idVendedor, reloj: reloj).crear(),
        const CancelacionEncuentro(encuentroId: 'enc-1'),
      );
      expect(
        () => CreadorCancelacion(encuentro: encuentro(), miId: idComprador, reloj: reloj).crear(),
        throwsA(isA<CancelarNoPermitidoFailure>()),
      );
    });

    test('un encuentro confirmado lo cancela cualquiera de los dos', () {
      final Encuentro confirmado = encuentro(estado: EstadoEncuentro.aceptado);
      expect(CreadorCancelacion(encuentro: confirmado, miId: idComprador, reloj: reloj).crear(), isA<CancelacionEncuentro>());
      expect(CreadorCancelacion(encuentro: confirmado, miId: idVendedor, reloj: reloj).crear(), isA<CancelacionEncuentro>());
    });

    test('lo que ya no está activo no se cancela', () {
      for (final EstadoEncuentro estado in <EstadoEncuentro>[EstadoEncuentro.rechazado, EstadoEncuentro.cancelado]) {
        expect(
          () => CreadorCancelacion(encuentro: encuentro(estado: estado), miId: idVendedor, reloj: reloj).crear(),
          throwsA(isA<EncuentroNoActivoFailure>()),
        );
      }
    });
  });
}
