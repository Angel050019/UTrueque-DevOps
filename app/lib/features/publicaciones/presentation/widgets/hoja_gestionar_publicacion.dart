import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/repositories/publicacion_repository.dart';
import '../../domain/usecases/borrar_publicacion.dart';
import '../../domain/usecases/cambiar_estado_publicacion.dart';
import '../../domain/usecases/obtener_detalle_publicacion.dart';
import '../avisos_publicaciones.dart';
import '../cubit/gestionar_publicacion_cubit.dart';
import '../cubit/gestionar_publicacion_state.dart';
import '../mis_publicaciones_keys.dart';
import '../pages/publicar_articulo_page.dart';
import 'etiqueta_publicacion.dart';

/// Qué pasó al gestionar una publicación (HU-06).
enum ResultadoGestion { cambioEstado, editada, borrada }

/// Lo que regresa la hoja al cerrarse.
class _Salida {
  const _Salida.resultado(ResultadoGestion this.resultado) : editar = null;
  const _Salida.editar(Publicacion this.editar) : resultado = null;

  final ResultadoGestion? resultado;
  final Publicacion? editar;
}

/// HU-06: abre la hoja "Gestionar publicación" de una publicación propia
/// (desde el Detalle o desde "Mis publicaciones").
///
/// Ofrece solo lo que permite su estado (patrón State): Reservar, Volver a
/// Disponible, Marcar como Vendido (con confirmación), Editar y Borrar (con
/// confirmación). Si el estudiante elige "Editar", abre "Editar
/// publicación". Avisa del cambio al Feed y a "Mis publicaciones" con
/// [AvisosPublicaciones].
///
/// Devuelve qué pasó, o `null` si el estudiante cerró sin hacer nada.
Future<ResultadoGestion?> gestionarPublicacion(BuildContext context, Publicacion publicacion) async {
  final PublicacionRepository repositorio = context.read<PublicacionRepository>();
  final NetworkInfo red = context.read<NetworkInfo>();
  final _Salida? salida = await showModalBottomSheet<_Salida>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColores.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppMedidas.radioTarjeta)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => GestionarPublicacionCubit(
        publicacion: publicacion,
        cambiarEstado: CambiarEstadoPublicacion(repositorio, red),
        borrarPublicacion: BorrarPublicacion(repositorio, red),
        obtenerDetalle: ObtenerDetallePublicacion(repositorio, red),
      ),
      child: const _HojaGestionar(),
    ),
  );
  if (salida == null) return null;
  final Publicacion? aEditar = salida.editar;
  if (aEditar == null) return salida.resultado;
  if (!context.mounted) return null;
  final Publicacion? editada = await PublicarArticuloPage.editar(context, aEditar);
  return editada == null ? null : ResultadoGestion.editada;
}

/// Contenido de la hoja. Solo dibuja el estado del
/// [GestionarPublicacionCubit].
// TODO(diseño): hoja "Gestionar publicación" según Figma.
class _HojaGestionar extends StatelessWidget {
  const _HojaGestionar();

  Future<void> _escuchar(BuildContext context, GestionState state) async {
    final GestionarPublicacionCubit cubit = context.read<GestionarPublicacionCubit>();
    if (state is GestionConfirmando) {
      final bool confirmado = await _confirmar(context, state.operacion);
      if (confirmado) {
        await cubit.confirmar();
      } else {
        cubit.cancelar();
      }
    } else if (state is GestionTerminada) {
      // Escenario 14: el Feed y "Mis publicaciones" se actualizan.
      context.read<AvisosPublicaciones>().avisar(state.publicacion.id, state.actualizada);
      mostrarMensaje(context, state.mensaje);
      Navigator.of(context).pop(_Salida.resultado(
        state.operacion == OperacionGestion.borrar
            ? ResultadoGestion.borrada
            : ResultadoGestion.cambioEstado,
      ));
    } else if (state is GestionError) {
      mostrarMensaje(context, state.mensaje, esError: true);
      cubit.descartarError();
    }
  }

  /// Escenarios 5 y 8: confirmación antes de Vender o Borrar.
  static Future<bool> _confirmar(BuildContext context, OperacionGestion operacion) async {
    final bool? respuesta = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        key: GestionarKeys.confirmacion,
        title: Text(operacion.tituloConfirmacion, style: AppTexto.subtitulo(size: 18)),
        content: Text(operacion.textoConfirmacion, style: AppTexto.cuerpo(size: 14)),
        actions: [
          TextButton(
            key: GestionarKeys.cancelarBoton,
            onPressed: () => Navigator.of(dialogo).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColores.textoSecundario),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: GestionarKeys.confirmarBoton,
            onPressed: () => Navigator.of(dialogo).pop(true),
            style: TextButton.styleFrom(
              foregroundColor:
                  operacion == OperacionGestion.borrar ? AppColores.error : AppColores.primario,
            ),
            child: Text(operacion.botonConfirmacion),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GestionarPublicacionCubit, GestionState>(
      listener: _escuchar,
      builder: (context, state) {
        final GestionarPublicacionCubit cubit = context.read<GestionarPublicacionCubit>();
        final Publicacion publicacion = state.publicacion;
        final bool ocupado = state is GestionEnviando || state is GestionConfirmando;
        final List<OperacionGestion> operaciones = state.operaciones;
        return SafeArea(
          top: false,
          child: Padding(
            key: GestionarKeys.hoja,
            padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 12, AppMedidas.margen, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColores.borde,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Gestionar publicación', style: AppTexto.subtitulo(size: 18)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        publicacion.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTexto.cuerpo(size: 14, color: AppColores.texto),
                      ),
                    ),
                    const SizedBox(width: 8),
                    EtiquetaPublicacion.estado(publicacion.estado, key: GestionarKeys.estado),
                  ],
                ),
                const SizedBox(height: 16),
                if (state is GestionEnviando) ...[
                  const LinearProgressIndicator(
                    key: GestionarKeys.enviando,
                    color: AppColores.primario,
                    backgroundColor: AppColores.primarioSuave,
                  ),
                  const SizedBox(height: 16),
                ],
                if (publicacion.estado.esFinal)
                  Container(
                    key: GestionarKeys.finalizadaAviso,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColores.primarioSuave,
                      borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                    ),
                    child: Text(
                      'Esta publicación ya está finalizada. Ya no se puede cambiar su '
                      'estado ni editar.',
                      style: AppTexto.cuerpo(size: 14, color: AppColores.primario),
                    ),
                  ),
                for (final OperacionGestion operacion in operaciones)
                  if (operacion != OperacionGestion.borrar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: operacion == OperacionGestion.marcarVendido
                          ? PrimaryButton(
                              key: GestionarKeys.operacion(operacion),
                              texto: operacion.etiqueta,
                              onPressed: ocupado ? null : () => cubit.elegir(operacion),
                            )
                          : SecondaryButton(
                              key: GestionarKeys.operacion(operacion),
                              texto: operacion.etiqueta,
                              onPressed: ocupado ? null : () => cubit.elegir(operacion),
                            ),
                    ),
                if (state.sePuedeEditar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SecondaryButton(
                      key: GestionarKeys.editarBoton,
                      texto: 'Editar publicación',
                      onPressed: ocupado
                          ? null
                          : () => Navigator.of(context).pop(_Salida.editar(publicacion)),
                    ),
                  ),
                if (operaciones.contains(OperacionGestion.borrar))
                  TextButton.icon(
                    key: GestionarKeys.operacion(OperacionGestion.borrar),
                    onPressed: ocupado ? null : () => cubit.elegir(OperacionGestion.borrar),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColores.error,
                      textStyle: AppTexto.subtitulo(size: 15),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: Text(OperacionGestion.borrar.etiqueta),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
