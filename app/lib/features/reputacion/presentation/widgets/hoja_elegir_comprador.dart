import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import '../../domain/entities/trato.dart';
import '../../domain/repositories/reputacion_repository.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';
import '../cubit/elegir_comprador_cubit.dart';
import '../reputacion_keys.dart';

/// HU-09, Escenarios 1 y 2: hoja "¿A quién se lo vendiste?". Reemplaza la
/// confirmación de "Marcar como Vendido" de HU-06.
///
/// Devuelve lo que eligió el vendedor, o `null` si canceló (no se vende).
Future<EleccionVenta?> elegirComprador(BuildContext context, Publicacion publicacion) {
  final ReputacionRepository repositorio = context.read<ReputacionRepository>();
  final NetworkInfo red = context.read<NetworkInfo>();
  return showModalBottomSheet<EleccionVenta>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColores.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppMedidas.radioTarjeta)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => ElegirCompradorCubit(
        publicacionId: publicacion.id,
        obtener: ObtenerCompradoresPosibles(repositorio, red),
      )..cargar(),
      child: _HojaElegirComprador(titulo: publicacion.titulo),
    ),
  );
}

// TODO(diseño): hoja "¿A quién se lo vendiste?" según Figma.
class _HojaElegirComprador extends StatelessWidget {
  const _HojaElegirComprador({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ElegirCompradorCubit, ElegirCompradorState>(
      builder: (context, state) {
        final ElegirCompradorCubit cubit = context.read<ElegirCompradorCubit>();
        final EleccionVenta? eleccion = state.eleccion;
        return Padding(
          key: ReputacionKeys.hojaComprador,
          padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 0, AppMedidas.margen, AppMedidas.margen),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('¿A quién se lo vendiste?', style: AppTexto.titulo(size: 20)),
                const SizedBox(height: 4),
                Text(
                  'Elige con quién hiciste el trato de "$titulo". Los dos podrán calificarse durante 14 días.',
                  style: AppTexto.cuerpo(size: 14),
                ),
                const SizedBox(height: 16),
                if (state.cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(key: ReputacionKeys.compradoresCargando, color: AppColores.primario),
                    ),
                  )
                else if (state.error != null)
                  _AvisoError(mensaje: state.error!, onReintentar: cubit.cargar)
                else if (state.compradores.isEmpty)
                  Padding(
                    key: ReputacionKeys.compradoresVacio,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Nadie te ha escrito por esta publicación. Si la vendiste, elige "Lo vendí fuera de UTrueque".',
                      style: AppTexto.cuerpo(size: 14),
                    ),
                  )
                else
                  for (final CompradorPosible comprador in state.compradores)
                    _Opcion(
                      key: ReputacionKeys.comprador(comprador.conversacionId),
                      elegida: eleccion?.conversacionId == comprador.conversacionId,
                      onTap: () => cubit.elegir(comprador),
                      inicio: AvatarPerfil(fotoUrl: comprador.fotoUrl, nombre: comprador.nombre, radio: 20),
                      titulo: comprador.nombre,
                      subtitulo: comprador.ultimoMensajeEn == null
                          ? 'Te escribió por esta publicación'
                          : 'Último mensaje: ${formatearMomento(comprador.ultimoMensajeEn!)}',
                    ),
                _Opcion(
                  key: ReputacionKeys.fueraDeUTrueque,
                  elegida: eleccion?.fueraDeUTrueque ?? false,
                  onTap: cubit.elegirFueraDeUTrueque,
                  inicio: const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColores.primarioSuave,
                    child: Icon(Icons.storefront_rounded, color: AppColores.primario),
                  ),
                  titulo: 'Lo vendí fuera de UTrueque',
                  subtitulo: 'Nadie podrá calificar este trato',
                ),
                const SizedBox(height: 12),
                Text(
                  'Ya no podrás cambiar su estado ni editarla.',
                  textAlign: TextAlign.center,
                  style: AppTexto.cuerpo(size: 13),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  key: ReputacionKeys.confirmarVenta,
                  texto: 'Sí, marcar como Vendido',
                  onPressed: eleccion == null ? null : () => Navigator.of(context).pop(eleccion),
                ),
                const SizedBox(height: 4),
                TextButton(
                  key: ReputacionKeys.cancelarVenta,
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: AppColores.textoSecundario),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Una opción de la lista, con palomita si está elegida.
class _Opcion extends StatelessWidget {
  const _Opcion({
    super.key,
    required this.elegida,
    required this.onTap,
    required this.inicio,
    required this.titulo,
    required this.subtitulo,
  });

  final bool elegida;
  final VoidCallback onTap;
  final Widget inicio;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: elegida ? AppColores.primarioSuave : AppColores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
          side: BorderSide(color: elegida ? AppColores.primario : AppColores.borde, width: elegida ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                inicio,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: AppTexto.subtitulo(size: 15)),
                      Text(subtitulo, style: AppTexto.cuerpo(size: 13)),
                    ],
                  ),
                ),
                Icon(
                  elegida ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: elegida ? AppColores.primario : AppColores.borde,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  const _AvisoError({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ReputacionKeys.compradoresError,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.errorSuave,
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
      ),
      child: Row(
        children: [
          Expanded(child: Text(mensaje, style: AppTexto.cuerpo(size: 13, color: AppColores.error))),
          TextButton(
            key: ReputacionKeys.compradoresReintentar,
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
