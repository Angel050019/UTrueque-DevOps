import '../../domain/entities/mensaje.dart';

/// Un mensaje tal como llega del servidor: de la función
/// `mensajes_conversacion`, del POST a `mensajes` o del registro que manda
/// Supabase Realtime por WebSocket (las tres usan las mismas columnas).
class MensajeModel extends Mensaje {
  const MensajeModel({
    required super.id,
    required super.conversacionId,
    required super.autorId,
    required super.texto,
    required super.creadoEn,
    super.tipo,
    super.encuentroId,
  });

  static const String tablaMensajes = 'mensajes';
  /// Columnas que se piden al enviar. No incluye `tipo` ni `encuentro_id`
  /// (HU-08): lo que envía la app siempre es texto normal, y así enviar
  /// sigue funcionando aunque la migración de HU-08 no esté aplicada.
  static const String columnasSelect = 'id, conversacion_id, autor_id, texto, created_at';

  factory MensajeModel.fromMap(Map<String, dynamic> mapa) {
    return MensajeModel(
      id: mapa['id'] as String,
      conversacionId: mapa['conversacion_id'] as String,
      autorId: mapa['autor_id'] as String,
      texto: mapa['texto'] as String,
      creadoEn: DateTime.parse(mapa['created_at'] as String),
      // HU-08: si la columna no viene (migración sin aplicar), es texto normal.
      tipo: TipoMensaje.desdeValor(mapa['tipo'] as String?),
      encuentroId: mapa['encuentro_id'] as String?,
    );
  }

  /// Datos que la app envía al escribir. SEGURIDAD: no incluye `autor_id`
  /// (lo pone el servidor con la sesión), la fecha, el tipo ni el encuentro
  /// (las tarjetas de encuentro solo las crea el servidor).
  static Map<String, dynamic> paraEnviar(String conversacionId, String texto) =>
      <String, dynamic>{'conversacion_id': conversacionId, 'texto': texto};
}
