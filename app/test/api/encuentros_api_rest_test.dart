// Pruebas del API REST de los puntos de encuentro con el patrón AAA
// (Sprint 8, HU-08, issue #3): CP-65 a CP-76.
//
// Igual que en chat_api_rest_test.dart, se ejercita la cadena REAL:
//
//   Caso de uso -> Creador (Factory Method) -> EncuentrosRepositoryImpl
//               -> EncuentrosRemoteDataSourceImpl -> SupabaseClient -> HTTP
//
// y solo se sustituye la red por un servidor simulado (MockClient).
//
// Ver docs/Plan_de_Pruebas.md (anexo de HU-08) y docs/Sprint8_Planning.md.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/chat/domain/errors/chat_failures.dart';
import 'package:utrueque/features/encuentros/data/datasources/encuentros_remote_datasource.dart';
import 'package:utrueque/features/encuentros/data/repositories/encuentros_repository_impl.dart';
import 'package:utrueque/features/encuentros/domain/entities/encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/punto_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/entities/solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/errors/encuentro_failures.dart';
import 'package:utrueque/features/encuentros/domain/factories/creadores_solicitud.dart';
import 'package:utrueque/features/encuentros/domain/usecases/enviar_solicitud_encuentro.dart';
import 'package:utrueque/features/encuentros/domain/usecases/obtener_encuentros.dart';
import 'package:utrueque/features/encuentros/domain/usecases/obtener_puntos_encuentro.dart';

import '../features/encuentros/fixtures.dart';

const String _urlSupabase = 'https://utrueque-pruebas.supabase.co';
const String _rpc = '/rest/v1/rpc';
const String _rutaPuntos = '/rest/v1/puntos_encuentro';
const String _tokenAcceso = 'token-de-acceso-de-pruebas';

class _RedSimulada implements NetworkInfo {
  _RedSimulada({required this.conectado});

  final bool conectado;

  @override
  Future<bool> get estaConectado async => conectado;
}

http.Response _json(int codigo, Object? cuerpo) => http.Response(
      jsonEncode(cuerpo),
      codigo,
      headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
    );

http.Response _vacia() => http.Response('', 204);

Map<String, dynamic> _sesionJson() => <String, dynamic>{
      'access_token': _tokenAcceso,
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh-token-de-pruebas',
      'user': <String, dynamic>{
        'id': idComprador,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'beto.ruiz@utsjr.edu.mx',
        'email_confirmed_at': '2026-09-20T10:00:00Z',
        'app_metadata': <String, dynamic>{'provider': 'email'},
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-09-20T10:00:00Z',
      },
    };

Map<String, dynamic> _filaEncuentro(String id, {String estado = 'propuesto', String propuestoPor = idVendedor}) =>
    <String, dynamic>{
      'id': id,
      'conversacion_id': idConversacion,
      'propuesto_por': propuestoPor,
      'punto_id': 'biblioteca',
      'punto_nombre': 'Biblioteca - Entrada Principal',
      'punto_referencia': 'Frente a la puerta principal de la biblioteca',
      'fecha_hora': '2026-11-12T19:00:00+00:00',
      'estado': estado,
      'created_at': '2026-11-11T15:00:00+00:00',
      'respondido_en': null,
    };

Map<String, dynamic> _error(String code, {String? hint, String message = 'rechazado en 10.0.0.8 (tabla encuentros)'}) =>
    <String, dynamic>{'code': code, 'details': null, 'hint': hint, 'message': message};

void main() {
  late List<http.Request> peticiones;
  late Map<String, http.Response Function(http.Request)> respuestas;
  late SupabaseClient cliente;
  late EncuentrosRepositoryImpl repositorio;
  final _RedSimulada conRed = _RedSimulada(conectado: true);
  final _RedSimulada sinRed = _RedSimulada(conectado: false);

  setUp(() async {
    peticiones = <http.Request>[];
    respuestas = <String, http.Response Function(http.Request)>{};
    final MockClient red = MockClient((http.Request p) async {
      peticiones.add(p);
      final http.Response r = p.url.path.startsWith('/auth/')
          ? _json(200, _sesionJson())
          : (respuestas['${p.method} ${p.url.path}'] ??
              (_) => _json(404, <String, dynamic>{'message': 'Ruta no simulada'}))(p);
      return http.Response.bytes(r.bodyBytes, r.statusCode, headers: r.headers, request: p);
    });
    cliente = SupabaseClient(
      _urlSupabase,
      'anon-key-de-pruebas',
      httpClient: red,
      authOptions: const AuthClientOptions(autoRefreshToken: false, authFlowType: AuthFlowType.implicit),
    );
    repositorio = EncuentrosRepositoryImpl(EncuentrosRemoteDataSourceImpl(cliente));
    await cliente.auth.signInWithPassword(email: 'beto.ruiz@utsjr.edu.mx', password: 'x');
  });

  tearDown(() async => cliente.dispose());

  List<http.Request> app() => peticiones.where((p) => !p.url.path.startsWith('/auth/')).toList();
  Map<String, dynamic> cuerpo(http.Request p) => jsonDecode(p.body) as Map<String, dynamic>;
  void cuando(String metodo, String ruta, http.Response Function(http.Request) r) => respuestas['$metodo $ruta'] = r;

  CreadorPropuesta propuesta({PuntoEncuentro punto = biblioteca, DateTime? fechaHora}) => CreadorPropuesta(
        conversacion: conversacion(),
        punto: punto,
        fechaHora: fechaHora ?? jueves13,
        catalogo: catalogo,
        reloj: reloj,
      );

  group('API REST de los puntos de encuentro (HU-08, issue #3) — patrón AAA', () {
    test(
        'CP-65 (Escenario 5): el catálogo hace GET /rest/v1/puntos_encuentro → 200, solo los activos '
        'en orden, y se pide una sola vez', () async {
      // ARRANGE
      cuando('GET', _rutaPuntos, (_) => _json(200, [
            <String, dynamic>{'id': 'biblioteca', 'nombre': 'Biblioteca - Entrada Principal', 'referencia': 'Frente a la puerta'},
            <String, dynamic>{'id': 'cafeteria', 'nombre': 'Cafetería - Área de mesas', 'referencia': 'Junto a la barra'},
          ]));
      final ObtenerPuntosEncuentro obtener = ObtenerPuntosEncuentro(repositorio, conRed);

      // ACT
      final List<PuntoEncuentro> lista = await obtener();
      await obtener();

      // ASSERT: respuesta interpretada
      expect(lista.map((p) => p.id), ['biblioteca', 'cafeteria']);
      expect(lista.first.nombre, 'Biblioteca - Entrada Principal');

      // ASSERT: una sola petición, con filtro de activos y orden
      final http.Request p = app().single;
      expect(p.method, 'GET');
      expect(p.url.queryParameters['select'], allOf(contains('nombre'), contains('referencia')));
      expect(p.url.queryParameters['activo'], 'eq.true');
      expect(p.url.queryParameters['order'], startsWith('orden'));
      expect(p.headers['Authorization'], 'Bearer $_tokenAcceso');
    });

    test(
        'CP-66 (Escenario 1): proponer hace POST /rest/v1/rpc/proponer_encuentro → 200; solo manda '
        'la conversación, el lugar y la hora en UTC', () async {
      // ARRANGE
      cuando('POST', '$_rpc/proponer_encuentro', (_) => _json(200, 'enc-9'));

      // ACT
      final SolicitudEncuentro enviada = await EnviarSolicitudEncuentro(repositorio, conRed)(propuesta());

      // ASSERT
      expect(enviada, isA<PropuestaEncuentro>());
      final http.Request p = app().single;
      expect(p.method, 'POST');
      expect(p.url.path, '$_rpc/proponer_encuentro');
      // SEGURIDAD: quién propone sale de la sesión; no se manda.
      expect(cuerpo(p), <String, dynamic>{
        'p_conversacion': idConversacion,
        'p_punto': 'biblioteca',
        'p_fecha_hora': '2026-11-12T19:00:00.000Z',
      });
    });

    test(
        'CP-67 (Escenario 5): un lugar fuera del catálogo no sale del celular; si alguien lo manda '
        'saltándose la app → 400 punto_no_permitido → "Solo se permiten zonas seguras dentro de la UTSJR."',
        () async {
      // ARRANGE
      cuando('POST', '$_rpc/proponer_encuentro', (_) => _json(400, _error('23514', hint: 'punto_no_permitido')));
      const PuntoEncuentro externo = PuntoEncuentro(id: 'plaza-comercial', nombre: 'Plaza comercial', referencia: '');

      // ACT + ASSERT: el creador lo detiene sin petición
      await expectLater(
        EnviarSolicitudEncuentro(repositorio, conRed)(propuesta(punto: externo)),
        throwsA(isA<PuntoNoPermitidoFailure>()),
      );
      expect(app(), isEmpty);

      // ACT + ASSERT: el servidor también lo rechaza
      await expectLater(
        repositorio.enviar(PropuestaEncuentro(conversacionId: idConversacion, puntoId: 'plaza-comercial', fechaHora: jueves13)),
        throwsA(isA<PuntoNoPermitidoFailure>()
            .having((f) => f.mensaje, 'mensaje', 'Solo se permiten zonas seguras dentro de la UTSJR.')
            .having((f) => f.mensaje, 'sin detalles', isNot(contains('10.0.0.8')))),
      );
    });

    test('CP-68 (Escenario 6): un horario no permitido no sale del celular; el servidor → 400 horario_no_permitido',
        () async {
      // ARRANGE
      cuando('POST', '$_rpc/proponer_encuentro', (_) => _json(400, _error('23514', hint: 'horario_no_permitido')));

      // ACT + ASSERT
      await expectLater(
        EnviarSolicitudEncuentro(repositorio, conRed)(propuesta(fechaHora: sabado10)),
        throwsA(isA<HorarioNoPermitidoFailure>()),
      );
      expect(app(), isEmpty);
      await expectLater(
        repositorio.enviar(PropuestaEncuentro(conversacionId: idConversacion, puntoId: 'biblioteca', fechaHora: sabado10)),
        throwsA(isA<HorarioNoPermitidoFailure>().having(
            (f) => f.mensaje, 'mensaje', 'Elige un horario de lunes a viernes, de 7:00 a 20:00, dentro de los próximos 14 días.')),
      );
    });

    test('CP-69 (Escenario 7): proponer con un encuentro activo → 400 encuentro_activo', () async {
      // ARRANGE
      cuando('POST', '$_rpc/proponer_encuentro', (_) => _json(400, _error('23514', hint: 'encuentro_activo')));

      // ACT + ASSERT
      await expectLater(
        EnviarSolicitudEncuentro(repositorio, conRed)(propuesta()),
        throwsA(isA<EncuentroActivoFailure>()),
      );
      expect(app(), hasLength(1));
    });

    test(
        'CP-70 (Escenarios 2 y 3): aceptar y rechazar hacen POST /rest/v1/rpc/responder_encuentro → 204',
        () async {
      // ARRANGE
      cuando('POST', '$_rpc/responder_encuentro', (_) => _vacia());
      final EnviarSolicitudEncuentro enviar = EnviarSolicitudEncuentro(repositorio, conRed);

      // ACT
      await enviar(CreadorRespuesta(encuentro: encuentro(), miId: idComprador, acepta: true, reloj: reloj));
      await enviar(CreadorRespuesta(encuentro: encuentro(), miId: idComprador, acepta: false, reloj: reloj));

      // ASSERT
      expect(app().map(cuerpo), [
        <String, dynamic>{'p_encuentro': 'enc-1', 'p_acepta': true},
        <String, dynamic>{'p_encuentro': 'enc-1', 'p_acepta': false},
      ]);
    });

    test(
        'CP-71 (Escenarios 8 y 9): responder la propia, una vencida o una ya respondida → 400 con '
        'pistas fijas', () async {
      // ARRANGE: una respuesta distinta en cada intento.
      final List<http.Response> rechazos = <http.Response>[
        _json(400, _error('23514', hint: 'encuentro_propio')),
        _json(400, _error('23514', hint: 'encuentro_vencido')),
        _json(400, _error('23514', hint: 'encuentro_no_pendiente')),
      ];
      int i = 0;
      cuando('POST', '$_rpc/responder_encuentro', (_) => rechazos[i++]);
      const RespuestaEncuentro aceptar = RespuestaEncuentro(encuentroId: 'enc-1', acepta: true);

      // ACT + ASSERT
      await expectLater(repositorio.enviar(aceptar), throwsA(isA<EncuentroPropioFailure>()));
      await expectLater(
        repositorio.enviar(aceptar),
        throwsA(isA<EncuentroVencidoFailure>()
            .having((f) => f.mensaje, 'mensaje', 'La hora propuesta ya pasó. Propongan otra.')),
      );
      await expectLater(repositorio.enviar(aceptar), throwsA(isA<EncuentroNoPendienteFailure>()));

      // Y el creador ni siquiera envía la propia (Escenario 8).
      await expectLater(
        EnviarSolicitudEncuentro(repositorio, conRed)(
          CreadorRespuesta(encuentro: encuentro(propuestoPor: idComprador), miId: idComprador, acepta: true, reloj: reloj),
        ),
        throwsA(isA<EncuentroPropioFailure>()),
      );
      expect(app(), hasLength(3));
    });

    test('CP-72 (Escenario 4): cancelar hace POST /rest/v1/rpc/cancelar_encuentro → 204; rechazos con pistas',
        () async {
      // ARRANGE
      final List<http.Response> respuestasCancelar = <http.Response>[
        _vacia(),
        _json(400, _error('23514', hint: 'encuentro_no_activo')),
        _json(400, _error('23514', hint: 'encuentro_propio')),
      ];
      int i = 0;
      cuando('POST', '$_rpc/cancelar_encuentro', (_) => respuestasCancelar[i++]);
      const CancelacionEncuentro cancelar = CancelacionEncuentro(encuentroId: 'enc-1');

      // ACT
      await EnviarSolicitudEncuentro(repositorio, conRed)(
        CreadorCancelacion(encuentro: encuentro(estado: EstadoEncuentro.aceptado), miId: idComprador, reloj: reloj),
      );

      // ASSERT
      expect(cuerpo(app().first), <String, dynamic>{'p_encuentro': 'enc-1'});
      await expectLater(repositorio.enviar(cancelar), throwsA(isA<EncuentroNoActivoFailure>()));
      // Al cancelar, "encuentro_propio" significa que la propuesta es del otro.
      await expectLater(
        repositorio.enviar(cancelar),
        throwsA(isA<CancelarNoPermitidoFailure>()
            .having((f) => f.mensaje, 'mensaje', 'Solo quien hizo la propuesta puede cancelarla. Tú puedes rechazarla.')),
      );
    });

    test('CP-73: las tarjetas hacen POST /rest/v1/rpc/encuentros_conversacion → 200', () async {
      // ARRANGE
      cuando('POST', '$_rpc/encuentros_conversacion', (_) => _json(200, [
            _filaEncuentro('enc-2', estado: 'aceptado', propuestoPor: idComprador),
            _filaEncuentro('enc-1', estado: 'rechazado'),
          ]));

      // ACT
      final List<Encuentro> lista = await ObtenerEncuentros(repositorio, conRed)(idConversacion);

      // ASSERT
      expect(lista.map((e) => e.id), ['enc-2', 'enc-1']);
      expect(lista.first.estado, EstadoEncuentro.aceptado);
      expect(lista.first.propuestoPor, idComprador);
      expect(lista.first.punto.nombre, 'Biblioteca - Entrada Principal');
      expect(lista.first.fechaHora, jueves13);
      expect(cuerpo(app().single), <String, dynamic>{'p_conversacion': idConversacion});
    });

    test(
        'CP-74 (Escenario 11): proponer, responder o cancelar en una conversación ajena → 403 '
        '(42501) → sin permiso; un id inválido también', () async {
      // ARRANGE
      for (final String ruta in <String>[
        '$_rpc/proponer_encuentro',
        '$_rpc/responder_encuentro',
        '$_rpc/cancelar_encuentro',
        '$_rpc/encuentros_conversacion',
      ]) {
        cuando('POST', ruta, (_) => _json(403, _error('42501', message: 'Sin acceso a la conversación')));
      }
      final Matcher sinPermiso = throwsA(isA<ChatSinPermisoFailure>()
          .having((f) => f.mensaje, 'mensaje', 'No tienes acceso a esta conversación.'));

      // ACT + ASSERT
      await expectLater(
        repositorio.enviar(PropuestaEncuentro(conversacionId: 'ajena', puntoId: 'biblioteca', fechaHora: jueves13)),
        sinPermiso,
      );
      await expectLater(repositorio.enviar(const RespuestaEncuentro(encuentroId: 'ajeno', acepta: true)), sinPermiso);
      await expectLater(repositorio.enviar(const CancelacionEncuentro(encuentroId: 'ajeno')), sinPermiso);
      await expectLater(repositorio.obtenerEncuentros('ajena'), sinPermiso);

      cuando('POST', '$_rpc/encuentros_conversacion', (_) => _json(400, _error('22P02')));
      await expectLater(repositorio.obtenerEncuentros('no-es-uuid'), sinPermiso);
    });

    test(
        'CP-75 (Escenarios 10 y 12): conversación cerrada y demasiados mensajes → 400 con el '
        'mensaje del chat', () async {
      // ARRANGE
      final List<http.Response> rechazos = <http.Response>[
        _json(400, _error('23514', hint: 'conversacion_cerrada')),
        _json(400, _error('23514', hint: 'demasiados_mensajes')),
      ];
      int i = 0;
      cuando('POST', '$_rpc/proponer_encuentro', (_) => rechazos[i++]);
      final EnviarSolicitudEncuentro enviar = EnviarSolicitudEncuentro(repositorio, conRed);

      // ACT + ASSERT
      await expectLater(enviar(propuesta()), throwsA(isA<ConversacionCerradaFailure>()));
      await expectLater(
        enviar(propuesta()),
        throwsA(isA<DemasiadosMensajesFailure>()
            .having((f) => f.mensaje, 'mensaje', 'Estás enviando muchos mensajes. Espera un momento.')),
      );
    });

    test(
        'CP-76 (Escenarios 13 y 14): sin conexión no se envía nada; un 500 da el mensaje genérico; '
        'sin sesión no se envía nada', () async {
      // ACT + ASSERT: sin conexión
      await expectLater(ObtenerPuntosEncuentro(repositorio, sinRed)(), throwsA(isA<SinConexionFailure>()));
      await expectLater(ObtenerEncuentros(repositorio, sinRed)(idConversacion), throwsA(isA<SinConexionFailure>()));
      await expectLater(EnviarSolicitudEncuentro(repositorio, sinRed)(propuesta()), throwsA(isA<SinConexionFailure>()));
      expect(app(), isEmpty);

      // ARRANGE: 500
      cuando('GET', _rutaPuntos, (_) => _json(500, _error('XX000')));
      for (final String ruta in <String>[
        '$_rpc/proponer_encuentro',
        '$_rpc/encuentros_conversacion',
      ]) {
        cuando('POST', ruta, (_) => _json(500, _error('XX000')));
      }
      final Matcher generico = throwsA(isA<ChatServidorFailure>()
          .having((f) => f.mensaje, 'mensaje', 'No pudimos completar la acción. Inténtalo de nuevo.')
          .having((f) => f.mensaje, 'sin IP', isNot(contains('10.0.0.8'))));

      // ACT + ASSERT: 500
      await expectLater(repositorio.obtenerPuntos(), generico);
      await expectLater(repositorio.obtenerEncuentros(idConversacion), generico);
      await expectLater(
        repositorio.enviar(PropuestaEncuentro(conversacionId: idConversacion, puntoId: 'biblioteca', fechaHora: jueves13)),
        generico,
      );

      // ACT + ASSERT: sin sesión
      await cliente.auth.signOut();
      final int antes = app().length;
      for (final Future<Object?> Function() llamada in <Future<Object?> Function()>[
        repositorio.obtenerPuntos,
        () => repositorio.obtenerEncuentros(idConversacion),
        () => repositorio.enviar(const CancelacionEncuentro(encuentroId: 'enc-1')),
      ]) {
        await expectLater(llamada(), throwsA(isA<SesionNoIniciadaFailure>()));
      }
      expect(app().length, antes);
    });
  });
}
