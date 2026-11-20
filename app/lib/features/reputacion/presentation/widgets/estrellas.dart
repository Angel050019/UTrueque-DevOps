import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/reputacion.dart';
import '../../domain/repositories/reputacion_repository.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';
import '../cubit/reputacion_cubit.dart';
import '../reputacion_keys.dart';

/// Cinco estrellas: [llenas] pintadas y el resto vacías (HU-09).
// TODO(diseño): estrellas según Figma (ver docs/Sprint9_Guia_Diseno.md).
class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.llenas, this.tamano = 16, this.claro = false});

  final int llenas;
  final double tamano;

  /// true sobre fondo oscuro (encabezado del chat).
  final bool claro;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$llenas de 5 estrellas',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 1; i <= 5; i++)
              Icon(
                i <= llenas ? Icons.star_rounded : Icons.star_outline_rounded,
                size: tamano,
                color: i <= llenas
                    ? AppColores.estrella
                    : (claro ? AppColores.primarioSuave : AppColores.borde),
              ),
          ],
        ),
      ),
    );
  }
}

/// Selector de 1 a 5 estrellas de la hoja "Calificar" (Escenarios 3 y 4).
class SelectorEstrellas extends StatelessWidget {
  const SelectorEstrellas({super.key, required this.elegidas, required this.onElegir});

  final int? elegidas;
  final ValueChanged<int>? onElegir;

  /// Texto debajo de las estrellas.
  static String etiqueta(int? estrellas) => switch (estrellas) {
        1 => 'Malo',
        2 => 'Regular',
        3 => 'Bueno',
        4 => 'Muy bueno',
        5 => 'Excelente',
        _ => 'Toca una estrella',
      };

  @override
  Widget build(BuildContext context) {
    final int actuales = elegidas ?? 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 1; i <= 5; i++)
              IconButton(
                key: ReputacionKeys.estrella(i),
                tooltip: '$i ${i == 1 ? 'estrella' : 'estrellas'}',
                iconSize: 40,
                onPressed: onElegir == null ? null : () => onElegir!(i),
                icon: Icon(
                  i <= actuales ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i <= actuales ? AppColores.estrella : AppColores.borde,
                ),
              ),
          ],
        ),
        Text(etiqueta(elegidas), style: AppTexto.subtitulo(size: 15, color: AppColores.textoSecundario)),
      ],
    );
  }
}

/// La reputación en una línea: "★★★★☆ 4.3 · 2 calificaciones", o "Nuevo en
/// UTrueque · Sin calificaciones aún" (Escenarios 6, 7 y 8).
class EtiquetaReputacion extends StatelessWidget {
  const EtiquetaReputacion({super.key, required this.reputacion, this.claro = false});

  final Reputacion reputacion;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final Color color = claro ? AppColores.primarioSuave : AppColores.textoSecundario;
    if (reputacion.sinCalificaciones) {
      return Row(
        key: ReputacionKeys.sinCalificaciones,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: claro ? AppColores.acento : AppColores.primario),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              Reputacion.textoSinCalificaciones,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTexto.cuerpo(size: 12, color: color),
            ),
          ),
        ],
      );
    }
    return Row(
      key: ReputacionKeys.etiqueta,
      mainAxisSize: MainAxisSize.min,
      children: [
        Estrellas(llenas: reputacion.estrellasLlenas, tamano: 14, claro: claro),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            reputacion.texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTexto.cuerpo(size: 12, color: color, peso: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Carga y muestra la reputación de [usuarioId] en una línea. La usan el
/// Detalle de la publicación y el encabezado del chat. Si no se puede
/// cargar no muestra nada: no impide usar la pantalla.
class ReputacionDe extends StatelessWidget {
  const ReputacionDe({super.key, required this.usuarioId, this.claro = false});

  final String usuarioId;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey<String>('reputacion_de_$usuarioId'),
      create: (ctx) => ReputacionCubit(
        obtenerReputacion: ObtenerReputacion(ctx.read<ReputacionRepository>(), ctx.read<NetworkInfo>()),
        usuarioId: usuarioId,
      )..cargar(),
      child: BlocBuilder<ReputacionCubit, ReputacionState>(
        builder: (context, state) {
          if (state is ReputacionLista) return EtiquetaReputacion(reputacion: state.reputacion, claro: claro);
          return const SizedBox(height: 16);
        },
      ),
    );
  }
}
