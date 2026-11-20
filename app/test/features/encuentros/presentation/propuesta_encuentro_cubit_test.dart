import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/chat/domain/errors/chat_failures.dart';
import 'package:utrueque/features/encuentros/domain/entities/punto_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/errors/encuentro_failures.dart';
import 'package:utrueque/features/encuentros/domain/factories/creadores_solicitud.dart';
import 'package:utrueque/features/encuentros/domain/usecases/enviar_solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/usecases/obtener_puntos_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/validators/horario_encuentro.dart';
import 'package:utrueque/features/encuentros/presentation/cubit/propuesta_encuentro_cubit.dart';

import '../fixtures.dart';

class _MockPuntos extends Mock implements ObtenerPuntosEncuentro {}

class _MockEnviar extends Mock implements EnviarSolicitudEncuentro {}

class _FakeCreador extends Fake implements CreadorSolicitudEncuentro {}

void main() {
  late _MockPuntos puntos;
  late _MockEnviar enviar;

  setUpAll(() => registerFallbackValue(_FakeCreador()));

  setUp(() {
    puntos = _MockPuntos();
    enviar = _MockEnviar();
    when(() => puntos()).thenAnswer((_) async => catalogo);
    when(() => enviar(any())).thenAnswer(
      (inv) async => (inv.positionalArguments.first as CreadorSolicitudEncuentro).crear(),
    );
  });

  PropuestaEncuentroCubit crearCubit({bool conActivo = false}) => PropuestaEncuentroCubit(
        conversacion: conversacion(),
        obtenerPuntos: puntos,
        enviarSolicitud: enviar,
        encuentroActivo: conActivo ? encuentro() : null,
        reloj: reloj,
      );

  final DateTime jueves = DateTime.utc(2026, 11, 12);

  group('Escenarios 5 y 6: la hoja solo ofrece lugares del catálogo y horarios permitidos', () {
    test('carga el catálogo y los días; elige el primer día disponible', () async {
      final PropuestaEncuentroCubit cubit = crearCubit();
      await cubit.cargar();

      expect(cubit.state.cargando, isFalse);
      expect(cubit.state.puntos, catalogo);
      expect(cubit.state.dias, const HorarioEncuentro().diasDisponibles(ahora: ahora));
      expect(cubit.state.dia, DateTime.utc(2026, 11, 11));
      expect(HorarioEncuentro.formatearHora(cubit.state.horas.first), '10:30');
      expect(cubit.state.hora, isNull);
      expect(cubit.state.completa, isFalse);
      await cubit.close();
    });

    test('al cambiar de día se ofrecen sus horarios y se borra la hora elegida', () async {
      final PropuestaEncuentroCubit cubit = crearCubit();
      await cubit.cargar();
      cubit.elegirHora(cubit.state.horas.first);
      cubit.elegirDia(jueves);

      expect(cubit.state.dia, jueves);
      expect(cubit.state.horas, hasLength(27));
      expect(cubit.state.hora, isNull);
      await cubit.close();
    });

    test('Escenario 13: sin conexión se muestra el error del catálogo y se puede reintentar', () async {
      when(() => puntos()).thenThrow(const SinConexionFailure());
      final PropuestaEncuentroCubit cubit = crearCubit();
      await cubit.cargar();
      expect(cubit.state.errorCatalogo, 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.');

      when(() => puntos()).thenAnswer((_) async => catalogo);
      await cubit.cargar();
      expect(cubit.state.errorCatalogo, isNull);
      expect(cubit.state.puntos, catalogo);
      await cubit.close();
    });

    test('Escenario 14: un error inesperado da el mensaje genérico', () async {
      when(() => puntos()).thenThrow(StateError('x'));
      final PropuestaEncuentroCubit cubit = crearCubit();
      await cubit.cargar();
      expect(cubit.state.errorCatalogo, 'No pudimos completar la acción. Inténtalo de nuevo.');
      await cubit.close();
    });
  });

  group('Escenario 1: enviar la propuesta', () {
    test('con lugar, día y hora se envía con el CreadorPropuesta', () async {
      final PropuestaEncuentroCubit cubit = crearCubit();
      await cubit.cargar();
      cubit
        ..elegirPunto(biblioteca)
        ..elegirDia(jueves)
        ..elegirHora(jueves13);
      expect(cubit.state.completa, isTrue);

      expect(await cubit.enviar(), isTrue);

      final CreadorSolicitudEncuentro creador =
          verify(() => enviar(captureAny())).captured.single as CreadorSolicitudEncuentro;
      expect(creador, isA<CreadorPropuesta>());
      expect(
        creador.crear(),
        PropuestaEncuentro(conversacionId: idConversacion, puntoId: 'biblioteca', fechaHora: jueves13),
      );
      expect(cubit.state.enviando, isFalse);
      expect(cubit.state.error, isNull);
      await cubit.close();
    });

    test('Escenario 7: con un encuentro activo no se envía y se explica por qué', () async {
      final PropuestaEncuentroCubit cubit = crearCubit(conActivo: true);
      await cubit.cargar();
      cubit
        ..elegirPunto(biblioteca)
        ..elegirHora(jueves13);

      expect(await cubit.enviar(), isFalse);
      expect(cubit.state.error, const EncuentroActivoFailure().mensaje);
      await cubit.close();
    });

    test('Escenario 5: un lugar que no está en el catálogo no se envía', () async {
      final PropuestaEncuentroCubit cubit = crearCubit();
      await cubit.cargar();
      cubit
        ..elegirPunto(const PuntoEncuentro(id: 'plaza', nombre: 'Plaza', referencia: ''))
        ..elegirHora(jueves13);

      expect(await cubit.enviar(), isFalse);
      expect(cubit.state.error, 'Solo se permiten zonas seguras dentro de la UTSJR.');
      await cubit.close();
    });

    test('Escenario 12: si el servidor lo rechaza se conserva lo elegido', () async {
      when(() => enviar(any())).thenThrow(const DemasiadosMensajesFailure());
      final PropuestaEncuentroCubit cubit = crearCubit();
      await cubit.cargar();
      cubit
        ..elegirPunto(cafeteria)
        ..elegirDia(jueves)
        ..elegirHora(jueves13);

      expect(await cubit.enviar(), isFalse);
      expect(cubit.state.error, 'Estás enviando muchos mensajes. Espera un momento.');
      expect(cubit.state.punto, cafeteria);
      expect(cubit.state.dia, jueves);
      expect(cubit.state.hora, jueves13);

      // Al elegir otra cosa se borra el mensaje de error.
      cubit.elegirPunto(biblioteca);
      expect(cubit.state.error, isNull);
      await cubit.close();
    });
  });
}
