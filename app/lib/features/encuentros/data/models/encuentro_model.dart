import '../../domain/entities/encuentro.dart';
import '../../domain/entities/punto_encuentro.dart';

/// Un lugar del catálogo tal como llega de
/// `GET /rest/v1/puntos_encuentro?select=id,nombre,referencia`.
class PuntoEncuentroModel extends PuntoEncuentro {
  const PuntoEncuentroModel({required super.id, required super.nombre, required super.referencia});

  static const String tabla = 'puntos_encuentro';
  static const String columnasSelect = 'id, nombre, referencia';

  factory PuntoEncuentroModel.fromMap(Map<String, dynamic> mapa) {
    return PuntoEncuentroModel(
      id: mapa['id'] as String,
      nombre: mapa['nombre'] as String,
      referencia: (mapa['referencia'] as String?) ?? '',
    );
  }
}

/// Un encuentro tal como llega de `POST /rest/v1/rpc/encuentros_conversacion`.
class EncuentroModel extends Encuentro {
  const EncuentroModel({
    required super.id,
    required super.conversacionId,
    required super.propuestoPor,
    required super.punto,
    required super.fechaHora,
    required super.estado,
    required super.creadoEn,
  });

  factory EncuentroModel.fromMap(Map<String, dynamic> mapa) {
    return EncuentroModel(
      id: mapa['id'] as String,
      conversacionId: mapa['conversacion_id'] as String,
      propuestoPor: mapa['propuesto_por'] as String,
      punto: PuntoEncuentro(
        id: mapa['punto_id'] as String,
        nombre: mapa['punto_nombre'] as String,
        referencia: (mapa['punto_referencia'] as String?) ?? '',
      ),
      fechaHora: DateTime.parse(mapa['fecha_hora'] as String),
      estado: EstadoEncuentro.desdeValor(mapa['estado'] as String?),
      creadoEn: DateTime.parse(mapa['created_at'] as String),
    );
  }
}
