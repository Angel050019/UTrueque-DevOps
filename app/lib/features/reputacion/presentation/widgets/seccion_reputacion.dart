import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';
import '../../domain/entities/reputacion.dart';
import '../../domain/entities/trato.dart';
import '../../domain/repositories/reputacion_repository.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';
import '../cubit/calificaciones_recibidas_cubit.dart';
import '../cubit/reputacion_cubit.dart';
import '../cubit/tratos_por_calificar_cubit.dart';
import '../reputacion_keys.dart';
import 'estrellas.dart';
import 'hoja_calificar.dart';

/// HU-09: la reputación en Mi perfil (Escenarios 3, 5, 7 y 8): el resumen,
/// los tratos que faltan por calificar y las calificaciones que recibí.
class SeccionReputacion extends StatelessWidget {
  const SeccionReputacion({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    final ReputacionRepository repositorio = context.read<ReputacionRepository>();
    final NetworkInfo red = context.read<NetworkInfo>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ReputacionCubit(
            obtenerReputacion: ObtenerReputacion(repositorio, red),
            usuarioId: usuarioId,
          )..cargar(),
        ),
        BlocProvider(create: (_) => TratosPorCalificarCubit(ObtenerTratosPorCalificar(repositorio, red))..cargar()),
        BlocProvider(
          create: (_) => CalificacionesRecibidasCubit(ObtenerCalificacionesRecibidas(repositorio, red))..cargar(),
        ),
      ],
      child: const _Contenido(),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido();

  Future<void> _calificar(BuildContext context, TratoPorCalificar trato) async {
    final TratosPorCalificarCubit tratos = context.read<TratosPorCalificarCubit>();
    final bool quitar = await HojaCalificar.abrir(context, trato);
    if (quitar) tratos.quitar(trato.ventaId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ReputacionKeys.seccion,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Resumen(),
        BlocBuilder<TratosPorCalificarCubit, TratosPorCalificarState>(
          builder: (context, state) => Column(
            children: [
              for (final TratoPorCalificar trato in state.tratos)
                AvisoCalificarTrato(trato: trato, onCalificar: () => _calificar(context, trato)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _Recibidas(),
      ],
    );
  }
}

// TODO(diseño): tarjeta "Mi reputación" según Figma.
class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
        border: Border.all(color: AppColores.borde),
      ),
      child: BlocBuilder<ReputacionCubit, ReputacionState>(
        builder: (context, state) {
          if (state is ReputacionError) {
            return Row(
              key: ReputacionKeys.resumenError,
              children: [
                Expanded(child: Text(state.mensaje, style: AppTexto.cuerpo(size: 13, color: AppColores.error))),
                TextButton(
                  key: ReputacionKeys.resumenReintentar,
                  onPressed: context.read<ReputacionCubit>().cargar,
                  child: const Text('Reintentar'),
                ),
              ],
            );
          }
          if (state is! ReputacionLista) {
            return const SizedBox(
              height: 64,
              child: Center(child: CircularProgressIndicator(color: AppColores.primario)),
            );
          }
          final Reputacion reputacion = state.reputacion;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mi reputación', style: AppTexto.subtitulo(size: 16)),
              const SizedBox(height: 10),
              if (reputacion.sinCalificaciones)
                Text(
                  Reputacion.textoSinCalificaciones,
                  key: ReputacionKeys.sinCalificaciones,
                  style: AppTexto.cuerpo(size: 14),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(reputacion.promedioTexto ?? '', key: ReputacionKeys.promedio, style: AppTexto.titulo(size: 36)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Estrellas(llenas: reputacion.estrellasLlenas, tamano: 20),
                        Text(reputacion.totalTexto, style: AppTexto.cuerpo(size: 13)),
                      ],
                    ),
                  ],
                ),
                if (reputacion.ajustada)
                  Padding(
                    key: ReputacionKeys.avisoAjustado,
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Con menos de 5 calificaciones mostramos un promedio ajustado para que sea justo.',
                      style: AppTexto.cuerpo(size: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                for (int n = 5; n >= 1; n--)
                  _Barra(
                    key: ReputacionKeys.barra(n),
                    estrellas: n,
                    cantidad: reputacion.resumen.de(n),
                    total: reputacion.total,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// "5 ★ ████░░ 3".
class _Barra extends StatelessWidget {
  const _Barra({super.key, required this.estrellas, required this.cantidad, required this.total});

  final int estrellas;
  final int cantidad;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 14, child: Text('$estrellas', style: AppTexto.cuerpo(size: 12))),
          const Icon(Icons.star_rounded, size: 14, color: AppColores.estrella),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : cantidad / total,
                minHeight: 8,
                color: AppColores.estrella,
                backgroundColor: AppColores.fondo,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text('$cantidad', textAlign: TextAlign.end, style: AppTexto.cuerpo(size: 12)),
          ),
        ],
      ),
    );
  }
}

// TODO(diseño): lista de calificaciones recibidas según Figma.
class _Recibidas extends StatelessWidget {
  const _Recibidas();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalificacionesRecibidasCubit, CalificacionesRecibidasState>(
      builder: (context, state) {
        final CalificacionesRecibidasCubit cubit = context.read<CalificacionesRecibidasCubit>();
        final List<Widget> hijos = <Widget>[
          Text('Calificaciones que recibí', style: AppTexto.subtitulo(size: 16)),
          const SizedBox(height: 8),
        ];
        if (state.cargando) {
          hijos.add(const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(color: AppColores.primario)),
          ));
        } else if (state.error != null) {
          hijos.add(Row(
            key: ReputacionKeys.recibidasError,
            children: [
              Expanded(child: Text(state.error!, style: AppTexto.cuerpo(size: 13, color: AppColores.error))),
              TextButton(onPressed: cubit.cargar, child: const Text('Reintentar')),
            ],
          ));
        } else if (state.calificaciones.isEmpty) {
          hijos.add(Text(
            'Cuando alguien califique un trato contigo, aparecerá aquí.',
            key: ReputacionKeys.recibidasVacio,
            style: AppTexto.cuerpo(size: 14),
          ));
        } else {
          for (final CalificacionRecibida c in state.calificaciones) {
            hijos.add(_TarjetaRecibida(key: ReputacionKeys.recibida(c.id), calificacion: c));
          }
          if (state.errorMas != null) {
            hijos.add(Text(state.errorMas!, style: AppTexto.cuerpo(size: 13, color: AppColores.error)));
          }
          if (state.hayMas) {
            hijos.add(TextButton(
              key: ReputacionKeys.verMas,
              onPressed: state.cargandoMas ? null : cubit.cargarMas,
              child: Text(state.cargandoMas ? 'Cargando…' : 'Ver más'),
            ));
          }
        }
        return Column(key: ReputacionKeys.recibidas, crossAxisAlignment: CrossAxisAlignment.stretch, children: hijos);
      },
    );
  }
}

class _TarjetaRecibida extends StatelessWidget {
  const _TarjetaRecibida({super.key, required this.calificacion});

  final CalificacionRecibida calificacion;

  @override
  Widget build(BuildContext context) {
    final String? comentario = calificacion.comentario;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        border: Border.all(color: AppColores.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarPerfil(fotoUrl: calificacion.autorFotoUrl, nombre: calificacion.autorNombre, radio: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(calificacion.autorNombre, style: AppTexto.subtitulo(size: 14))),
                    Text(formatearMomento(calificacion.creadaEn), style: AppTexto.cuerpo(size: 12)),
                  ],
                ),
                Estrellas(llenas: calificacion.estrellas, tamano: 14),
                Text(
                  '${calificacion.comoVendedor ? 'Le vendiste' : 'Le compraste'} "${calificacion.publicacionTitulo}"',
                  style: AppTexto.cuerpo(size: 12),
                ),
                if (comentario != null) ...[
                  const SizedBox(height: 4),
                  Text(comentario, style: AppTexto.cuerpo(size: 14, color: AppColores.texto)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
