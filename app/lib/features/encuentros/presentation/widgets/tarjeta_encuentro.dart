import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../../chat/domain/entities/mensaje.dart';
import '../../domain/entities/encuentro.dart';
import '../../domain/validators/horario_encuentro.dart';
import '../encuentro_keys.dart';
import 'mapa_campus.dart';

/// Tarjeta de encuentro dentro del chat (HU-08). La crea el servidor como
/// un mensaje con tipo: propuesta, aceptado (la tarjeta de confirmación),
/// rechazado o cancelado.
///
/// Los botones solo aparecen en la tarjeta de PROPUESTA (aceptar, rechazar o
/// cancelar) y en la de CONFIRMACIÓN (cancelar), y solo si el encuentro
/// sigue en ese estado. Si el encuentro todavía no se carga, se muestra el
/// texto del mensaje.
class TarjetaEncuentro extends StatelessWidget {
  const TarjetaEncuentro({
    super.key,
    required this.mensaje,
    required this.encuentro,
    required this.miId,
    required this.ahora,
    required this.habilitada,
    required this.onAceptar,
    required this.onRechazar,
    required this.onCancelar,
  });

  final Mensaje mensaje;
  final Encuentro? encuentro;
  final String? miId;
  final DateTime ahora;

  /// `false` mientras se envía otra acción o si la conversación está cerrada.
  final bool habilitada;
  final ValueChanged<Encuentro> onAceptar;
  final ValueChanged<Encuentro> onRechazar;
  final ValueChanged<Encuentro> onCancelar;

  String get _titulo => switch (mensaje.tipo) {
        TipoMensaje.propuesta => 'Propuesta de encuentro',
        TipoMensaje.aceptado => 'Punto de encuentro confirmado',
        TipoMensaje.rechazado => 'Propuesta rechazada',
        TipoMensaje.cancelado => 'Encuentro cancelado',
        TipoMensaje.texto => 'Punto de encuentro',
      };

  IconData get _icono => switch (mensaje.tipo) {
        TipoMensaje.aceptado => Icons.check_circle_rounded,
        TipoMensaje.rechazado || TipoMensaje.cancelado => Icons.cancel_rounded,
        _ => Icons.place_rounded,
      };

  bool get _esConfirmacion => mensaje.tipo == TipoMensaje.aceptado;

  @override
  Widget build(BuildContext context) {
    final Encuentro? e = encuentro;
    final EstadoEncuentro? estado = e?.estadoAl(ahora);
    final bool esPropuesta = mensaje.tipo == TipoMensaje.propuesta;
    // La tarjeta de propuesta muestra el estado actual; la de confirmación,
    // solo si ya no está confirmado (cancelado o ya pasó).
    final String? textoEstado = (e == null || estado == null)
        ? null
        : (esPropuesta
            ? (estado == EstadoEncuentro.propuesto && e.puedeResponder(miId, ahora)
                ? 'Te toca responder'
                : estado.etiqueta)
            : (_esConfirmacion && estado != EstadoEncuentro.aceptado
                ? (estado == EstadoEncuentro.cancelado ? 'Cancelado' : estado.etiqueta)
                : null));
    final bool puedeResponder = e != null && esPropuesta && e.puedeResponder(miId, ahora);
    final bool puedeCancelar = e != null &&
        ((esPropuesta && estado == EstadoEncuentro.propuesto) || (_esConfirmacion && estado == EstadoEncuentro.aceptado)) &&
        e.puedeCancelar(miId, ahora);

    final bool apagada = mensaje.tipo == TipoMensaje.rechazado || mensaje.tipo == TipoMensaje.cancelado;
    final Color colorTema = _esConfirmacion
        ? const Color(0xFF1E8A55)
        : apagada
            ? AppColores.textoSecundario
            : AppColores.primario;

    return Center(
      key: EncuentroKeys.tarjeta(mensaje.id),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColores.superficie,
            borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
            border: Border.all(color: _esConfirmacion ? AppColores.acento : AppColores.borde),
            boxShadow: const [BoxShadow(color: Color(0x14033B56), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Franja superior con el tipo de tarjeta.
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  color: _esConfirmacion
                      ? AppColores.acentoSuave
                      : apagada
                          ? AppColores.fondo
                          : AppColores.primarioSuave,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppMedidas.radioTarjeta - 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: colorTema, shape: BoxShape.circle),
                      child: Icon(_icono, color: AppColores.sobrePrimario, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_titulo, style: AppTexto.subtitulo(size: 14, color: colorTema))),
                    Text(formatearHora(mensaje.creadoEn), style: AppTexto.cuerpo(size: 11)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (e == null)
                      Text(mensaje.texto, style: AppTexto.cuerpo(size: 14, color: AppColores.texto))
                    else ...[
                      if (!apagada) ...[
                        MiniMapaCampus(puntoId: e.punto.id, nombre: e.punto.nombre),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(MapaCampus.iconoDe(e.punto.id), size: 20, color: colorTema),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.punto.nombre, style: AppTexto.subtitulo(size: 15)),
                                if (e.punto.referencia.isNotEmpty)
                                  Text(e.punto.referencia, style: AppTexto.cuerpo(size: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 20, color: colorTema),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              HorarioEncuentro.formatear(e.fechaHora),
                              style: AppTexto.cuerpo(size: 14, color: AppColores.texto, peso: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (apagada)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            mensaje.esDe(miId)
                                ? (mensaje.tipo == TipoMensaje.rechazado ? 'La rechazaste.' : 'Lo cancelaste.')
                                : (mensaje.tipo == TipoMensaje.rechazado
                                    ? 'La rechazó el otro estudiante.'
                                    : 'Lo canceló el otro estudiante.'),
                            style: AppTexto.cuerpo(size: 13),
                          ),
                        ),
                    ],
                    if (textoEstado != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: puedeResponder ? AppColores.acentoSuave : AppColores.fondo,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: puedeResponder ? AppColores.acento : AppColores.borde),
                        ),
                        child: Text(
                          textoEstado,
                          key: EncuentroKeys.estadoTarjeta(mensaje.id),
                          style: AppTexto.cuerpo(size: 12, color: AppColores.primario, peso: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (e != null && puedeResponder) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: EncuentroKeys.aceptar(mensaje.id),
                        onPressed: habilitada ? () => onAceptar(e) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColores.primario,
                          foregroundColor: AppColores.sobrePrimario,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMedidas.radioCampo)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Aceptar punto de encuentro'),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton(
                        key: EncuentroKeys.rechazar(mensaje.id),
                        onPressed: habilitada ? () => onRechazar(e) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColores.primario,
                          minimumSize: const Size.fromHeight(40),
                          side: const BorderSide(color: AppColores.borde),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMedidas.radioCampo)),
                        ),
                        child: const Text('Rechazar'),
                      ),
                    ],
                    if (e != null && puedeCancelar) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: EncuentroKeys.cancelar(mensaje.id),
                          onPressed: habilitada ? () => onCancelar(e) : null,
                          style: TextButton.styleFrom(foregroundColor: AppColores.error),
                          child: Text(esPropuesta ? 'Cancelar propuesta' : 'Cancelar encuentro'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Escenario 2: aviso fijo arriba del chat con el encuentro confirmado.
class AvisoEncuentroConfirmado extends StatelessWidget {
  const AvisoEncuentroConfirmado({super.key, required this.encuentro});

  final Encuentro encuentro;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: EncuentroKeys.avisoConfirmado,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColores.acentoSuave, Color(0xFFD3FBE7)]),
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        border: Border.all(color: AppColores.acento),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColores.primario, shape: BoxShape.circle),
            child: Icon(MapaCampus.iconoDe(encuentro.punto.id), color: AppColores.acento, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encuentro confirmado: ${encuentro.punto.nombre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTexto.subtitulo(size: 13, color: AppColores.primario),
                ),
                Text(
                  HorarioEncuentro.formatear(encuentro.fechaHora),
                  style: AppTexto.cuerpo(size: 12, color: AppColores.texto),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: Color(0xFF1E8A55), size: 22),
        ],
      ),
    );
  }
}
