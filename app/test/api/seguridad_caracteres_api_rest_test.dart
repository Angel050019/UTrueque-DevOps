// Pruebas del API REST de seguridad con el patrón AAA (Sprint 6: caracteres
// permitidos en el título, la descripción y el nombre a mostrar).
//
// CP-48 a CP-50: publicaciones. CP-51 y CP-52: perfil.
//
// Igual que en publicaciones_api_rest_test.dart, se ejercita la cadena REAL:
//
//   Caso de uso -> Repositorio -> RemoteDataSource -> SupabaseClient -> HTTP
//
// y solo se sustituye la red por un servidor simulado (MockClient). Se
// comprueba que la app no envía textos con caracteres no permitidos y que,
// si alguien se salta la app, el servidor los rechaza y la app marca el
// campo exacto sin mostrar detalles internos.
//
// Ver docs/Plan_de_Pruebas.md (anexo de caracteres permitidos).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/perfil/data/datasources/perfil_remote_datasource.dart';
import 'package:utrueque/features/perfil/data/repositories/perfil_repository_impl.dart';
import 'package:utrueque/features/perfil/domain/entities/perfil.dart';
import 'package:utrueque/features/perfil/domain/usecases/actualizar_perfil.dart';
import 'package:utrueque/features/perfil/domain/validators/perfil_validator.dart';
import 'package:utrueque/features/publicaciones/data/datasources/publicacion_remote_datasource.dart';
import 'package:utrueque/features/publicaciones/data/repositories/publicacion_repository_impl.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/crear_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/validators/publicacion_validator.dart';

import '../features/perfil/fixtures.dart' as perfil;
import '../features/publicaciones/fixtures.dart' as pub;

const String _urlSupabase = 'https://utrueque-pruebas.supabase.co';
const String _rutaUsuarios = '/rest/v1/usuarios';
const String _rutaPublicaciones = '/rest/v1/publicaciones';
const String _idAlumno = pub.idAlumno;

class _RedSimulada implements NetworkInfo {
  _RedSimulada({required this.conectado});

  final bool conectado;

  @override
  Future<bool> get estaConectado async => conectado;
}

http.Response _json(int codigo, Object cuerpo) => http.Response(
      jsonEncode(cuerpo),
      codigo,
      headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _sesionJson() => <String, dynamic>{
      'access_token': 'token-de-acceso-de-pruebas',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh-token-de-pruebas',
      'user': <String, dynamic>{
        'id': _idAlumno,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'ana.lopez@utsjr.edu.mx',
        'email_confirmed_at': '2026-09-20T10:00:00Z',
        'app_metadata': <String, dynamic>{'provider': 'email'},
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-09-20T10:00:00Z',
      },
    };

void main() {
  late List<http.Request> peticiones;
  late http.Response Function(http.Request) responderUsuarios;
  late http.Response Function(http.Request) responderPublicaciones;
  late SupabaseClient cliente;
  late PerfilRepositoryImpl repositorio;
  late PublicacionRepositoryImpl publicaciones;

  setUp(() async {
    peticiones = <http.Request>[];
    responderUsuarios = (_) => _json(500, <String, dynamic>{'message': 'sin respuesta simulada'});
    responderPublicaciones = responderUsuarios;
    final MockClient red = MockClient((http.Request p) async {
      peticiones.add(p);
      final http.Response r = p.url.path.startsWith('/auth/')
          ? _json(200, _sesionJson())
          : p.url.path == _rutaUsuarios
              ? responderUsuarios(p)
              : p.url.path == _rutaPublicaciones
                  ? responderPublicaciones(p)
                  : _json(404, <String, dynamic>{'message': 'Ruta no simulada'});
      return http.Response.bytes(r.bodyBytes, r.statusCode, headers: r.headers, request: p);
    });
    cliente = SupabaseClient(
      _urlSupabase,
      'anon-key-de-pruebas',
      httpClient: red,
      authOptions: const AuthClientOptions(autoRefreshToken: false, authFlowType: AuthFlowType.implicit),
    );
    repositorio = PerfilRepositoryImpl(PerfilRemoteDataSourceImpl(cliente));
    publicaciones = PublicacionRepositoryImpl(PublicacionRemoteDataSourceImpl(cliente));
    await cliente.auth.signInWithPassword(email: 'ana.lopez@utsjr.edu.mx', password: 'x');
  });

  tearDown(() async => cliente.dispose());

  List<http.Request> peticionesDeLaApp() => peticiones.where((p) => !p.url.path.startsWith('/auth/')).toList();

  ActualizarPerfil actualizar() => ActualizarPerfil(repositorio, _RedSimulada(conectado: true));
  CrearPublicacion crear() => CrearPublicacion(publicaciones, _RedSimulada(conectado: true));
  Map<String, dynamic> cuerpo(http.Request p) => jsonDecode(p.body) as Map<String, dynamic>;

  group('SEGURIDAD: caracteres permitidos en publicaciones (Sprint 6) — patrón AAA', () {
    test(
        'CP-48: un título o una descripción con caracteres no permitidos no envía '
        'ninguna petición (ni fotos ni publicación)', () async {
      // ACT
      final Future<Publicacion> conTitulo = crear()(pub.borrador(titulo: '<script>alert(1)</script>'));
      final Future<Publicacion> conDescripcion = crear()(pub.borrador(descripcion: "Buen estado' OR '1'='1"));

      // ASSERT
      await expectLater(
        conTitulo,
        throwsA(isA<PublicacionInvalidaFailure>().having(
          (f) => f.errores[CampoPublicacion.titulo],
          'error del título',
          PublicacionValidator.mensajeTituloCaracteres,
        )),
      );
      await expectLater(
        conDescripcion,
        throwsA(isA<PublicacionInvalidaFailure>().having(
          (f) => f.errores[CampoPublicacion.descripcion],
          'error de la descripción',
          PublicacionValidator.mensajeDescripcionCaracteres,
        )),
      );
      expect(peticionesDeLaApp(), isEmpty);
    });

    test(
        'CP-49 (defensa en el servidor): si alguien salta la app, el API responde 400 '
        '(pista titulo_caracteres) y la app marca el título sin detalles internos', () async {
      // ARRANGE
      responderPublicaciones = (_) => _json(400, <String, dynamic>{
            'code': '23514',
            'details': null,
            'hint': 'titulo_caracteres',
            'message': 'El título tiene caracteres no permitidos',
          });

      // ACT: directo al repositorio, sin el validador de la app.
      final Future<Publicacion> intento = publicaciones.crearPublicacion(
        titulo: '<img src=x onerror=alert(1)>',
        descripcion: pub.descripcionValida,
        categoriaId: 2,
        modalidad: Modalidad.gratis,
        precio: null,
        fotos: const [pub.rutaFoto1],
      );

      // ASSERT
      await expectLater(
        intento,
        throwsA(isA<PublicacionInvalidaFailure>()
            .having((f) => f.errores.keys, 'campos', [CampoPublicacion.titulo])
            .having((f) => f.errores[CampoPublicacion.titulo], 'mensaje',
                PublicacionValidator.mensajeTituloCaracteres)),
      );
      final http.Request envio = peticionesDeLaApp().single;
      expect(envio.method, 'POST');
      expect(cuerpo(envio)['titulo'], '<img src=x onerror=alert(1)>');
    });

    test('CP-50 (defensa en el servidor): pista descripcion_caracteres → se marca la descripción; '
        'sin pista sigue siendo un rechazo general', () async {
      // ARRANGE: primero con la pista de la descripción, luego sin pista.
      int intentos = 0;
      responderPublicaciones = (_) => _json(400, <String, dynamic>{
            'code': '23514',
            'hint': ++intentos == 1 ? 'descripcion_caracteres' : null,
            'message': 'rechazado',
          });
      Future<Publicacion> publicar() => publicaciones.crearPublicacion(
            titulo: pub.tituloValido,
            descripcion: 'Usado; ver {detalles}',
            categoriaId: 2,
            modalidad: Modalidad.gratis,
            precio: null,
            fotos: const [pub.rutaFoto1],
          );

      // ACT + ASSERT
      await expectLater(
        publicar(),
        throwsA(isA<PublicacionInvalidaFailure>().having(
          (f) => f.errores,
          'errores',
          {CampoPublicacion.descripcion: PublicacionValidator.mensajeDescripcionCaracteres},
        )),
      );
      await expectLater(publicar(), throwsA(isA<PublicacionRechazadaFailure>()));
    });
  });

  group('SEGURIDAD: caracteres permitidos en el nombre del perfil (Sprint 6) — patrón AAA', () {
    test('CP-51: un nombre con caracteres no permitidos no envía ninguna petición', () async {
      // ACT
      final Future<Perfil> intento = actualizar()(
        nombre: '<script>alert(1)</script>',
        division: perfil.divisionTI,
        carrera: perfil.carreraSoftware,
      );

      // ASSERT
      await expectLater(
        intento,
        throwsA(const NombreInvalidoFailure(PerfilValidator.mensajeNombreCaracteres)),
      );
      expect(peticionesDeLaApp(), isEmpty);
    });

    test(
        'CP-52 (defensa en el servidor): si alguien salta la app, el API responde 400 '
        '(pista nombre_caracteres) y la app muestra el mensaje de caracteres', () async {
      // ARRANGE
      responderUsuarios = (_) => _json(400, <String, dynamic>{
            'code': '23514',
            'hint': 'nombre_caracteres',
            'message': 'El nombre tiene caracteres no permitidos',
          });

      // ACT: directo al repositorio, sin el validador de la app.
      final Future<Perfil> intento = repositorio.actualizarPerfil(
        nombreMostrar: "Ana' OR '1'='1",
        divisionId: 1,
        carreraId: 1,
      );

      // ASSERT
      await expectLater(
        intento,
        throwsA(const NombreInvalidoFailure(PerfilValidator.mensajeNombreCaracteres)),
      );
      final http.Request envio = peticionesDeLaApp().single;
      expect(envio.method, 'POST');
      expect((jsonDecode(envio.body) as Map<String, dynamic>)['nombre_mostrar'], "Ana' OR '1'='1");
    });

    test('CP-52 (sin pista): un 23514 por la longitud sigue dando el mensaje de longitud',
        () async {
      // ARRANGE
      responderUsuarios = (_) => _json(400, <String, dynamic>{
            'code': '23514',
            'message': 'new row for relation "usuarios" violates check constraint',
          });

      // ACT + ASSERT
      await expectLater(
        repositorio.actualizarPerfil(nombreMostrar: 'ab', divisionId: 1, carreraId: 1),
        throwsA(isA<NombreInvalidoFailure>()
            .having((f) => f.mensaje, 'mensaje', contains('entre'))
            .having((f) => f.mensaje, 'sin detalles', isNot(contains('usuarios')))),
      );
    });
  });
}
