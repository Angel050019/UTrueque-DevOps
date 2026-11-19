import '../../domain/entities/resumen_reputacion.dart';
import '../../domain/entities/trato.dart';

/// Lee un entero que puede llegar como `int`, `double` o texto.
int _entero(Object? valor) => switch (valor) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

/// Lee una fecha que puede faltar.
DateTime? _fecha(Object? valor) => valor is String ? DateTime.parse(valor) : null;

/// `POST /rest/v1/rpc/reputacion_usuario` → una fila con los conteos.
class ResumenReputacionModel extends ResumenReputacion {
  const ResumenReputacionModel({
    required super.usuarioId,
    super.una,
    super.dos,
    super.tres,
    super.cuatro,
    super.cinco,
  });

  factory ResumenReputacionModel.fromMap(Map<String, dynamic> mapa, {required String usuarioId}) {
    return ResumenReputacionModel(
      usuarioId: (mapa['usuario_id'] as String?) ?? usuarioId,
      una: _entero(mapa['una']),
      dos: _entero(mapa['dos']),
      tres: _entero(mapa['tres']),
      cuatro: _entero(mapa['cuatro']),
      cinco: _entero(mapa['cinco']),
    );
  }
}

/// `POST /rest/v1/rpc/compradores_posibles`.
class CompradorPosibleModel extends CompradorPosible {
  const CompradorPosibleModel({
    required super.conversacionId,
    required super.compradorId,
    required super.nombre,
    super.fotoUrl,
    super.ultimoMensajeEn,
  });

  factory CompradorPosibleModel.fromMap(Map<String, dynamic> mapa) {
    return CompradorPosibleModel(
      conversacionId: mapa['conversacion_id'] as String,
      compradorId: mapa['comprador_id'] as String,
      nombre: (mapa['comprador_nombre'] as String?) ?? 'Estudiante de la UTSJR',
      fotoUrl: mapa['comprador_foto_url'] as String?,
      ultimoMensajeEn: _fecha(mapa['ultimo_mensaje_en']),
    );
  }
}

/// `POST /rest/v1/rpc/tratos_por_calificar`.
class TratoPorCalificarModel extends TratoPorCalificar {
  const TratoPorCalificarModel({
    required super.ventaId,
    required super.publicacionId,
    required super.publicacionTitulo,
    required super.soyVendedor,
    required super.otroId,
    required super.otroNombre,
    required super.vendidaEn,
    required super.venceEn,
    super.conversacionId,
    super.publicacionFotoUrl,
    super.otroFotoUrl,
  });

  factory TratoPorCalificarModel.fromMap(Map<String, dynamic> mapa, {String Function(String ruta)? urlFoto}) {
    final DateTime vendidaEn = DateTime.parse(mapa['vendida_en'] as String);
    final String? ruta = mapa['publicacion_foto'] as String?;
    return TratoPorCalificarModel(
      ventaId: mapa['venta_id'] as String,
      conversacionId: mapa['conversacion_id'] as String?,
      publicacionId: mapa['publicacion_id'] as String,
      publicacionTitulo: (mapa['publicacion_titulo'] as String?) ?? 'Publicación',
      publicacionFotoUrl: ruta == null ? null : (urlFoto == null ? ruta : urlFoto(ruta)),
      soyVendedor: (mapa['soy_vendedor'] as bool?) ?? false,
      otroId: mapa['otro_id'] as String,
      otroNombre: (mapa['otro_nombre'] as String?) ?? 'Estudiante de la UTSJR',
      otroFotoUrl: mapa['otro_foto_url'] as String?,
      vendidaEn: vendidaEn,
      venceEn: _fecha(mapa['vence_en']) ??
          vendidaEn.add(const Duration(days: TratoPorCalificar.diasParaCalificar)),
    );
  }
}

/// `POST /rest/v1/rpc/calificaciones_recibidas`.
class CalificacionRecibidaModel extends CalificacionRecibida {
  const CalificacionRecibidaModel({
    required super.id,
    required super.estrellas,
    required super.creadaEn,
    required super.autorId,
    required super.autorNombre,
    required super.publicacionTitulo,
    required super.comoVendedor,
    super.comentario,
    super.autorFotoUrl,
  });

  factory CalificacionRecibidaModel.fromMap(Map<String, dynamic> mapa) {
    return CalificacionRecibidaModel(
      id: mapa['id'] as String,
      estrellas: _entero(mapa['estrellas']),
      comentario: mapa['comentario'] as String?,
      creadaEn: DateTime.parse(mapa['created_at'] as String),
      autorId: mapa['autor_id'] as String,
      autorNombre: (mapa['autor_nombre'] as String?) ?? 'Estudiante de la UTSJR',
      autorFotoUrl: mapa['autor_foto_url'] as String?,
      publicacionTitulo: (mapa['publicacion_titulo'] as String?) ?? 'Publicación',
      comoVendedor: (mapa['como_vendedor'] as bool?) ?? false,
    );
  }
}
