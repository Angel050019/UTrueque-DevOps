import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/foto_perfil.dart';
import '../models/division_model.dart';
import '../models/perfil_model.dart';

/// Fuente de datos remota del perfil. Es la única capa de esta feature que
/// importa `supabase_flutter`; traduce sus excepciones a [Failure]s.
abstract class PerfilRemoteDataSource {
  Future<PerfilModel> obtenerPerfilPropio();
  Future<PerfilModel> obtenerPerfilPorId(String id);
  Future<PerfilModel> actualizarPerfil({
    required String nombreMostrar,
    required int divisionId,
    required int carreraId,
    String? fotoUrl,
  });
  Future<String> subirFoto(FotoPerfil foto);
  Future<List<DivisionModel>> obtenerCatalogoAcademico();
}

class PerfilRemoteDataSourceImpl implements PerfilRemoteDataSource {
  PerfilRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _idUsuarioActual {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) throw const SesionNoIniciadaFailure();
    return id;
  }

  @override
  Future<PerfilModel> obtenerPerfilPropio() => obtenerPerfilPorId(_idUsuarioActual);

  @override
  Future<PerfilModel> obtenerPerfilPorId(String id) async {
    try {
      final Map<String, dynamic>? fila = await _client
          .from(AppConstants.tablaUsuarios)
          .select(PerfilModel.columnasSelect)
          .eq('id', id)
          .maybeSingle();
      if (fila == null) {
        // Usuario registrado antes de la migración y sin fila: se trata
        // como perfil vacío (incompleto) en lugar de un error.
        if (id == _client.auth.currentUser?.id) return PerfilModel(id: id);
        throw const PerfilNoEncontradoFailure();
      }
      return PerfilModel.fromMap(fila);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<PerfilModel> actualizarPerfil({
    required String nombreMostrar,
    required int divisionId,
    required int carreraId,
    String? fotoUrl,
  }) async {
    final Map<String, dynamic> valores = <String, dynamic>{
      'id': _idUsuarioActual,
      'nombre_mostrar': nombreMostrar,
      'division_id': divisionId,
      'carrera_id': carreraId,
      // Si no hay foto nueva no se manda la columna, así se conserva la actual.
      if (fotoUrl != null) 'foto_url': fotoUrl,
    };
    try {
      // upsert: crea la fila si no existía (usuarios anteriores a HU-02) o
      // la actualiza. perfil_completo y updated_at los calcula la base.
      final Map<String, dynamic> fila = await _client
          .from(AppConstants.tablaUsuarios)
          .upsert(valores)
          .select(PerfilModel.columnasSelect)
          .single();
      return PerfilModel.fromMap(fila);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<String> subirFoto(FotoPerfil foto) async {
    final FormatoImagen? formato = foto.formato;
    if (formato == null) throw const FotoFormatoInvalidoFailure();

    // Ruta fija por usuario: avatars/<id>/avatar.<ext>. Las políticas de
    // Storage solo permiten escribir dentro de la carpeta propia.
    final String ruta = '$_idUsuarioActual/avatar.${formato.extension}';
    try {
      await _client.storage.from(AppConstants.bucketAvatars).uploadBinary(
            ruta,
            foto.bytes,
            fileOptions: FileOptions(contentType: formato.contentType, upsert: true),
          );
      final String url = _client.storage.from(AppConstants.bucketAvatars).getPublicUrl(ruta);
      // El parámetro ?v= evita que el celular muestre la foto vieja en caché.
      return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    } on StorageException catch (e) {
      if (e.statusCode == '413') throw const FotoDemasiadoGrandeFailure();
      if (e.statusCode == '415') throw const FotoFormatoInvalidoFailure();
      throw const ServidorFailure('No se pudo subir la foto. Inténtalo de nuevo.');
    }
  }

  @override
  Future<List<DivisionModel>> obtenerCatalogoAcademico() async {
    try {
      final List<Map<String, dynamic>> filas = await _client
          .from(AppConstants.tablaDivisiones)
          .select(DivisionModel.columnasSelect)
          .eq('activo', true)
          // Ojo: en supabase-dart `order` es descendente por defecto.
          .order('orden', ascending: true)
          .order('nombre', ascending: true);
      return filas.map(DivisionModel.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// Traduce los códigos de error de Postgres a fallos entendibles.
  Failure _traducir(PostgrestException e) {
    switch (e.code) {
      case '23503': // llave foránea: la carrera no es de esa división
        return const CarreraNoPerteneceFailure();
      case '23514': // check: nombre fuera de 3–50 caracteres
        return const NombreInvalidoFailure(
          'El nombre debe tener entre ${AppConstants.nombreLongitudMinima} y '
          '${AppConstants.nombreLongitudMaxima} caracteres.',
        );
      case '42501': // RLS
        return const ServidorFailure('No tienes permiso para modificar este perfil.');
      default:
        return const ServidorFailure();
    }
  }
}
