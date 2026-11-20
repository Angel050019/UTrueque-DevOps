import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/modalidad.dart';
import '../publicacion_keys.dart';

/// Tres botones: Venta, Intercambio y Gratis. El elegido se pinta con el
/// azul del logo. Si [error] no es null, se muestra en rojo debajo.
class SelectorModalidad extends StatelessWidget {
  const SelectorModalidad({
    super.key,
    required this.seleccionada,
    required this.onSeleccionar,
    this.error,
    this.habilitado = true,
  });

  final Modalidad? seleccionada;
  final ValueChanged<Modalidad> onSeleccionar;
  final String? error;
  final bool habilitado;

  static IconData _icono(Modalidad modalidad) {
    switch (modalidad) {
      case Modalidad.venta:
        return Icons.sell_rounded;
      case Modalidad.intercambio:
        return Icons.swap_horiz_rounded;
      case Modalidad.gratis:
        return Icons.volunteer_activism_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Modalidad', style: AppTexto.etiqueta()),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final Modalidad modalidad in Modalidad.values) ...[
              if (modalidad != Modalidad.values.first) const SizedBox(width: 8),
              Expanded(
                child: _Opcion(
                  key: PublicacionKeys.modalidad(modalidad),
                  texto: modalidad.etiqueta,
                  icono: _icono(modalidad),
                  activa: modalidad == seleccionada,
                  conError: error != null,
                  onTap: habilitado ? () => onSeleccionar(modalidad) : null,
                ),
              ),
            ],
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            key: PublicacionKeys.errorModalidad,
            style: AppTexto.cuerpo(size: 12, color: AppColores.error),
          ),
        ],
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    super.key,
    required this.texto,
    required this.icono,
    required this.activa,
    required this.conError,
    required this.onTap,
  });

  final String texto;
  final IconData icono;
  final bool activa;
  final bool conError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color colorContenido = activa ? AppColores.sobrePrimario : AppColores.primario;
    Color colorBorde = conError ? AppColores.error : AppColores.borde;
    if (activa) colorBorde = AppColores.primario;
    return Semantics(
      selected: activa,
      button: true,
      child: Material(
        color: activa ? AppColores.primario : AppColores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
          side: BorderSide(color: colorBorde, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                Icon(icono, color: activa ? AppColores.acento : AppColores.primario),
                const SizedBox(height: 4),
                Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTexto.cuerpo(size: 13, color: colorContenido, peso: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
