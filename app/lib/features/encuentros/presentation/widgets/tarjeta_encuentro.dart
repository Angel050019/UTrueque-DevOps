import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../../chat/domain/entities/mensaje.dart';
import '../../domain/entities/encuentro.dart';
import '../../domain/validators/horario_encuentro.dart';
import '../encuentro_keys.dart';

/// Tarjeta de encuentro dentro del chat (HU-08). La crea el servidor como
/// un mensaje con tipo: propuesta, aceptado (la tarjeta de confirmación),
/// rechazado o cancelado.
///
/// Los botones solo aparecen en la tarjeta de PROPUESTA (aceptar, rechazar o
/// cancelar) y en la de CONFIRMACIÓN (cancelar), y solo si el encuentro
/// sigue en ese estado. Si el encuentro todavía no se carga, se muestra el
/// texto del mensaje.
// TODO(diseño): tarjetas según Figma.
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

    return Center(
      key: EncuentroKeys.tarjeta(mensaje.id),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _esConfirmacion ? AppColores.acentoSuave : AppColores.superficie,
            borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
            border: Border.all(color: _esConfirmacion ? AppColores.acento : AppColores.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_icono, color: AppColores.primario, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_titulo, style: AppTexto.subtitulo(size: 15))),
                  Text(formatearHora(mensaje.creadoEn), style: AppTexto.cuerpo(size: 11)),
                ],
              ),
              const SizedBox(height: 8),
              if (e == null)
                Text(mensaje.texto, style: AppTexto.cuerpo(size: 14, color: AppColores.texto))
              else ...[
                Text(e.punto.nombre, style: AppTexto.subtitulo(size: 15)),
                if (e.punto.referencia.isNotEmpty)
                  Text(e.punto.referencia, style: AppTexto.cuerpo(size: 13)),
                const SizedBox(height: 4),
                Text(
                  HorarioEncuentro.formatear(e.fechaHora),
                  style: AppTexto.cuerpo(size: 14, color: AppColores.texto),
                ),
                if (mensaje.tipo == TipoMensaje.rechazado || mensaje.tipo == TipoMensaje.cancelado)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      mensaje.esDe(miId)
                          ? (mensaje.tipo == TipoMensaje.rechazado ? 'La rechazaste.' : 'Lo cancelaste.')
                          : (mensaje.tipo == TipoMensaje.rechazado ? 'La rechazó el otro estudiante.' : 'Lo canceló el otro estudiante.'),
                      style: AppTexto.cuerpo(size: 13),
                    ),
                  ),
              ],
              if (textoEstado != null) ...[
                const SizedBox(height: 8),
                Text(
                  textoEstado,
                  key: EncuentroKeys.estadoTarjeta(mensaje.id),
                  style: AppTexto.cuerpo(size: 13, color: AppColores.primario, peso: FontWeight.w600),
                ),
              ],
              if (e != null && puedeResponder) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        key: EncuentroKeys.aceptar(mensaje.id),
                        onPressed: habilitada ? () => onAceptar(e) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColores.primario,
                          foregroundColor: AppColores.sobrePrimario,
                        ),
                        child: const Text('Aceptar punto de encuentro', textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: EncuentroKeys.rechazar(mensaje.id),
                      onPressed: habilitada ? () => onRechazar(e) : null,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColores.primario),
                      child: const Text('Rechazar'),
                    ),
                  ],
                ),
              ],
              if (e != null && puedeCancelar) ...[
                const SizedBox(height: 6),
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
      ),
    );
  }
}

/// Escenario 2: aviso fijo arriba del chat con el encuentro confirmado.
// TODO(diseño): aviso fijo según Figma.
class AvisoEncuentroConfirmado extends StatelessWidget {
  const AvisoEncuentroConfirmado({super.key, required this.encuentro});

  final Encuentro encuentro;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: EncuentroKeys.avisoConfirmado,
      padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margen, vertical: 10),
      color: AppColores.acentoSuave,
      child: Row(
        children: [
          const Icon(Icons.place_rounded, color: AppColores.primario, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Encuentro confirmado: ${encuentro.punto.nombre}, ${HorarioEncuentro.formatear(encuentro.fechaHora)}',
              style: AppTexto.cuerpo(size: 13, color: AppColores.primario, peso: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
