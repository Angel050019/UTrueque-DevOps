// Pruebas del API REST de UTrueque (Supabase) con el patrón AAA.
//
// UTrueque no tiene un backend propio: su API REST es la que expone Supabase
// (`/auth/v1/...` para autenticación y `/rest/v1/...` para las tablas de
// Postgres). Estas pruebas ejercitan la cadena REAL de la app:
//
//   Caso de uso -> AuthRepositoryImpl -> AuthRemoteDataSourceImpl
//               -> SupabaseClient -> HTTP
//
// y solo sustituyen la red por un servidor simulado (MockClient de
// `package:http`). Así validamos qué peticiones HTTP envía la app y cómo
// interpreta cada código de respuesta (200, 204, 400, 422), sin depender de
// internet ni de la base de datos de producción.
//
// Ver docs/Plan_de_Pruebas.md, Sección 2.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:utrueque/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:utrueque/features/auth/domain/entities/usuario.dart';
import 'package:utrueque/features/auth/domain/usecases/iniciar_sesion.dart';
import 'package:utrueque/features/auth/domain/usecases/registrar_usuario.dart';

const String _urlSupabase = 'https://utrueque-pruebas.supabase.co';
const String _anonKey = 'anon-key-de-pruebas';
const String _tokenAcceso = 'token-de-acceso-de-pruebas';

const String _idAlumno = '7f1c2a9e-0000-4000-8000-000000000001';
const String _correoAlumno = 'ana.lopez@alumno.utsjr.edu.mx';
const String _contrasena = 'Contrasena123';

/// Servidor HTTP simulado que imita las respuestas del API REST de Supabase
/// y guarda cada petición recibida para poder verificarla en el ASSERT.
class _ApiSupabaseSimulada {
  final List<http.Request> peticiones = <http.Request>[];
  final Map<String, http.Response Function(http.Request)> _rutas =
      <String, http.Response Function(http.Request)>{};

  late final MockClient cliente = MockClient((http.Request peticion) async {
    peticiones.add(peticion);
    final http.Response Function(http.Request)? responder =
        _rutas['${peticion.method} ${peticion.url.path}'];
    final http.Response respuesta = responder == null
        ? _respuestaJson(404, <String, dynamic>{'msg': 'Ruta no simulada'})
        : responder(peticion);
    // Supabase (postgrest) lee `response.request`, así que la respuesta
    // simulada debe ir ligada a la petición que la originó.
    return http.Response.bytes(
      respuesta.bodyBytes,
      respuesta.statusCode,
      headers: respuesta.headers,
      request: peticion,
    );
  });

  /// Registra la respuesta que dará el servidor para `metodo` + `ruta`.
  void cuando(
    String metodo,
    String ruta,
    http.Response Function(http.Request) responder,
  ) {
    _rutas['$metodo $ruta'] = responder;
  }
}

/// Conectividad simulada (evita depender del plugin connectivity_plus).
class _RedSimulada implements NetworkInfo {
  _RedSimulada({required this.conectado});

  final bool conectado;

  @override
  Future<bool> get estaConectado async => conectado;
}

http.Response _respuestaJson(int codigo, Object cuerpo) {
  return http.Response(
    jsonEncode(cuerpo),
    codigo,
    headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
  );
}

/// Usuario tal como lo devuelve Supabase Auth (GoTrue).
Map<String, dynamic> _usuarioAuthJson({required bool correoConfirmado}) {
  return <String, dynamic>{
    'id': _idAlumno,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': _correoAlumno,
    'email_confirmed_at': correoConfirmado ? '2026-09-20T10:00:00Z' : null,
    'app_metadata': <String, dynamic>{'provider': 'email'},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-09-20T10:00:00Z',
  };
}

/// Sesión que devuelve `POST /auth/v1/token?grant_type=password`.
Map<String, dynamic> _sesionJson() {
  return <String, dynamic>{
    'access_token': _tokenAcceso,
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh-token-de-pruebas',
    'user': _usuarioAuthJson(correoConfirmado: true),
  };
}

void main() {
  late _ApiSupabaseSimulada api;
  late SupabaseClient cliente;
  late AuthRepositoryImpl repositorio;

  setUp(() {
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
    repositorio = AuthRepositoryImpl(AuthRemoteDataSourceImpl(cliente));
  });

  tearDown(() async {
    await cliente.dispose();
  });

  group('API REST de autenticación (HU-01) — patrón AAA', () {
    test(
        'CP-01: POST /auth/v1/token responde 200 y el inicio de sesión '
        'devuelve el perfil del alumno desde /rest/v1/usuarios', () async {
      // ARRANGE
      api.cuando('POST', '/auth/v1/token', (_) => _respuestaJson(200, _sesionJson()));
      api.cuando(
        'GET',
        '/rest/v1/usuarios',
        (_) => _respuestaJson(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'id': _idAlumno,
            'nombre_mostrar': 'Ana López',
            'division': 'Tecnologías de la Información',
            'carrera': 'Ingeniería en Desarrollo y Gestión de Software',
          },
        ]),
      );
      final IniciarSesion iniciarSesion =
          IniciarSesion(repositorio, _RedSimulada(conectado: true));

      // ACT
      final Usuario usuario =
          await iniciarSesion(correo: _correoAlumno, contrasena: _contrasena);

      // ASSERT
      expect(usuario.id, _idAlumno);
      expect(usuario.correo, _correoAlumno);
      expect(usuario.correoConfirmado, isTrue);
      expect(usuario.nombreMostrar, 'Ana López');
      expect(usuario.carrera, 'Ingeniería en Desarrollo y Gestión de Software');

      expect(api.peticiones, hasLength(2));
      final http.Request login = api.peticiones[0];
      expect(login.method, 'POST');
      expect(login.url.path, '/auth/v1/token');
      expect(login.url.queryParameters['grant_type'], 'password');
      expect(login.headers['apikey'], _anonKey);
      expect(jsonDecode(login.body), containsPair('email', _correoAlumno));

      final http.Request perfil = api.peticiones[1];
      expect(perfil.method, 'GET');
      expect(perfil.url.path, '/rest/v1/usuarios');
      expect(perfil.url.queryParameters['id'], 'eq.$_idAlumno');
      expect(perfil.headers['Authorization'], 'Bearer $_tokenAcceso');

      expect(repositorio.usuarioActual?.id, _idAlumno);
    });

    test(
        'CP-02: el registro con un correo no institucional se rechaza '
        'sin enviar ninguna petición al API', () async {
      // ARRANGE
      final RegistrarUsuario registrarUsuario = RegistrarUsuario(repositorio);

      // ACT
      final Future<Usuario> intento = registrarUsuario(
        correo: 'ana.lopez@gmail.com',
        contrasena: _contrasena,
        confirmarContrasena: _contrasena,
      );

      // ASSERT
      await expectLater(intento, throwsA(isA<CorreoNoInstitucionalFailure>()));
      expect(api.peticiones, isEmpty);
    });

    test(
        'CP-03: POST /auth/v1/signup responde 200 y la cuenta queda '
        'pendiente de confirmar el correo institucional', () async {
      // ARRANGE
      api.cuando(
        'POST',
        '/auth/v1/signup',
        (_) => _respuestaJson(200, _usuarioAuthJson(correoConfirmado: false)),
      );
      final RegistrarUsuario registrarUsuario = RegistrarUsuario(repositorio);

      // ACT
      final Usuario usuario = await registrarUsuario(
        correo: _correoAlumno,
        contrasena: _contrasena,
        confirmarContrasena: _contrasena,
      );

      // ASSERT
      expect(usuario.id, _idAlumno);
      expect(usuario.correo, _correoAlumno);
      expect(usuario.correoConfirmado, isFalse);

      expect(api.peticiones, hasLength(1));
      final http.Request registro = api.peticiones.single;
      expect(registro.method, 'POST');
      expect(registro.url.path, '/auth/v1/signup');
      final Map<String, dynamic> cuerpo =
          jsonDecode(registro.body) as Map<String, dynamic>;
      expect(cuerpo['email'], _correoAlumno);
      expect(cuerpo['password'], _contrasena);

      expect(repositorio.usuarioActual, isNull);
    });

    test(
        'CP-04: POST /auth/v1/token responde 400 (credenciales inválidas) '
        'y la app muestra CredencialesInvalidasFailure', () async {
      // ARRANGE
      api.cuando(
        'POST',
        '/auth/v1/token',
        (_) => _respuestaJson(400, <String, dynamic>{
          'code': 'invalid_credentials',
          'error_code': 'invalid_credentials',
          'msg': 'Invalid login credentials',
        }),
      );
      final IniciarSesion iniciarSesion =
          IniciarSesion(repositorio, _RedSimulada(conectado: true));

      // ACT
      final Future<Usuario> intento =
          iniciarSesion(correo: _correoAlumno, contrasena: 'ContrasenaIncorrecta');

      // ASSERT
      await expectLater(intento, throwsA(isA<CredencialesInvalidasFailure>()));
      expect(api.peticiones, hasLength(1));
      expect(api.peticiones.single.url.path, '/auth/v1/token');
      expect(repositorio.usuarioActual, isNull);
    });

    test(
        'CP-05: sin conexión a internet el inicio de sesión falla con '
        'SinConexionFailure y no se llama al API', () async {
      // ARRANGE
      final IniciarSesion iniciarSesion =
          IniciarSesion(repositorio, _RedSimulada(conectado: false));

      // ACT
      final Future<Usuario> intento =
          iniciarSesion(correo: _correoAlumno, contrasena: _contrasena);

      // ASSERT
      await expectLater(intento, throwsA(isA<SinConexionFailure>()));
      expect(api.peticiones, isEmpty);
    });

    test(
        'CP-06: POST /auth/v1/signup responde 422 (correo ya registrado) '
        'y el mensaje del servidor llega a la app', () async {
      // ARRANGE
      api.cuando(
        'POST',
        '/auth/v1/signup',
        (_) => _respuestaJson(422, <String, dynamic>{
          'code': 'user_already_exists',
          'error_code': 'user_already_exists',
          'msg': 'User already registered',
        }),
      );
      final RegistrarUsuario registrarUsuario = RegistrarUsuario(repositorio);

      // ACT
      final Future<Usuario> intento = registrarUsuario(
        correo: _correoAlumno,
        contrasena: _contrasena,
        confirmarContrasena: _contrasena,
      );

      // ASSERT
      await expectLater(
        intento,
        throwsA(
          isA<ServidorFailure>()
              .having((ServidorFailure f) => f.mensaje, 'mensaje', 'User already registered'),
        ),
      );
      expect(api.peticiones, hasLength(1));
    });

    test(
        'CP-07: POST /auth/v1/logout responde 204 y la sesión local '
        'queda cerrada', () async {
      // ARRANGE
      api.cuando('POST', '/auth/v1/token', (_) => _respuestaJson(200, _sesionJson()));
      api.cuando(
        'GET',
        '/rest/v1/usuarios',
        (_) => _respuestaJson(200, <Map<String, dynamic>>[]),
      );
      api.cuando('POST', '/auth/v1/logout', (_) => http.Response('', 204));
      await repositorio.iniciarSesion(correo: _correoAlumno, contrasena: _contrasena);
      expect(repositorio.usuarioActual, isNotNull);

      // ACT
      await repositorio.cerrarSesion();

      // ASSERT
      expect(repositorio.usuarioActual, isNull);
      final http.Request logout = api.peticiones.last;
      expect(logout.method, 'POST');
      expect(logout.url.path, '/auth/v1/logout');
      expect(logout.headers['Authorization'], 'Bearer $_tokenAcceso');
    });
  });
}
