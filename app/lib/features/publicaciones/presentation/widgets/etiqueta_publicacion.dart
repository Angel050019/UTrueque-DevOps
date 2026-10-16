import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/estado_publicacion.dart';

/// Etiqueta redondeada (precio, modalidad, categoría, estado…). La usan la
/// tarjeta del Feed y el Detalle.
class EtiquetaPublicacion extends StatelessWidget {
  const EtiquetaPublicacion({
    super.key,
    required this.texto,
    required this.fondo,
    required this.color,
  });

  /// Etiqueta del estado (patrón State): menta si está Disponible, roja si
  /// está Reservado o Vendido.
  factory EtiquetaPublicacion.estado(EstadoPublicacion estado, {Key? key}) {
    final bool disponible = estado is Disponible;
    return EtiquetaPublicacion(
      key: key,
      texto: estado.etiqueta,
      fondo: disponible ? AppColores.acentoSuave : AppColores.errorSuave,
      color: disponible ? AppColores.primario : AppColores.error,
    );
  }

  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(999)),
      child: Text(texto, style: AppTexto.cuerpo(size: 12, color: color, peso: FontWeight.w600)),
    );
  }
}
