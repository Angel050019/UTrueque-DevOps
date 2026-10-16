// Pruebas del API REST de publicaciones (HU-03, issue #4) con el patrón AAA.
//
// Igual que en auth_api_rest_test.dart, se ejercita la cadena REAL de la app:
//
//   Caso de uso -> PublicacionRepositoryImpl -> PublicacionRemoteDataSourceImpl
//               -> SupabaseClient -> HTTP
//
// y solo se sustituye la red por un servidor simulado (MockClient de
// `package:http`). Se valida qué peticiones envía la app a PostgREST
// (`/rest/v1/...`) y a Storage (`/storage/v1/object/...`) y cómo interpreta
// cada respuesta (200, 201, 400, 403, 413 y sin red).
//
// HU-04 (Feed de publicaciones) agrega CP-18 a CP-27: el Feed paginado con
// la función `feed_publicaciones` (POST /rest/v1/rpc/...) y el Detalle con
// la vista `publicaciones_detalle` (GET /rest/v1/publicaciones_detalle).
//
// Ver docs/Plan_de_Pruebas.md, Sección 2, docs/Sprint3_Planning.md y
// docs/Sprint4_Planning.md.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/publicaciones/data/datasources/publicacion_remote_datasource.dart';
import 'package:utrueque/features/publicaciones/data/repositories/publicacion_repository_impl.dart';
import 'package:utrueque/features/publicaciones/domain/entities/categoria.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/crear_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_categorias.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_detalle_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/obtener_feed.dart';

import '../features/publicaciones/fixtures.dart';

const String _urlSupabase = 'https://utrueque-pruebas.supabase.co';
const String _anonKey = 'anon-key-de-pruebas';
const String _tokenAcceso = 'token-de-acceso-de-pruebas';

const String _rutaStorage = '/storage/v1/object/publicaciones';
const String _rutaPublicaciones = '/rest/v1/publicaciones';

// HU-04
const String _rutaFeed = '/rest/v1/rpc/feed_publicaciones';
const String _rutaDetalle = '/rest/v1/publicaciones_detalle';

/// Servidor HTTP simulado que imita las respuestas de Supabase y guarda cada
/// petición recibida para revisarla en el ASSERT. Las rutas se buscan por
/// prefijo porque el nombre de cada foto cambia.
class _ApiSupabaseSimulada {
  final List<http.Request> peticiones = <http.Request>[];
  final List<MapEntry<String, http.Response Function(http.Request)>> _rutas =
      <MapEntry<String, http.Response Function(http.Request)>>[];

  late final MockClient cliente = MockClient((http.Request peticion) async {
    peticiones.add(peticion);
    final String llave = '${peticion.method} ${peticion.url.path}';
    http.Response respuesta = _json(404, <String, dynamic>{'message': 'Ruta no simulada: $llave'});
    for (final MapEntry<String, http.Response Function(http.Request)> ruta in _rutas) {
      if (llave.startsWith(ruta.key)) {
        respuesta = ruta.value(peticion);
        break;
      }
    }
    // postgrest lee `response.request`: la respuesta va ligada a su petición.
    return http.Response.bytes(
      respuesta.bodyBytes,
      respuesta.statusCode,
      headers: respuesta.headers,
      request: peticion,
    );
  });

  void cuando(String metodo, String ruta, http.Response Function(http.Request) responder) {
    _rutas.add(MapEntry<String, http.Response Function(http.Request)>('$metodo $ruta', responder));
  }

  /// Peticiones de la app a la API, sin contar el inicio de sesión.
  List<http.Request> get peticionesDeLaApp =>
      peticiones.where((p) => !p.url.path.startsWith('/auth/')).toList();
}

class _RedSimulada implements NetworkInfo {
  _RedSimulada({required this.conectado});

  final bool conectado;

  @override
  Future<bool> get estaConectado async => conectado;
}

http.Response _json(int codigo, Object cuerpo) {
  return http.Response(
    jsonEncode(cuerpo),
    codigo,
    headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
  );
}

Map<String, dynamic> _sesionJson() {
  return <String, dynamic>{
    'access_token': _tokenAcceso,
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh-token-de-pruebas',
    'user': <String, dynamic>{
      'id': idAlumno,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'ana.lopez@utsjr.edu.mx',
      'email_confirmed_at': '2026-09-20T10:00:00Z',
      'app_metadata': <String, dynamic>{'provider': 'email'},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-09-20T10:00:00Z',
    },
  };
}

/// Fila que devuelve PostgREST al crear la publicación (lo pone el servidor:
/// id, usuario_id, estado y created_at).
Map<String, dynamic> _filaCreada(Map<String, dynamic> enviado) {
  return <String, dynamic>{
    'id': '5b0d0000-0000-4000-8000-0000000000aa',
    'usuario_id': idAlumno,
    'estado': 'disponible',
    'created_at': '2026-10-07T18:00:00Z',
    ...enviado,
  };
}

Map<String, dynamic> _cuerpoJson(http.Request peticion) =>
    jsonDecode(peticion.body) as Map<String, dynamic>;

/// HU-04: fila de la vista `publicaciones_detalle` (la misma forma que
/// regresa la función `feed_publicaciones`).
Map<String, dynamic> _filaVista(String id, {String fecha = '2026-10-13T18:00:00.123456+00:00'}) {
  return <String, dynamic>{
    'id': id,
    'usuario_id': idAlumno,
    'titulo': tituloValido,
    'descripcion': descripcionValida,
    'categoria_id': 2,
    'categoria_nombre': 'Calculadoras',
    'modalidad': 'venta',
    'precio': 150,
    'estado': 'disponible',
    'fotos': <String>[rutaFoto1, rutaFoto2],
    'created_at': fecha,
    'updated_at': fecha,
    'dueno_nombre': 'Ana López',
    'dueno_foto_url': '$_urlSupabase/storage/v1/object/public/avatars/$idAlumno/a.jpg',
    'dueno_division_id': 11,
    'dueno_division': 'Mecatrónica, Desarrollo de Software e Ingeniería Civil',
    'dueno_carrera_id': 101,
    'dueno_carrera': 'Ingeniería en Desarrollo y Gestión de Software',
  };
}

/// HU-04: [cantidad] filas con ids `pub-0`, `pub-1`, …
List<Map<String, dynamic>> _filasVista(int cantidad) =>
    List<Map<String, dynamic>>.generate(cantidad, (i) => _filaVista('pub-$i'));

void main() {
  late _ApiSupabaseSimulada api;
  late SupabaseClient cliente;
  late PublicacionRepositoryImpl repositorio;

  setUp(() async {
    api = _ApiSupabaseSimulada();
    cliente = SupabaseClient(
      _urlSupabase,
      _anonKey,
      httpClient: api.cliente,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    // Reloj fijo: los nombres de las fotos son predecibles (1_0.jpg, 1_1.jpg).
    repositorio = PublicacionRepositoryImpl(PublicacionRemoteDataSourceImpl(
      cliente,
      reloj: () => DateTime.fromMicrosecondsSinceEpoch(1),
    ));

    // El estudiante ya inició sesión (HU-01).
    api.cuando('POST', '/auth/v1/token', (_) => _json(200, _sesionJson()));
    await cliente.auth.signInWithPassword(email: 'ana.lopez@utsjr.edu.mx', password: 'x');
  });

  tearDown(() async {
    await cliente.dispose();
  });

  CrearPublicacion crearPublicacion({bool conectado = true}) =>
      CrearPublicacion(repositorio, _RedSimulada(conectado: conectado));

  group('API REST de publicaciones (HU-03) — patrón AAA', () {
    test('CP-08: GET /rest/v1/categorias responde 200 con el catálogo activo y ordenado',
        () async {
      // ARRANGE
      api.cuando(
        'GET',
        '/rest/v1/categorias',
        (_) => _json(200, <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'nombre': 'Libros y apuntes', 'orden': 1},
          <String, dynamic>{'id': 2, 'nombre': 'Calculadoras', 'orden': 2},
        ]),
      );

      // ACT
      final List<Categoria> resultado =
          await ObtenerCategorias(repositorio, _RedSimulada(conectado: true))();

      // ASSERT
      expect(resultado.map((c) => c.nombre), ['Libros y apuntes', 'Calculadoras']);
      final http.Request peticion = api.peticionesDeLaApp.single;
      expect(peticion.method, 'GET');
      expect(peticion.url.queryParameters['activo'], 'eq.true');
      expect(peticion.url.queryParameters['order'], startsWith('orden.asc'));
      expect(peticion.headers['Authorization'], 'Bearer $_tokenAcceso');
    });

    test(
        'CP-09 (Escenario 1): sube las fotos a Storage y POST /rest/v1/publicaciones '
        'responde 201 Created; la publicación queda a nombre del alumno y Disponible',
        () async {
      // ARRANGE
      api.cuando('POST', _rutaStorage, (p) => _json(200, <String, dynamic>{'Key': p.url.path}));
      api.cuando('POST', _rutaPublicaciones, (p) => _json(201, _filaCreada(_cuerpoJson(p))));

      // ACT
      final Publicacion publicacion = await crearPublicacion()(borrador(
        modalidad: Modalidad.intercambio,
        fotos: [fotoJpg(), fotoPng()],
      ));

      // ASSERT: respuesta interpretada
      expect(publicacion.usuarioId, idAlumno);
      expect(publicacion.estado, EstadoPublicacion.inicial);
      expect(publicacion.modalidad, Modalidad.intercambio);
      expect(publicacion.precio, isNull);
      expect(publicacion.fotos, ['$idAlumno/1_0.jpg', '$idAlumno/1_1.png']);

      // ASSERT: peticiones enviadas (2 fotos + 1 publicación, en ese orden)
      final List<http.Request> peticiones = api.peticionesDeLaApp;
      expect(peticiones, hasLength(3));
      expect(peticiones[0].url.path, '$_rutaStorage/$idAlumno/1_0.jpg');
      expect(peticiones[1].url.path, '$_rutaStorage/$idAlumno/1_1.png');
      for (final http.Request subida in peticiones.take(2)) {
        expect(subida.method, 'POST');
        expect(subida.headers['Authorization'], 'Bearer $_tokenAcceso');
        expect(subida.headers['x-upsert'], 'false');
      }

      final http.Request alta = peticiones[2];
      expect(alta.method, 'POST');
      expect(alta.url.path, _rutaPublicaciones);
      expect(alta.headers['Authorization'], 'Bearer $_tokenAcceso');
      expect(alta.headers['Prefer'], contains('return=representation'));
      final Map<String, dynamic> cuerpo = _cuerpoJson(alta);
      expect(cuerpo['titulo'], tituloValido);
      expect(cuerpo['modalidad'], 'intercambio');
      expect(cuerpo['precio'], isNull);
      expect(cuerpo['fotos'], ['$idAlumno/1_0.jpg', '$idAlumno/1_1.png']);
      // No se confía en el cliente: el dueño y el estado los pone el servidor.
      expect(cuerpo.containsKey('usuario_id'), isFalse);
      expect(cuerpo.containsKey('estado'), isFalse);
    });

    test('CP-10 (Escenario 2): Venta sin precio no envía ninguna petición', () async {
      // ACT
      final Future<Publicacion> intento = crearPublicacion()(borrador(modalidad: Modalidad.venta));

      // ASSERT
      await expectLater(intento, throwsA(isA<PublicacionInvalidaFailure>()));
      expect(api.peticionesDeLaApp, isEmpty);
    });

    test(
        'CP-11 (Escenario 3, defensa en el servidor): si alguien salta la app y '
        'manda precio 0, el API responde 400 y la app lo traduce', () async {
      // ARRANGE
      api.cuando(
        'POST',
        _rutaPublicaciones,
        (_) => _json(400, <String, dynamic>{
          'code': '23514',
          'details': null,
          'hint': null,
          'message': 'new row for relation "publicaciones" violates check constraint '
              '"publicaciones_precio_chk"',
        }),
      );

      // ACT: se llama directo al repositorio, sin el validador de la app.
      final Future<Publicacion> intento = repositorio.crearPublicacion(
        titulo: tituloValido,
        descripcion: descripcionValida,
        categoriaId: 2,
        modalidad: Modalidad.venta,
        precio: 0,
        fotos: const [rutaFoto1],
      );

      // ASSERT: el mensaje NO expone el nombre de la tabla ni de la regla.
      await expectLater(
        intento,
        throwsA(isA<PublicacionRechazadaFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          isNot(contains('publicaciones_precio_chk')),
        )),
      );
      expect(_cuerpoJson(api.peticionesDeLaApp.single)['precio'], 0);
    });

    test('CP-12: si el API responde 400 al crear, la app borra las fotos que ya subió',
        () async {
      // ARRANGE
      api.cuando('POST', _rutaStorage, (p) => _json(200, <String, dynamic>{'Key': p.url.path}));
      api.cuando('POST', _rutaPublicaciones, (_) => _json(400, <String, dynamic>{'code': '23514', 'message': 'x'}));
      api.cuando('DELETE', _rutaStorage, (_) => _json(200, <dynamic>[]));

      // ACT
      final Future<Publicacion> intento = crearPublicacion()(borrador());

      // ASSERT
      await expectLater(intento, throwsA(isA<PublicacionRechazadaFailure>()));
      final http.Request borrado = api.peticionesDeLaApp.last;
      expect(borrado.method, 'DELETE');
      expect(borrado.url.path, _rutaStorage);
      expect(jsonDecode(borrado.body), <String, dynamic>{
        'prefixes': ['$idAlumno/1_0.jpg'],
      });
    });

    test('CP-13: el API responde 403 (RLS) si el perfil no está completo', () async {
      // ARRANGE
      api.cuando('POST', _rutaStorage, (p) => _json(200, <String, dynamic>{'Key': p.url.path}));
      api.cuando(
        'POST',
        _rutaPublicaciones,
        (_) => _json(403, <String, dynamic>{
          'code': '42501',
          'message': 'new row violates row-level security policy for table "publicaciones"',
        }),
      );
      api.cuando('DELETE', _rutaStorage, (_) => _json(200, <dynamic>[]));

      // ACT
      final Future<Publicacion> intento = crearPublicacion()(borrador());

      // ASSERT
      await expectLater(
        intento,
        throwsA(isA<PublicarSinPermisoFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          'Completa tu perfil académico antes de publicar.',
        )),
      );
    });

    test(
        'CP-14 (Escenario 4): Storage responde 413 (foto muy pesada) y no se '
        'crea la publicación', () async {
      // ARRANGE
      api.cuando(
        'POST',
        _rutaStorage,
        (_) => _json(413, <String, dynamic>{
          'statusCode': '413',
          'error': 'Payload too large',
          'message': 'The object exceeded the maximum allowed size',
        }),
      );

      // ACT
      final Future<Publicacion> intento = crearPublicacion()(borrador());

      // ASSERT
      await expectLater(
        intento,
        throwsA(isA<FotoArticuloDemasiadoGrandeFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          'Cada foto puede pesar máximo 5 MB.',
        )),
      );
      expect(api.peticionesDeLaApp.where((p) => p.url.path == _rutaPublicaciones), isEmpty);
    });

    test('CP-15 (Escenario 6): sin conexión no se envía ninguna petición', () async {
      // ACT
      final Future<Publicacion> intento = crearPublicacion(conectado: false)(borrador());

      // ASSERT
      await expectLater(intento, throwsA(isA<SinConexionFailure>()));
      expect(api.peticionesDeLaApp, isEmpty);
    });

    test('CP-16: sin sesión iniciada no se llama al API de publicaciones', () async {
      // ARRANGE
      api.cuando('POST', '/auth/v1/logout', (_) => http.Response('', 204));
      await cliente.auth.signOut();
      api.peticiones.clear();

      // ACT
      final Future<Publicacion> intento = repositorio.crearPublicacion(
        titulo: tituloValido,
        descripcion: descripcionValida,
        categoriaId: 2,
        modalidad: Modalidad.gratis,
        precio: null,
        fotos: const [rutaFoto1],
      );

      // ASSERT
      await expectLater(intento, throwsA(isA<SesionNoIniciadaFailure>()));
      await expectLater(repositorio.subirFoto(fotoJpg()), throwsA(isA<SesionNoIniciadaFailure>()));
      expect(api.peticiones, isEmpty);
    });

    test(
        'CP-17: los demás errores del API llegan como mensajes en español '
        'sin detalles internos', () async {
      // ARRANGE
      api.cuando('GET', '/rest/v1/categorias', (_) => _json(500, <String, dynamic>{
            'code': 'XX000',
            'message': 'internal error at 10.0.0.8',
          }));
      api.cuando('POST', '$_rutaStorage/$idAlumno/1_0', (_) => _json(415, <String, dynamic>{
            'statusCode': '415',
            'error': 'invalid_mime_type',
            'message': 'mime type image/gif is not supported',
          }));
      api.cuando('POST', '$_rutaStorage/$idAlumno/1_1', (_) => _json(403, <String, dynamic>{
            'statusCode': '403',
            'error': 'Unauthorized',
            'message': 'new row violates row-level security policy',
          }));
      api.cuando('POST', '$_rutaStorage/$idAlumno/1_2', (_) => _json(500, <String, dynamic>{
            'statusCode': '500',
            'error': 'internal',
            'message': 'boom',
          }));
      api.cuando('POST', _rutaPublicaciones, (_) => _json(409, <String, dynamic>{
            'code': '23503',
            'message': 'insert or update violates foreign key constraint',
          }));
      api.cuando('DELETE', _rutaStorage, (_) => _json(500, <String, dynamic>{
            'statusCode': '500',
            'error': 'internal',
            'message': 'boom',
          }));

      // ACT + ASSERT
      await expectLater(
        repositorio.obtenerCategorias(),
        throwsA(isA<ServidorFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          'Ocurrió un error inesperado. Inténtalo de nuevo.',
        )),
      );
      await expectLater(repositorio.subirFoto(fotoJpg()), throwsA(isA<FotoFormatoInvalidoFailure>()));
      await expectLater(
        repositorio.subirFoto(fotoJpg()),
        throwsA(isA<ServidorFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          'No tienes permiso para subir fotos en esa carpeta.',
        )),
      );
      await expectLater(repositorio.subirFoto(fotoJpg()), throwsA(isA<ServidorFailure>()));
      await expectLater(
        repositorio.subirFoto(fotoGif()),
        throwsA(isA<FotoFormatoInvalidoFailure>()),
      );
      await expectLater(
        repositorio.crearPublicacion(
          titulo: tituloValido,
          descripcion: descripcionValida,
          categoriaId: 99,
          modalidad: Modalidad.gratis,
          precio: null,
          fotos: const [rutaFoto1],
        ),
        throwsA(isA<PublicacionInvalidaFailure>().having(
          (f) => f.errores[CampoPublicacion.categoria],
          'error de categoría',
          'La categoría seleccionada no existe.',
        )),
      );
      await expectLater(repositorio.eliminarFotos(const [rutaFoto1]), throwsA(isA<ServidorFailure>()));
      await repositorio.eliminarFotos(const []);
    });
  });

  group('API REST del Feed y el Detalle (HU-04) — patrón AAA', () {
    ObtenerFeed obtenerFeed({bool conectado = true}) =>
        ObtenerFeed(repositorio, _RedSimulada(conectado: conectado));

    ObtenerDetallePublicacion obtenerDetalle({bool conectado = true}) =>
        ObtenerDetallePublicacion(repositorio, _RedSimulada(conectado: conectado));

    test(
        'CP-18 (Escenario 1): POST /rest/v1/rpc/feed_publicaciones responde 200 con las '
        'publicaciones, su dueño, su categoría y la URL pública de cada foto', () async {
      // ARRANGE
      api.cuando('POST', _rutaFeed, (_) => _json(200, <Map<String, dynamic>>[_filaVista('pub-1')]));

      // ACT
      final PaginaFeed pagina = await obtenerFeed()();

      // ASSERT: respuesta interpretada
      final Publicacion publicacion = pagina.publicaciones.single;
      expect(publicacion.precio, 150);
      expect(publicacion.duenoNombre, 'Ana López');
      expect(publicacion.categoriaNombre, 'Calculadoras');
      expect(publicacion.estado, const Disponible());
      expect(
        publicacion.portadaUrl,
        '$_urlSupabase/storage/v1/object/public/publicaciones/$rutaFoto1',
      );
      expect(publicacion.fotosUrls, hasLength(2));

      // ASSERT: petición enviada (primera página: sin cursor, 20 por página)
      final http.Request peticion = api.peticionesDeLaApp.single;
      expect(peticion.method, 'POST');
      expect(peticion.url.path, _rutaFeed);
      expect(_cuerpoJson(peticion), <String, dynamic>{'p_limite': 20});
      expect(peticion.headers['Authorization'], 'Bearer $_tokenAcceso');
    });

    test('CP-19 (Escenario 6): si el Feed responde 500, la app muestra un mensaje genérico',
        () async {
      // ARRANGE
      api.cuando('POST', _rutaFeed, (_) => _json(500, <String, dynamic>{
            'code': 'XX000',
            'message': 'internal error at 10.0.0.8',
          }));

      // ACT + ASSERT
      await expectLater(
        obtenerFeed()(),
        throwsA(isA<CargarPublicacionesFailure>()
            .having((f) => f.mensaje, 'mensaje', 'No pudimos cargar las publicaciones. Inténtalo de nuevo.')
            .having((f) => f.mensaje, 'sin detalles internos', isNot(contains('10.0.0.8')))),
      );
    });

    test(
        'CP-20 (Escenario 2): una página completa (20) trae el cursor con la fecha EXACTA '
        '(microsegundos) y el id de la última', () async {
      // ARRANGE
      api.cuando('POST', _rutaFeed, (_) => _json(200, _filasVista(20)));

      // ACT
      final PaginaFeed pagina = await obtenerFeed()();

      // ASSERT
      expect(pagina.publicaciones, hasLength(20));
      expect(pagina.hayMas, isTrue);
      expect(
        pagina.siguiente,
        const CursorFeed(fecha: '2026-10-13T18:00:00.123456+00:00', id: 'pub-19'),
      );
    });

    test(
        'CP-21 (Escenario 2): la siguiente página envía p_antes_de y p_antes_id; si llegan '
        'menos de 20, ya no hay más', () async {
      // ARRANGE
      api.cuando('POST', _rutaFeed, (_) => _json(200, _filasVista(3)));
      const CursorFeed cursor = CursorFeed(fecha: '2026-10-13T18:00:00.123456+00:00', id: 'pub-19');

      // ACT
      final PaginaFeed pagina = await obtenerFeed()(despuesDe: cursor);

      // ASSERT
      expect(pagina.publicaciones, hasLength(3));
      expect(pagina.hayMas, isFalse);
      expect(_cuerpoJson(api.peticionesDeLaApp.single), <String, dynamic>{
        'p_limite': 20,
        'p_antes_de': '2026-10-13T18:00:00.123456+00:00',
        'p_antes_id': 'pub-19',
      });
    });

    test('CP-22 (Escenario 4): 200 con una lista vacía es un Feed vacío, sin cursor', () async {
      // ARRANGE
      api.cuando('POST', _rutaFeed, (_) => _json(200, <Map<String, dynamic>>[]));

      // ACT
      final PaginaFeed pagina = await obtenerFeed()();

      // ASSERT
      expect(pagina.publicaciones, isEmpty);
      expect(pagina.hayMas, isFalse);
    });

    test(
        'CP-23 (Escenario 7): GET /rest/v1/publicaciones_detalle?id=eq.<id> responde 200 '
        'con todas las fotos y el perfil público del dueño', () async {
      // ARRANGE
      api.cuando('GET', _rutaDetalle, (_) => _json(200, <Map<String, dynamic>>[_filaVista('pub-1')]));

      // ACT
      final Publicacion publicacion = await obtenerDetalle()('pub-1');

      // ASSERT: respuesta interpretada
      expect(publicacion.id, 'pub-1');
      expect(publicacion.fotosUrls, [
        '$_urlSupabase/storage/v1/object/public/publicaciones/$rutaFoto1',
        '$_urlSupabase/storage/v1/object/public/publicaciones/$rutaFoto2',
      ]);
      expect(publicacion.duenoDivision, 'Mecatrónica, Desarrollo de Software e Ingeniería Civil');
      expect(publicacion.duenoCarrera, 'Ingeniería en Desarrollo y Gestión de Software');
      expect(publicacion.duenoFotoUrl, endsWith('/avatars/$idAlumno/a.jpg'));
      expect(publicacion.creadaEn, DateTime.utc(2026, 10, 13, 18, 0, 0, 123, 456));

      // ASSERT: petición enviada
      final http.Request peticion = api.peticionesDeLaApp.single;
      expect(peticion.method, 'GET');
      expect(peticion.url.path, _rutaDetalle);
      expect(peticion.url.queryParameters['id'], 'eq.pub-1');
      expect(peticion.url.queryParameters['limit'], '1');
      expect(peticion.headers['Authorization'], 'Bearer $_tokenAcceso');
    });

    test(
        'CP-24 (Escenario 10): si la publicación se borró (200 con lista vacía o id '
        'inválido 400), la app muestra "ya no está disponible"', () async {
      // ARRANGE
      api.cuando('GET', _rutaDetalle, (p) {
        if (p.url.queryParameters['id'] == 'eq.no-es-uuid') {
          return _json(400, <String, dynamic>{
            'code': '22P02',
            'message': 'invalid input syntax for type uuid: "no-es-uuid"',
          });
        }
        return _json(200, <Map<String, dynamic>>[]);
      });

      // ACT + ASSERT
      for (final String id in ['borrada', 'no-es-uuid']) {
        await expectLater(
          obtenerDetalle()(id),
          throwsA(isA<PublicacionNoEncontradaFailure>().having(
            (f) => f.mensaje,
            'mensaje',
            'Esta publicación ya no está disponible.',
          )),
        );
      }
    });

    test('CP-25 (Escenario 6): si el Detalle responde 500, el mensaje no revela detalles internos',
        () async {
      // ARRANGE
      api.cuando('GET', _rutaDetalle, (_) => _json(500, <String, dynamic>{
            'code': 'XX000',
            'message': 'relation "publicaciones_detalle" failed at 10.0.0.8',
          }));

      // ACT + ASSERT
      await expectLater(
        obtenerDetalle()('pub-1'),
        throwsA(isA<CargarPublicacionesFailure>()
            .having((f) => f.mensaje, 'sin IP', isNot(contains('10.0.0.8')))
            .having((f) => f.mensaje, 'sin nombres internos', isNot(contains('publicaciones_detalle')))),
      );
    });

    test('CP-26 (Escenario 5): sin conexión no se envía ninguna petición', () async {
      // ACT + ASSERT
      await expectLater(obtenerFeed(conectado: false)(), throwsA(isA<SinConexionFailure>()));
      await expectLater(
        obtenerDetalle(conectado: false)('pub-1'),
        throwsA(isA<SinConexionFailure>()),
      );
      expect(api.peticionesDeLaApp, isEmpty);
    });

    test('CP-27: sin sesión no se envía ninguna petición al Feed ni al Detalle', () async {
      // ARRANGE: un cliente que nunca inició sesión.
      final SupabaseClient sinSesion = SupabaseClient(
        _urlSupabase,
        _anonKey,
        httpClient: api.cliente,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final PublicacionRepositoryImpl repo =
          PublicacionRepositoryImpl(PublicacionRemoteDataSourceImpl(sinSesion));

      // ACT + ASSERT
      await expectLater(repo.obtenerFeed(limite: 20), throwsA(isA<SesionNoIniciadaFailure>()));
      await expectLater(repo.obtenerDetalle('pub-1'), throwsA(isA<SesionNoIniciadaFailure>()));
      expect(api.peticionesDeLaApp, isEmpty);
      await sinSesion.dispose();
    });
  });
}
