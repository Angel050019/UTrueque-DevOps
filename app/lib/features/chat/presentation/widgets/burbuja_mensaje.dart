import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../domain/entities/mensaje.dart';
import '../chat_keys.dart';

/// Un mensaje del chat: los míos a la derecha en azul marino y los del otro
/// a la izquierda en blanco, con la hora abajo a la derecha.
///
/// Si [continuacion] es `true`, el mensaje anterior es del mismo autor: se
/// pega más a él y no lleva "colita" arriba.
class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje({super.key, required this.mensaje, required this.esMio, this.continuacion = false});

  final Mensaje mensaje;
  final bool esMio;
  final bool continuacion;

  @override
  Widget build(BuildContext context) {
    final Color letra = esMio ? AppColores.sobrePrimario : AppColores.texto;
    const Radius grande = Radius.circular(18);
    const Radius chica = Radius.circular(6);
    return Align(
      key: ChatKeys.burbuja(mensaje.id),
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: EdgeInsets.only(top: continuacion ? 2 : 8),
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
          decoration: BoxDecoration(
            color: esMio ? null : AppColores.superficie,
            gradient: esMio
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B5378), AppColores.primario],
                  )
                : null,
            border: esMio ? null : Border.all(color: AppColores.borde),
            borderRadius: BorderRadius.only(
              topLeft: !esMio && !continuacion ? chica : grande,
              topRight: esMio && !continuacion ? chica : grande,
              bottomLeft: grande,
              bottomRight: grande,
            ),
            boxShadow: const [BoxShadow(color: Color(0x0F033B56), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(mensaje.texto, style: AppTexto.cuerpo(size: 15, color: letra)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  formatearHora(mensaje.creadoEn),
                  style: AppTexto.cuerpo(size: 11, color: esMio ? AppColores.acento : AppColores.textoSecundario),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
