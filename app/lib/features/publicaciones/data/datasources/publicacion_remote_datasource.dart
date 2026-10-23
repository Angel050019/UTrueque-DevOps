import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/formato_imagen.dart';
import '../../domain/entities/filtros_feed.dart';
import '../../domain/entities/foto_articulo.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/pagina_feed.dart';
import '../../domain/errors/publicacion_failures.dart';
import '../models/publicacion_model.dart';

/// Fuente de datos remota de publicaciones. Es la única capa de esta
/// feature que importa `supabase_flutter`; traduce sus excepciones a
/// [Failure]s con mensajes en español que no revelan detalles internos.
abstract class PublicacionRemoteDataSource {
  Future<PaginaFeed> buscarPublicaciones({
    FiltrosFeed filtros = const FiltrosFeed(),
    CursorFeed? despuesDe,
    required int limite,
  });
  Future<PublicacionModel> obtenerDetalle(String id);
  Future<List<CategoriaModel>> obtenerCategorias();
  Future<String> subirFoto(FotoArticulo foto);
  Future<void> eliminarFotos(List<String> rutas);
  Future<PublicacionModel> crearPublicacion({
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required Modalidad modalidad,
    required double? precio,
    required List<String> fotos,
  });
}

class PublicacionRemoteDataSourceImpl implements PublicacionRemoteDataSource {
  PublicacionRemoteDataSourceImpl(this._client, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _reloj;

  /// Distingue fotos subidas en el mismo instante.
  int _contador = 0;

  String get _idUsuarioActual {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) throw const SesionNoIniciadaFailure();
    return id;
  }

  StorageFileApi get _bucket => _client.storage.from(AppConstants.bucketPublicaciones);

  /// HU-04 y HU-05: una página del Feed con la función
  /// `buscar_publicaciones` (`POST /rest/v1/rpc/buscar_publicaciones`). La
  /// base ya filtra las Vendidas, aplica la búsqueda y los filtros, ordena
  /// de la más nueva a la más vieja y une la categoría y el perfil público
  /// del dueño. Solo se mandan los filtros que están puestos.
  @override
  Future<PaginaFeed> buscarPublicaciones({
    FiltrosFeed filtros = const FiltrosFeed(),
    CursorFeed? despuesDe,
    required int limite,
  }) async {
    // Si no hay sesión, no tiene caso llamar al API (el Feed es solo para
    // estudiantes autenticados).
    if (_client.auth.currentUser == null) throw const SesionNoIniciadaFailure();
    // SEGURIDAD: validación de entrada. Sin espacios de más y máximo 100
    // caracteres (la base vuelve a recortar y quita los signos).
    final String texto = FiltrosFeed.normalizarTexto(filtros.texto);
    try {
      final List<dynamic> respuesta = await _client.rpc<List<dynamic>>(
        PublicacionModel.funcionBuscar,
        params: <String, dynamic>{
          'p_limite': limite,
          if (texto.isNotEmpty) 'p_texto': texto,
          if (filtros.categoriaId != null) 'p_categoria_id': filtros.categoriaId,
          if (filtros.divisionId != null) 'p_division_id': filtros.divisionId,
          if (filtros.carreraId != null) 'p_carrera_id': filtros.carreraId,
          if (despuesDe != null) 'p_antes_de': despuesDe.fecha,
          if (despuesDe != null) 'p_antes_id': despuesDe.id,
        },
      );
      final List<Map<String, dynamic>> filas =
          respuesta.cast<Map<String, dynamic>>().toList(growable: false);
      final List<PublicacionModel> publicaciones = filas
          .map((fila) => PublicacionModel.fromMap(fila, urlFoto: _bucket.getPublicUrl))
          .toList(growable: false);

      // Si llegó la página completa puede haber más: el cursor es la última
      // publicación, con su fecha tal como la mandó el servidor.
      final CursorFeed? siguiente = filas.length < limite
          ? null
          : CursorFeed(fecha: filas.last['created_at'] as String, id: filas.last['id'] as String);
      return PaginaFeed(publicaciones: publicaciones, siguiente: siguiente);
    } on PostgrestException {
      // SEGURIDAD: mensaje genérico, sin detalles internos.
      throw const CargarPublicacionesFailure();
    }
  }

  /// HU-04: detalle desde la vista `publicaciones_detalle`
  /// (`GET /rest/v1/publicaciones_detalle?id=eq.<id>`). Si la respuesta
  /// llega vacía, la publicación ya se borró.
  @override
  Future<PublicacionModel> obtenerDetalle(String id) async {
    if (_client.auth.currentUser == null) throw const SesionNoIniciadaFailure();
    try {
      final List<Map<String, dynamic>> filas = await _client
          .from(PublicacionModel.vistaDetalle)
          .select()
          .eq('id', id)
          .limit(1);
      if (filas.isEmpty) throw const PublicacionNoEncontradaFailure();
      return PublicacionModel.fromMap(filas.first, urlFoto: _bucket.getPublicUrl);
    } on PostgrestException catch (e) {
      // Un id con formato inválido (22P02) es lo mismo que "no existe".
      if (e.code == '22P02') throw const PublicacionNoEncontradaFailure();
      throw const CargarPublicacionesFailure();
    }
  }

  @override
  Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final List<Map<String, dynamic>> filas = await _client
          .from(AppConstants.tablaCategorias)
          .select(CategoriaModel.columnasSelect)
          .eq('activo', true)
          // Ojo: en supabase-dart `order` es descendente por defecto.
          .order('orden', ascending: true)
          .order('nombre', ascending: true);
      return filas.map(CategoriaModel.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<String> subirFoto(FotoArticulo foto) async {
    final FormatoImagen? formato = foto.formato;
    if (formato == null) throw const FotoFormatoInvalidoFailure();

    // SEGURIDAD: mínimo privilegio (cada quien escribe solo en su carpeta).
    // publicaciones/<id del usuario>/<marca de tiempo>_<n>.<ext>
    // Las políticas de Storage solo permiten escribir en la carpeta propia,
    // y la base revisa que las rutas de `fotos` estén en esa carpeta.
    final String ruta = '$_idUsuarioActual/'
        '${_reloj().microsecondsSinceEpoch}_${_contador++}.${formato.extension}';
    try {
      await _bucket.uploadBinary(
        ruta,
        foto.bytes,
        fileOptions: FileOptions(contentType: formato.contentType),
      );
      return ruta;
    } on StorageException catch (e) {
      switch (e.statusCode) {
        case '413':
          throw const FotoArticuloDemasiadoGrandeFailure();
        case '415':
          throw const FotoFormatoInvalidoFailure();
        case '403':
          throw const ServidorFailure('No tienes permiso para subir fotos en esa carpeta.');
        default:
          throw const ServidorFailure('No se pudo subir la foto. Inténtalo de nuevo.');
      }
    }
  }

  @override
  Future<void> eliminarFotos(List<String> rutas) async {
    if (rutas.isEmpty) return;
    try {
      await _bucket.remove(rutas);
    } on StorageException {
      throw const ServidorFailure('No se pudieron borrar las fotos.');
    }
  }

  @override
  Future<PublicacionModel> crearPublicacion({
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required Modalidad modalidad,
    required double? precio,
    required List<String> fotos,
  }) async {
    // Si no hay sesión, no tiene caso llamar al API.
    if (_client.auth.currentUser == null) throw const SesionNoIniciadaFailure();
    try {
      final Map<String, dynamic> fila = await _client
          .from(AppConstants.tablaPublicaciones)
          .insert(PublicacionModel.paraCrear(
            titulo: titulo,
            descripcion: descripcion,
            categoriaId: categoriaId,
            modalidad: modalidad,
            precio: precio,
            fotos: fotos,
          ))
          .select(PublicacionModel.columnasSelect)
          .single();
      return PublicacionModel.fromMap(fila);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// SEGURIDAD: errores sin detalles internos (no se muestran nombres de
  /// tablas, reglas ni direcciones del servidor).
  /// Traduce los códigos de error de Postgres a fallos entendibles.
  Failure _traducir(PostgrestException e) {
    switch (e.code) {
      case '23514': // check: precio, fotos, longitudes o trigger de reglas
        return const PublicacionRechazadaFailure();
      case '23503': // llave foránea: la categoría no existe
        return const PublicacionInvalidaFailure(
          {CampoPublicacion.categoria: 'La categoría seleccionada no existe.'},
        );
      case '42501': // RLS: perfil incompleto o publicación ajena
        return const PublicarSinPermisoFailure();
      default:
        return const ServidorFailure();
    }
  }
}
