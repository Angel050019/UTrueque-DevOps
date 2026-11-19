// Pruebas del API REST de la reputación con el patrón AAA (Sprint 9, HU-09,
// issue #38): CP-77 a CP-88.
//
// Igual que en encuentros_api_rest_test.dart, se ejercita la cadena REAL:
//
//   Caso de uso -> ReputacionRepositoryImpl -> ReputacionRemoteDataSourceImpl
//               -> SupabaseClient -> HTTP
//
// y solo se sustituye la red por un servidor simulado (MockClient).
//
// Ver docs/Plan_de_Pruebas.md (anexo de HU-09) y docs/Sprint9_Planning.md.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/reputacion/data/datasources/reputacion_remote_datasource.dart';
import 'package:utrueque/features/reputacion/data/repositories/reputacion_repository_impl.dart';
import 'package:utrueque/features/reputacion/domain/entities/reputacion.dart';
import 'package:utrueque/features/reputacion/domain/entities/trato.dart';
import 'package:utrueque/features/reputacion/domain/errors/reputacion_failures.dart';
import 'package:utrueque/features/reputacion/domain/usecases/casos_de_uso_reputacion.dart';
import 'package:utrueque/features/reputacion/domain/validators/calificacion_validator.dart';

import '../features/reputacion/fixtures.dart';

const String _urlSupabase = 'https://utrueque-pruebas.supabase.co';
const String _rpc = '/rest/v1/rpc';
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

Map<String, dynamic> _error(String code, {String? hint, String message = 'rechazado en 10.0.0.8 (tabla calificaciones)'}) =>
    <String, dynamic>{'code': code, 'details': null, 'hint': hint, 'message': message};

Map<String, dynamic> _filaTrato({String ventaId = 'venta-1', String vendidaEn = '2026-11-18T18:00:00+00:00'}) =>
    <String, dynamic>{
      'venta_id': ventaId,
      'conversacion_id': idConversacion,
      'publicacion_id': 'pub-1',
      'publicacion_titulo': 'Calculadora Casio fx-991',
      'publicacion_foto': '$idVendedor/1_0.jpg',
      'soy_vendedor': false,
      'otro_id': idVendedor,
      'otro_nombre': 'Ana López',
      'otro_foto_url': null,
      'vendida_en': vendidaEn,
      'vence_en': DateTime.parse(vendidaEn).add(const Duration(days: 14)).toIso8601String(),
    };

Map<String, dynamic> _filaRecibida(String id, String fecha) => <String, dynamic>{
      'id': id,
      'estrellas': 5,
      'comentario': 'Muy puntual.',
      'created_at': fecha,
      'autor_id': idComprador,
      'autor_nombre': 'Beto Ruiz',
      'autor_foto_url': null,
      'publicacion_titulo': 'Calculadora Casio fx-991',
      'como_vendedor': true,
    };

void main() {
  late List<http.Request> peticiones;
  late Map<String, http.Response Function(http.Request)> respuestas;
  late SupabaseClient cliente;
  late ReputacionRepositoryImpl repositorio;
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
    repositorio = ReputacionRepositoryImpl(ReputacionRemoteDataSourceImpl(cliente));
    await cliente.auth.signInWithPassword(email: 'beto.ruiz@utsjr.edu.mx', password: 'x');
  });

  tearDown(() async => cliente.dispose());

  List<http.Request> app() => peticiones.where((p) => !p.url.path.startsWith('/auth/')).toList();
  Map<String, dynamic> cuerpo(http.Request p) => jsonDecode(p.body) as Map<String, dynamic>;
  void cuando(String metodo, String ruta, http.Response Function(http.Request) r) => respuestas['$metodo $ruta'] = r;

  group('API REST de la reputación (HU-09, issue #38) — patrón AAA', () {
    test(
        'CP-77 (Escenario 1): "¿A quién se lo vendiste?" hace POST /rest/v1/rpc/compradores_posibles → 200 '
        'con quienes le escribieron', () async {
      // ARRANGE
      cuando('POST', '$_rpc/compradores_posibles', (_) => _json(200, [
            <String, dynamic>{
              'conversacion_id': idConversacion,
              'comprador_id': idComprador,
              'comprador_nombre': 'Beto Ruiz',
              'comprador_foto_url': null,
              'ultimo_mensaje_en': '2026-11-18T16:00:00+00:00',
            },
          ]));

      // ACT
      final List<CompradorPosible> lista = await ObtenerCompradoresPosibles(repositorio, conRed)('pub-1');

      // ASSERT
      expect(lista.single.nombre, 'Beto Ruiz');
      expect(lista.single.conversacionId, idConversacion);
      final http.Request p = app().single;
      expect(p.method, 'POST');
      expect(cuerpo(p), <String, dynamic>{'p_publicacion': 'pub-1'});
      expect(p.headers['Authorization'], 'Bearer $_tokenAcceso');
    });

    test(
        'CP-78 (Escenarios 1 y 2): marcar Vendido hace POST /rest/v1/rpc/marcar_vendida → 200 con el id '
        'del trato; fuera de UTrueque manda la conversación vacía y regresa null', () async {
      // ARRANGE
      final List<http.Response> r = <http.Response>[_json(200, 'venta-1'), _json(200, null)];
      int i = 0;
      cuando('POST', '$_rpc/marcar_vendida', (_) => r[i++]);
      final MarcarVendida vender = MarcarVendida(repositorio, conRed);

      // ACT
      final ResultadoVenta conTrato = await vender(publicacionDelVendedor(), const EleccionVenta.a(idConversacion));
      final ResultadoVenta fuera = await vender(publicacionDelVendedor(), const EleccionVenta.fueraDeUTrueque());

      // ASSERT
      expect(conTrato.ventaId, 'venta-1');
      expect(conTrato.publicacion.estado, const Vendido());
      expect(fuera.ventaId, isNull);
      // SEGURIDAD: quién vende sale de la sesión; solo se mandan la publicación y la conversación.
      expect(app().map(cuerpo), [
        <String, dynamic>{'p_publicacion': 'pub-1', 'p_conversacion': idConversacion},
        <String, dynamic>{'p_publicacion': 'pub-1', 'p_conversacion': null},
      ]);
    });

    test(
        'CP-79 (Escenario 11): vender a quien no escribió → 400 comprador_no_valido; ya vendida → '
        'transicion_no_permitida; no existe → publicacion_no_encontrada', () async {
      // ARRANGE
      final List<http.Response> r = <http.Response>[
        _json(400, _error('23514', hint: 'comprador_no_valido')),
        _json(400, _error('23514', hint: 'transicion_no_permitida')),
        _json(404, _error('P0002', hint: 'publicacion_no_encontrada')),
      ];
      int i = 0;
      cuando('POST', '$_rpc/marcar_vendida', (_) => r[i++]);

      // ACT + ASSERT
      await expectLater(
        repositorio.marcarVendida('pub-1', conversacionId: 'conv-dani'),
        throwsA(isA<CompradorNoValidoFailure>()
            .having((f) => f.mensaje, 'mensaje', 'Elige a alguien que te escribió por esta publicación.')
            .having((f) => f.mensaje, 'sin detalles', isNot(contains('10.0.0.8')))),
      );
      await expectLater(repositorio.marcarVendida('pub-1'), throwsA(isA<AccionNoPermitidaFailure>()));
      await expectLater(repositorio.marcarVendida('pub-x'), throwsA(isA<PublicacionNoEncontradaFailure>()));

      // Y una publicación Vendida ni siquiera sale del celular (patrón State).
      await expectLater(
        MarcarVendida(repositorio, conRed)(
          publicacionDelVendedor(estado: const Vendido()),
          const EleccionVenta.fueraDeUTrueque(),
        ),
        throwsA(isA<TransicionNoPermitidaFailure>()),
      );
      expect(app(), hasLength(3));
    });

    test('CP-80 (Escenario 3): tratos por calificar hace POST /rest/v1/rpc/tratos_por_calificar → 200', () async {
      // ARRANGE
      cuando('POST', '$_rpc/tratos_por_calificar', (_) => _json(200, [_filaTrato()]));

      // ACT
      final List<TratoPorCalificar> tratos = await ObtenerTratosPorCalificar(repositorio, conRed)();

      // ASSERT
      final TratoPorCalificar t = tratos.single;
      expect(t.ventaId, 'venta-1');
      expect(t.invitacion, 'Califica tu trato con Ana López');
      expect(t.publicacionFotoUrl, allOf(startsWith(_urlSupabase), endsWith('$idVendedor/1_0.jpg')));
      expect(t.venceEn, DateTime.utc(2026, 12, 2, 18));
      expect(cuerpo(app().single), <String, dynamic>{});
    });

    test(
        'CP-81 (Escenarios 3 y 4): calificar hace POST /rest/v1/rpc/calificar → 200; manda la venta, las '
        'estrellas y el comentario limpio, NUNCA a quién se califica', () async {
      // ARRANGE
      cuando('POST', '$_rpc/calificar', (_) => _json(200, 'cal-1'));
      final Calificar calificar = Calificar(repositorio, conRed, reloj: relojRep);

      // ACT
      await calificar(trato(), estrellas: 5, comentario: '  Muy puntual.  ');
      await calificar(trato(soyVendedor: true), estrellas: 4, comentario: '');

      // ASSERT
      expect(app().map(cuerpo), [
        <String, dynamic>{'p_venta': 'venta-1', 'p_estrellas': 5, 'p_comentario': 'Muy puntual.'},
        <String, dynamic>{'p_venta': 'venta-1', 'p_estrellas': 4, 'p_comentario': null},
      ]);
      for (final http.Request p in app()) {
        expect(cuerpo(p).keys, isNot(contains('p_calificado')));
      }
    });

    test(
        'CP-82 (Escenarios 6 a 8): la reputación hace POST /rest/v1/rpc/reputacion_usuario → 200 con '
        'los conteos; la app calcula el promedio (Strategy)', () async {
      // ARRANGE
      final List<http.Response> r = <http.Response>[
        _json(200, [
          <String, dynamic>{'usuario_id': idVendedor, 'total': 1, 'una': 0, 'dos': 0, 'tres': 0, 'cuatro': 0, 'cinco': 1},
        ]),
        _json(200, [
          <String, dynamic>{'usuario_id': idVendedor, 'total': 5, 'una': 0, 'dos': 0, 'tres': 0, 'cuatro': 2, 'cinco': 3},
        ]),
        _json(200, [
          <String, dynamic>{'usuario_id': idVendedor, 'total': 0, 'una': 0, 'dos': 0, 'tres': 0, 'cuatro': 0, 'cinco': 0},
        ]),
        _json(200, <Object>[]),
      ];
      int i = 0;
      cuando('POST', '$_rpc/reputacion_usuario', (_) => r[i++]);
      final ObtenerReputacion obtener = ObtenerReputacion(repositorio, conRed);

      // ACT
      final Reputacion una = await obtener(idVendedor);
      final Reputacion cinco = await obtener(idVendedor);
      final Reputacion nueva = await obtener(idVendedor);
      final Reputacion vacia = await obtener(idVendedor);

      // ASSERT
      expect(una.texto, '4.3 · 1 calificación');
      expect(una.ajustada, isTrue);
      expect(cinco.texto, '4.6 · 5 calificaciones');
      expect(nueva.texto, 'Nuevo en UTrueque · Sin calificaciones aún');
      expect(vacia.sinCalificaciones, isTrue);
      expect(cuerpo(app().first), <String, dynamic>{'p_usuario': idVendedor});
    });

    test(
        'CP-83 (Escenario 5): calificaciones recibidas hace POST /rest/v1/rpc/calificaciones_recibidas → '
        '200; pide una de más para saber si hay otra página y la siguiente usa el cursor', () async {
      // ARRANGE
      final List<http.Response> r = <http.Response>[
        _json(200, [
          _filaRecibida('c1', '2026-11-19T17:00:00+00:00'),
          _filaRecibida('c2', '2026-11-19T16:00:00+00:00'),
          _filaRecibida('c3', '2026-11-19T15:00:00+00:00'),
        ]),
        _json(200, [_filaRecibida('c3', '2026-11-19T15:00:00+00:00')]),
      ];
      int i = 0;
      cuando('POST', '$_rpc/calificaciones_recibidas', (_) => r[i++]);

      // ACT
      final PaginaCalificaciones p1 = await repositorio.recibidas(limite: 2);
      final PaginaCalificaciones p2 = await repositorio.recibidas(despuesDe: p1.calificaciones.last, limite: 2);

      // ASSERT
      expect(p1.calificaciones.map((c) => c.id), ['c1', 'c2']);
      expect(p1.hayMas, isTrue);
      expect(p2.calificaciones.map((c) => c.id), ['c3']);
      expect(p2.hayMas, isFalse);
      expect(cuerpo(app().first), <String, dynamic>{'p_antes_de': null, 'p_antes_id': null, 'p_limite': 3});
      expect(cuerpo(app().last), <String, dynamic>{
        'p_antes_de': '2026-11-19T16:00:00.000Z',
        'p_antes_id': 'c2',
        'p_limite': 3,
      });
    });

    test('CP-84 (Escenario 9): calificar dos veces → 400 calificacion_duplicada → "Ya calificaste este trato."',
        () async {
      // ARRANGE
      cuando('POST', '$_rpc/calificar', (_) => _json(400, _error('23514', hint: 'calificacion_duplicada')));

      // ACT + ASSERT
      await expectLater(
        Calificar(repositorio, conRed, reloj: relojRep)(trato(), estrellas: 1),
        throwsA(isA<CalificacionDuplicadaFailure>().having((f) => f.mensaje, 'mensaje', 'Ya calificaste este trato.')),
      );
    });

    test(
        'CP-85 (Escenario 10): pasados 14 días no sale del celular; si alguien lo manda → 400 plazo_vencido',
        () async {
      // ARRANGE
      cuando('POST', '$_rpc/calificar', (_) => _json(400, _error('23514', hint: 'plazo_vencido')));

      // ACT + ASSERT: el caso de uso lo detiene
      await expectLater(
        Calificar(repositorio, conRed, reloj: relojRep)(trato(diasDesdeVenta: 15), estrellas: 5),
        throwsA(isA<PlazoVencidoFailure>()),
      );
      expect(app(), isEmpty);

      // ACT + ASSERT: el servidor también
      await expectLater(
        repositorio.calificar(ventaId: 'venta-vieja', estrellas: 5),
        throwsA(isA<PlazoVencidoFailure>()
            .having((f) => f.mensaje, 'mensaje', 'Ya pasaron los 14 días para calificar este trato.')),
      );
    });

    test(
        'CP-86 (Escenario 11): calificar un trato ajeno, vender una publicación ajena o pedir con un id '
        'inválido → 403 (42501) / 22P02 → sin permiso', () async {
      // ARRANGE
      cuando('POST', '$_rpc/calificar', (_) => _json(403, _error('42501', message: 'Sin acceso al trato')));
      cuando('POST', '$_rpc/marcar_vendida', (_) => _json(403, _error('42501', message: 'Sin acceso a la publicación')));
      cuando('POST', '$_rpc/reputacion_usuario', (_) => _json(400, _error('22P02')));
      final Matcher sinPermiso = throwsA(isA<ReputacionSinPermisoFailure>()
          .having((f) => f.mensaje, 'mensaje', 'No tienes acceso a este trato.'));

      // ACT + ASSERT
      await expectLater(repositorio.calificar(ventaId: 'ajena', estrellas: 5), sinPermiso);
      await expectLater(repositorio.marcarVendida('ajena', conversacionId: idConversacion), sinPermiso);
      await expectLater(repositorio.resumen('no-es-uuid'), sinPermiso);
    });

    test(
        'CP-87 (Escenario 12): un comentario no válido no sale del celular; el servidor también lo '
        'rechaza (caracteres, largo y estrellas)', () async {
      // ARRANGE
      final List<http.Response> r = <http.Response>[
        _json(400, _error('23514', hint: 'comentario_caracteres')),
        _json(400, _error('23514', hint: 'comentario_largo')),
        _json(400, _error('23514', hint: 'estrellas_invalidas')),
      ];
      int i = 0;
      cuando('POST', '$_rpc/calificar', (_) => r[i++]);

      // ACT + ASSERT: el caso de uso lo detiene
      await expectLater(
        Calificar(repositorio, conRed, reloj: relojRep)(trato(), estrellas: 5, comentario: '<script>'),
        throwsA(isA<CalificacionInvalidaFailure>()),
      );
      await expectLater(
        Calificar(repositorio, conRed, reloj: relojRep)(trato(), estrellas: 0),
        throwsA(isA<CalificacionInvalidaFailure>()),
      );
      expect(app(), isEmpty);

      // ACT + ASSERT: el servidor
      await expectLater(
        repositorio.calificar(ventaId: 'venta-1', estrellas: 5, comentario: '<script>'),
        throwsA(isA<CalificacionInvalidaFailure>()
            .having((f) => f.mensaje, 'mensaje', CalificacionValidator.mensajeCaracteres)),
      );
      await expectLater(
        repositorio.calificar(ventaId: 'venta-1', estrellas: 5, comentario: 'a' * 300),
        throwsA(isA<CalificacionInvalidaFailure>().having((f) => f.mensaje, 'mensaje', CalificacionValidator.mensajeLargo)),
      );
      await expectLater(
        repositorio.calificar(ventaId: 'venta-1', estrellas: 9),
        throwsA(isA<CalificacionInvalidaFailure>()
            .having((f) => f.mensaje, 'mensaje', CalificacionValidator.mensajeEstrellas)),
      );
    });

    test(
        'CP-88 (Escenarios 13 y 14): sin conexión no se envía nada; un 500 da el mensaje genérico; '
        'sin sesión no se envía nada', () async {
      // ACT + ASSERT: sin conexión
      await expectLater(ObtenerCompradoresPosibles(repositorio, sinRed)('pub-1'), throwsA(isA<SinConexionFailure>()));
      await expectLater(
        MarcarVendida(repositorio, sinRed)(publicacionDelVendedor(), const EleccionVenta.fueraDeUTrueque()),
        throwsA(isA<SinConexionFailure>()),
      );
      await expectLater(ObtenerTratosPorCalificar(repositorio, sinRed)(), throwsA(isA<SinConexionFailure>()));
      await expectLater(
        Calificar(repositorio, sinRed, reloj: relojRep)(trato(), estrellas: 5),
        throwsA(isA<SinConexionFailure>()),
      );
      await expectLater(ObtenerReputacion(repositorio, sinRed)(idVendedor), throwsA(isA<SinConexionFailure>()));
      await expectLater(ObtenerCalificacionesRecibidas(repositorio, sinRed)(), throwsA(isA<SinConexionFailure>()));
      expect(app(), isEmpty);

      // ARRANGE: 500
      for (final String f in <String>[
        'compradores_posibles',
        'marcar_vendida',
        'tratos_por_calificar',
        'calificar',
        'reputacion_usuario',
        'calificaciones_recibidas',
      ]) {
        cuando('POST', '$_rpc/$f', (_) => _json(500, _error('XX000')));
      }
      final Matcher generico = throwsA(isA<ReputacionServidorFailure>()
          .having((f) => f.mensaje, 'mensaje', 'No pudimos completar la acción. Inténtalo de nuevo.')
          .having((f) => f.mensaje, 'sin IP', isNot(contains('10.0.0.8'))));

      // ACT + ASSERT: 500
      await expectLater(repositorio.compradoresPosibles('pub-1'), generico);
      await expectLater(repositorio.marcarVendida('pub-1'), generico);
      await expectLater(repositorio.tratosPorCalificar(), generico);
      await expectLater(repositorio.calificar(ventaId: 'venta-1', estrellas: 5), generico);
      await expectLater(repositorio.resumen(idVendedor), generico);
      await expectLater(repositorio.recibidas(), generico);

      // ACT + ASSERT: sin sesión
      await cliente.auth.signOut();
      final int antes = app().length;
      for (final Future<Object?> Function() llamada in <Future<Object?> Function()>[
        () => repositorio.compradoresPosibles('pub-1'),
        () => repositorio.marcarVendida('pub-1'),
        repositorio.tratosPorCalificar,
        () => repositorio.calificar(ventaId: 'venta-1', estrellas: 5),
        () => repositorio.resumen(idVendedor),
        () => repositorio.recibidas(),
      ]) {
        await expectLater(llamada(), throwsA(isA<SesionNoIniciadaFailure>()));
      }
      expect(app().length, antes);
    });
  });
}
