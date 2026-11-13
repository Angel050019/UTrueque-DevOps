import 'package:flutter/widgets.dart';

/// Keys de los puntos de encuentro (HU-08). Las pruebas buscan los widgets
/// por estas Keys, así el diseño puede cambiar sin romper pruebas. Si
/// rediseñas, CONSERVA las Keys.
class EncuentroKeys {
  EncuentroKeys._();

  // En el chat
  static const Key botonProponer = Key('encuentro_boton_proponer');
  static const Key avisoConfirmado = Key('encuentro_aviso_confirmado');

  // Hoja "Proponer punto de encuentro"
  static const Key hoja = Key('encuentro_hoja');
  static const Key ampliarMapa = Key('encuentro_ampliar_mapa');
  static const Key hojaCargando = Key('encuentro_hoja_cargando');
  static const Key hojaError = Key('encuentro_hoja_error');
  static const Key hojaReintentar = Key('encuentro_hoja_reintentar');
  static const Key hojaSinHorarios = Key('encuentro_hoja_sin_horarios');
  static const Key hojaMensajeError = Key('encuentro_hoja_mensaje_error');
  static const Key enviarPropuesta = Key('encuentro_enviar_propuesta');

  /// Opción del lugar con ese id.
  static Key punto(String id) => Key('encuentro_punto_$id');

  /// Botón del día (fecha `aaaa-mm-dd`).
  static Key dia(DateTime dia) => Key('encuentro_dia_${dia.toIso8601String().substring(0, 10)}');

  /// Botón del horario (instante en UTC).
  static Key hora(DateTime hora) => Key('encuentro_hora_${hora.toUtc().toIso8601String()}');

  // Tarjeta de encuentro dentro del chat
  /// Tarjeta del mensaje con ese id.
  static Key tarjeta(String mensajeId) => Key('encuentro_tarjeta_$mensajeId');

  /// Estado que muestra la tarjeta del mensaje con ese id.
  static Key estadoTarjeta(String mensajeId) => Key('encuentro_estado_$mensajeId');

  static Key aceptar(String mensajeId) => Key('encuentro_aceptar_$mensajeId');
  static Key rechazar(String mensajeId) => Key('encuentro_rechazar_$mensajeId');
  static Key cancelar(String mensajeId) => Key('encuentro_cancelar_$mensajeId');

  /// Botón "Sí, cancelar" del cuadro de confirmación.
  static const Key confirmarCancelar = Key('encuentro_confirmar_cancelar');
}
