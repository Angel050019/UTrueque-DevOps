// Pruebas del API REST del chat con el patrón AAA (Sprint 7, HU-07, issue #2):
// CP-53 a CP-64.
//
// Igual que en publicaciones_api_rest_test.dart, se ejercita la cadena REAL:
//
//   Caso de uso -> ChatRepositoryImpl -> ChatRemoteDataSourceImpl
//               -> SupabaseClient -> HTTP
//
// y solo se sustituye la red por un servidor simulado (MockClient). El
// WebSocket de Supabase Realtime se sustituye por un StreamController (no se
// puede abrir en el CI).
//
// Ver docs/Plan_de_Pruebas.md (anexo de HU-07) y docs/Sprint7_Planning.md.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:utrueque/features/chat/data/datasources/mensajes_tiempo_real.dart';
import 'package:utrueque/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:utrueque/features/chat/domain/entities/aviso_chat.dart';
import 'package:utrueque/features/chat/domain/entities/conversacion.dart';
import 'package:utrueque/features/chat/domain/entities/mensaje.dart';
import 'package:utrueque/features/chat/domain/entities/pagina_mensajes.dart';
import 'package:utrueque/features/chat/domain/errors/chat_failures.dart';
import 'package:utrueque/features/chat/domain/usecases/enviar_mensaje.dart';
import 'package:utrueque/features/chat/domain/usecases/escuchar_chat.dart';
import 'package:utrueque/features/chat/domain/usecases/iniciar_conversacion.dart';
import 'package:utrueque/features/chat/domain/usecases/marcar_conversacion_leida.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_conversaciones.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_mensajes.dart';
import 'package:utrueque/features/chat/domain/usecases/obtener_total_no_leidos.dart';
import 'package:utrueque/features/chat/domain/validators/mensaje_validator.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';

import '../features/chat/fixtures.dart';

const String _urlSupabase = 'https://utrueque-pruebas.supabase.co';
const String _rpc = '/rest/v1/rpc';
const String _rutaMensajes = '/rest/v1/mensajes';
const String _tokenAcceso = 'token-de-acceso-de-pruebas';

class _RedSimulada implements NetworkInfo {
  _RedSimulada({required this.conectado});

  final bool conectado;

  @override
  Future<bool> get estaConectado async => conectado;
}

/// El WebSocket de Supabase Realtime, simulado.
class _TiempoRealSimulado implements MensajesEnTiempoReal {
  final StreamController<EventoTiempoReal> controlador = StreamController<EventoTiempoReal>.broadcast();

  @override
  Stream<EventoTiempoReal> eventos() => controlador.stream;
}

http.Response _json(int codigo, Object? cuerpo) => http.Response(
      jsonEncode(cuerpo),
      codigo,
      headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
    );

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

Map<String, dynamic> _filaMensaje(String id, {String autor = idVendedor, String texto = 'Hola', int segundo = 0}) =>
    <String, dynamic>{
      'id': id,
      'conversacion_id': idConversacion,
      'autor_id': autor,
      'texto': texto,
      'created_at': '2026-11-06T16:00:${segundo.toString().padLeft(2, '0')}.123456+00:00',
    };

Map<String, dynamic> _filaConversacion(String id, {int noLeidos = 0, String? estado = 'disponible'}) =>
    <String, dynamic>{
      'id': id,
      'publicacion_id': estado == null ? null : 'pub-1',
      'publicacion_titulo': estado == null ? null : 'Calculadora Casio fx-991',
      'publicacion_foto': estado == null ? null : '$idVendedor/1_0.jpg',
      'publicacion_estado': estado,
      'soy_vendedor': false,
      'otro_id': idVendedor,
      'otro_nombre': 'Ana López',
      'otro_foto_url': 'https://avatars/ana.jpg',
      'ultimo_texto': 'Sí, ahí nos vemos.',
      'ultimo_autor_id': idVendedor,
      'ultimo_mensaje_en': '2026-11-06T16:05:00+00:00',
      'no_leidos': noLeidos,
      'created_at': '2026-11-06T16:00:00+00:00',
    };

Map<String, dynamic> _error(String code, {String? hint, String message = 'rechazado en 10.0.0.8 (tabla mensajes)'}) =>
    <String, dynamic>{'code': code, 'details': null, 'hint': hint, 'message': message};

void main() {
  late List<http.Request> peticiones;
  late Map<String, http.Response Function(http.Request)> respuestas;
  late SupabaseClient cliente;
  late _TiempoRealSimulado tiempoReal;
  late ChatRepositoryImpl repositorio;
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
    tiempoReal = _TiempoRealSimulado();
    repositorio = ChatRepositoryImpl(ChatRemoteDataSourceImpl(cliente, tiempoReal: tiempoReal));
    await cliente.auth.signInWithPassword(email: 'beto.ruiz@utsjr.edu.mx', password: 'x');
  });

  tearDown(() async {
    await tiempoReal.controlador.close();
    await cliente.dispose();
  });

  List<http.Request> app() => peticiones.where((p) => !p.url.path.startsWith('/auth/')).toList();
  Map<String, dynamic> cuerpo(http.Request p) => jsonDecode(p.body) as Map<String, dynamic>;
  void cuando(String metodo, String ruta, http.Response Function(http.Request) r) => respuestas['$metodo $ruta'] = r;

  group('API REST del chat (HU-07, issue #2) — patrón AAA', () {
    test(
        'CP-53 (Escenario 1): "Contactar al vendedor" hace POST /rest/v1/rpc/iniciar_conversacion '
        '→ 200 con el id; solo manda la publicación', () async {
      // ARRANGE
      cuando('POST', '$_rpc/iniciar_conversacion', (_) => _json(200, 'conv-9'));

      // ACT
      final Conversacion c = await IniciarConversacion(repositorio, conRed)(publicacionDelVendedor(), miId: idComprador);

      // ASSERT: respuesta interpretada
      expect(c.id, 'conv-9');
      expect(c.otroNombre, 'Ana López');
      expect(c.publicacionTitulo, 'Calculadora Casio fx-991');

      // ASSERT: petición. SEGURIDAD: quién escribe sale de la sesión.
      final http.Request p = app().single;
      expect(p.method, 'POST');
      expect(p.url.path, '$_rpc/iniciar_conversacion');
      expect(cuerpo(p), <String, dynamic>{'p_publicacion': 'pub-1'});
      expect(p.headers['Authorization'], 'Bearer $_tokenAcceso');
    });

    test(
        'CP-54 (Escenarios 4, 5 y 6): el servidor rechaza iniciar con pistas fijas y la app '
        'muestra el motivo sin detalles internos', () async {
      // ARRANGE: una respuesta distinta en cada intento.
      final List<http.Response> rechazos = <http.Response>[
        _json(400, _error('23514', hint: 'perfil_incompleto')),
        _json(400, _error('23514', hint: 'publicacion_no_disponible')),
        _json(400, _error('23514', hint: 'publicacion_propia')),
        _json(404, _error('P0002', hint: 'publicacion_no_encontrada')),
        _json(400, _error('22P02')),
      ];
      int i = 0;
      cuando('POST', '$_rpc/iniciar_conversacion', (_) => rechazos[i++]);

      // ACT + ASSERT
      for (final Matcher esperado in <Matcher>[
        throwsA(isA<PerfilIncompletoChatFailure>()
            .having((f) => f.mensaje, 'mensaje', 'Completa tu perfil para poder contactar al vendedor.')),
        throwsA(isA<PublicacionNoDisponibleFailure>()),
        throwsA(isA<PublicacionPropiaFailure>()),
        throwsA(isA<PublicacionNoEncontradaFailure>()),
        throwsA(isA<PublicacionNoEncontradaFailure>()),
      ]) {
        await expectLater(repositorio.iniciarConversacion('pub-1'), esperado);
      }
      expect(app(), hasLength(5));
    });

    test('CP-55 (Escenario 7): la bandeja hace POST /rest/v1/rpc/mis_conversaciones → 200', () async {
      // ARRANGE
      cuando('POST', '$_rpc/mis_conversaciones',
          (_) => _json(200, [_filaConversacion('c1', noLeidos: 2), _filaConversacion('c2', estado: null)]));

      // ACT
      final List<Conversacion> lista = await ObtenerConversaciones(repositorio, conRed)();

      // ASSERT
      expect(lista.map((c) => c.id), ['c1', 'c2']);
      expect(lista.first.noLeidos, 2);
      expect(lista.first.publicacionFotoUrl, contains('/publicaciones/$idVendedor/1_0.jpg'));
      expect(lista.first.publicacionEstado, const Disponible());
      expect(lista.last.tituloVisible, 'Publicación eliminada');
      expect(cuerpo(app().single), <String, dynamic>{'p_limite': 50});
    });

    test('CP-56 (Escenarios 2 y 9): mensajes de 30 en 30 con cursor', () async {
      // ARRANGE: 30 en la primera página y 2 en la segunda.
      int pedidas = 0;
      cuando('POST', '$_rpc/mensajes_conversacion', (_) {
        final int n = ++pedidas == 1 ? 30 : 2;
        return _json(200, [for (int i = 0; i < n; i++) _filaMensaje('m${pedidas}_$i', segundo: 59 - i)]);
      });
      final ObtenerMensajes obtener = ObtenerMensajes(repositorio, conRed);

      // ACT
      final PaginaMensajes primera = await obtener(idConversacion);
      final PaginaMensajes segunda = await obtener(idConversacion, antesDe: primera.siguiente);

      // ASSERT
      expect(primera.mensajes, hasLength(30));
      expect(primera.hayAnteriores, isTrue);
      expect(segunda.hayAnteriores, isFalse);
      expect(cuerpo(app().first), <String, dynamic>{'p_conversacion': idConversacion, 'p_limite': 30});
      expect(cuerpo(app().last), <String, dynamic>{
        'p_conversacion': idConversacion,
        'p_limite': 30,
        'p_antes_de': '2026-11-06T16:00:30.123456+00:00',
        'p_antes_id': 'm1_29',
      });
    });

    test(
        'CP-57 (Escenario 3): enviar hace POST /rest/v1/mensajes → 201 solo con la conversación '
        'y el texto, y el mensaje también llega por el tiempo real', () async {
      // ARRANGE
      cuando('POST', _rutaMensajes,
          (p) => _json(201, _filaMensaje('m1', autor: idComprador, texto: cuerpo(p)['texto'] as String)));
      final Future<AvisoChat> llegada = EscucharChat(repositorio)().first;

      // ACT
      final Mensaje m = await EnviarMensaje(repositorio, conRed)(conversacion(), '  ¿Sigue disponible?  ');
      tiempoReal.controlador.add(EventoTiempoReal.registro(_filaMensaje('m1', autor: idComprador, texto: '¿Sigue disponible?')));

      // ASSERT: respuesta
      expect(m.id, 'm1');
      expect(m.texto, '¿Sigue disponible?');
      expect(m.esDe(idComprador), isTrue);

      // ASSERT: petición. SEGURIDAD: no se manda el autor.
      final http.Request p = app().single;
      expect(p.method, 'POST');
      expect(cuerpo(p), <String, dynamic>{'conversacion_id': idConversacion, 'texto': '¿Sigue disponible?'});
      expect(p.url.queryParameters['select'], contains('autor_id'));
      expect(p.headers['Authorization'], 'Bearer $_tokenAcceso');

      // ASSERT: tiempo real (patrón Observer)
      expect(await llegada, isA<MensajeRecibido>().having((a) => a.mensaje.id, 'id', 'm1'));
    });

    test(
        'CP-58 (Escenario 10): un mensaje con caracteres no permitidos no se envía; si alguien '
        'salta la app, el servidor lo rechaza (pista mensaje_caracteres o longitud)', () async {
      // ARRANGE
      int intentos = 0;
      cuando('POST', _rutaMensajes, (_) => ++intentos == 1
          ? _json(400, _error('23514', hint: 'mensaje_caracteres'))
          : _json(400, _error('23514')));

      // ACT + ASSERT: la app no envía nada
      await expectLater(
        EnviarMensaje(repositorio, conRed)(conversacion(), '<script>alert(1)</script>'),
        throwsA(const MensajeInvalidoFailure(MensajeValidator.mensajeCaracteres)),
      );
      expect(app(), isEmpty);

      // ACT + ASSERT: el servidor también lo rechaza
      await expectLater(
        repositorio.enviarMensaje(idConversacion, "hola'; drop table mensajes --"),
        throwsA(const MensajeInvalidoFailure(MensajeValidator.mensajeCaracteres)),
      );
      await expectLater(
        repositorio.enviarMensaje(idConversacion, 'a' * 501),
        throwsA(const MensajeInvalidoFailure(MensajeValidator.mensajeLongitud)),
      );
    });

    test('CP-59 (Escenario 8): marcar como leída hace POST /rest/v1/rpc/marcar_conversacion_leida → 204', () async {
      // ARRANGE
      cuando('POST', '$_rpc/marcar_conversacion_leida', (_) => http.Response('', 204));

      // ACT
      final bool marcada = await MarcarConversacionLeida(repositorio, conRed)(idConversacion);

      // ASSERT
      expect(marcada, isTrue);
      expect(cuerpo(app().single), <String, dynamic>{'p_conversacion': idConversacion});
    });

    test('CP-60 (Escenario 8): el globo hace POST /rest/v1/rpc/total_no_leidos → 200', () async {
      // ARRANGE
      cuando('POST', '$_rpc/total_no_leidos', (_) => _json(200, 3));

      // ACT + ASSERT
      expect(await ObtenerTotalNoLeidos(repositorio, conRed)(), 3);
      expect(app().single.url.path, '$_rpc/total_no_leidos');
    });

    test(
        'CP-61 (Escenarios 11 y 13): una conversación cerrada y el límite contra el spam '
        'responden 400 con su pista', () async {
      // ARRANGE
      int intentos = 0;
      cuando('POST', _rutaMensajes, (_) => ++intentos == 1
          ? _json(400, _error('23514', hint: 'conversacion_cerrada'))
          : _json(400, _error('23514', hint: 'demasiados_mensajes')));

      // ACT + ASSERT
      await expectLater(repositorio.enviarMensaje(idConversacion, 'Hola'), throwsA(isA<ConversacionCerradaFailure>()));
      await expectLater(
        repositorio.enviarMensaje(idConversacion, 'Hola'),
        throwsA(isA<DemasiadosMensajesFailure>()
            .having((f) => f.mensaje, 'mensaje', 'Estás enviando muchos mensajes. Espera un momento.')),
      );
    });

    test('CP-62 (Escenario 12): escribir en una conversación ajena → 403 de RLS → sin permiso', () async {
      // ARRANGE
      cuando('POST', _rutaMensajes, (_) => _json(403, _error('42501',
          message: 'new row violates row-level security policy for table "mensajes"')));
      cuando('POST', '$_rpc/mensajes_conversacion', (_) => _json(400, _error('22P02')));

      // ACT + ASSERT
      await expectLater(
        repositorio.enviarMensaje('ajena', 'Hola'),
        throwsA(isA<ChatSinPermisoFailure>()
            .having((f) => f.mensaje, 'mensaje', 'No tienes acceso a esta conversación.')
            .having((f) => f.mensaje, 'sin detalles', isNot(contains('row-level')))),
      );
      await expectLater(
        repositorio.obtenerMensajes('no-es-uuid', limite: 30),
        throwsA(isA<ChatSinPermisoFailure>()),
      );
    });

    test('CP-63 (Escenario 14): sin conexión no se envía ninguna petición', () async {
      // ACT + ASSERT
      await expectLater(
        IniciarConversacion(repositorio, sinRed)(publicacionDelVendedor(), miId: idComprador),
        throwsA(isA<SinConexionFailure>()),
      );
      await expectLater(ObtenerConversaciones(repositorio, sinRed)(), throwsA(isA<SinConexionFailure>()));
      await expectLater(ObtenerMensajes(repositorio, sinRed)(idConversacion), throwsA(isA<SinConexionFailure>()));
      await expectLater(EnviarMensaje(repositorio, sinRed)(conversacion(), 'Hola'), throwsA(isA<SinConexionFailure>()));
      expect(await MarcarConversacionLeida(repositorio, sinRed)(idConversacion), isFalse);
      expect(await ObtenerTotalNoLeidos(repositorio, sinRed)(), isNull);
      expect(app(), isEmpty);
    });

    test(
        'CP-64 (Escenario 15): un 500 da el mensaje genérico sin detalles; sin sesión no se '
        'envía ninguna petición', () async {
      // ARRANGE
      for (final String ruta in <String>[
        '$_rpc/mis_conversaciones',
        '$_rpc/mensajes_conversacion',
        '$_rpc/marcar_conversacion_leida',
        '$_rpc/total_no_leidos',
        _rutaMensajes,
      ]) {
        cuando('POST', ruta, (_) => _json(500, _error('XX000')));
      }
      final Matcher generico = throwsA(isA<ChatServidorFailure>()
          .having((f) => f.mensaje, 'mensaje', 'No pudimos completar la acción. Inténtalo de nuevo.')
          .having((f) => f.mensaje, 'sin IP', isNot(contains('10.0.0.8'))));

      // ACT + ASSERT: 500
      await expectLater(repositorio.obtenerConversaciones(), generico);
      await expectLater(repositorio.obtenerMensajes(idConversacion, limite: 30), generico);
      await expectLater(repositorio.marcarLeida(idConversacion), generico);
      await expectLater(repositorio.totalNoLeidos(), generico);
      await expectLater(repositorio.enviarMensaje(idConversacion, 'Hola'), generico);

      // ACT + ASSERT: sin sesión
      await cliente.auth.signOut();
      final int antes = app().length;
      for (final Future<Object?> Function() llamada in <Future<Object?> Function()>[
        () => repositorio.iniciarConversacion('pub-1'),
        repositorio.obtenerConversaciones,
        () => repositorio.obtenerMensajes(idConversacion, limite: 30),
        () => repositorio.enviarMensaje(idConversacion, 'Hola'),
        () => repositorio.marcarLeida(idConversacion),
        repositorio.totalNoLeidos,
      ]) {
        await expectLater(llamada(), throwsA(isA<SesionNoIniciadaFailure>()));
      }
      expect(app().length, antes);
    });
  });
}
