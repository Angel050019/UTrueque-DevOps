import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/aviso_pantalla.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/conversacion.dart';
import '../chat_keys.dart';
import '../cubit/bandeja_cubit.dart';
import '../cubit/bandeja_state.dart';
import '../widgets/globo_no_leidos.dart';
import 'chat_page.dart';

/// Bandeja "Mensajes" (HU-07, Escenario 7). Se abre con el ícono de
/// mensajes del Feed. La conversación más reciente va primero y se mueve
/// sola cuando llega un mensaje (patrón Observer).
///
/// Solo dibuja el estado del [BandejaCubit].
class BandejaPage extends StatelessWidget {
  const BandejaPage({super.key});

  Future<void> _abrir(BuildContext context, Conversacion conversacion) async {
    final BandejaCubit cubit = context.read<BandejaCubit>()..marcarLeida(conversacion.id);
    await ChatPage.abrir(context, conversacion);
    await cubit.actualizar();
  }

  void _escuchar(BuildContext context, BandejaState state) {
    if (state is BandejaCargada && state.aviso != null) {
      mostrarMensaje(context, state.aviso!, esError: true);
      context.read<BandejaCubit>().avisoMostrado();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: BandejaKeys.pantalla,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarraSuperior(titulo: 'Mensajes'),
            Expanded(
              child: BlocConsumer<BandejaCubit, BandejaState>(
                listener: _escuchar,
                builder: (context, state) => _contenido(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, BandejaState state) {
    final BandejaCubit cubit = context.read<BandejaCubit>();
    const EdgeInsets margen = EdgeInsets.fromLTRB(AppMedidas.margen, 24, AppMedidas.margen, 24);
    if (state is BandejaError) {
      return RefreshIndicator(
        color: AppColores.primario,
        onRefresh: cubit.actualizar,
        child: AvisoPantalla(
          key: BandejaKeys.error,
          icono: state.sinConexion ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
          titulo: 'No pudimos cargar tus mensajes',
          texto: state.mensaje,
          margen: margen,
          accion: PrimaryButton(key: BandejaKeys.reintentarBoton, texto: 'Reintentar', onPressed: cubit.cargar),
        ),
      );
    }
    if (state is BandejaVacia) {
      // TODO(diseño): ilustración de bandeja vacía.
      return RefreshIndicator(
        color: AppColores.primario,
        onRefresh: cubit.actualizar,
        child: const AvisoPantalla(
          key: BandejaKeys.vacia,
          icono: Icons.chat_bubble_outline_rounded,
          titulo: BandejaVacia.mensaje,
          texto: 'Cuando contactes a un vendedor o alguien te escriba, la conversación aparecerá aquí.',
          margen: margen,
        ),
      );
    }
    if (state is BandejaCargada) {
      return RefreshIndicator(
        color: AppColores.primario,
        onRefresh: cubit.actualizar,
        child: ListView.separated(
          key: BandejaKeys.lista,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.conversaciones.length,
          separatorBuilder: (context, _) => const Divider(height: 1, indent: 84, color: AppColores.borde),
          itemBuilder: (context, i) {
            final Conversacion conversacion = state.conversaciones[i];
            return _FilaConversacion(
              conversacion: conversacion,
              miId: cubit.miId,
              onTap: () => _abrir(context, conversacion),
            );
          },
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(key: BandejaKeys.cargando, color: AppColores.primario));
  }
}

/// Una conversación: foto y título de la publicación, el otro estudiante,
/// el último mensaje, la fecha y los no leídos.
// TODO(diseño): fila de la bandeja según Figma.
class _FilaConversacion extends StatelessWidget {
  const _FilaConversacion({required this.conversacion, required this.miId, required this.onTap});

  final Conversacion conversacion;
  final String? miId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hayNoLeidos = conversacion.noLeidos > 0;
    final String? ultimo = conversacion.ultimoTexto;
    final String vistaPrevia = ultimo == null
        ? 'Sin mensajes todavía'
        : conversacion.ultimoAutorId == miId
            ? 'Tú: $ultimo'
            : ultimo;
    return InkWell(
      key: BandejaKeys.conversacion(conversacion.id),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margen, vertical: 10),
        child: Row(
          children: [
            _Portada(url: conversacion.publicacionFotoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversacion.otroNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTexto.subtitulo(size: 15),
                        ),
                      ),
                      Text(formatearMomento(conversacion.fechaOrden), style: AppTexto.cuerpo(size: 12)),
                    ],
                  ),
                  Text(
                    '${conversacion.soyVendedor ? 'Tu publicación' : 'Te interesa'}: ${conversacion.tituloVisible}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTexto.cuerpo(size: 12),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vistaPrevia,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTexto.cuerpo(
                            size: 14,
                            color: hayNoLeidos ? AppColores.texto : AppColores.textoSecundario,
                            peso: hayNoLeidos ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      GloboNoLeidos(key: BandejaKeys.noLeidos(conversacion.id), cantidad: conversacion.noLeidos),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Portada extends StatelessWidget {
  const _Portada({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const Widget sinFoto = ColoredBox(
      color: AppColores.primarioSuave,
      child: Icon(Icons.inventory_2_outlined, color: AppColores.primario),
    );
    final String? direccion = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
      child: SizedBox(
        width: 56,
        height: 56,
        child: direccion == null
            ? sinFoto
            : Image.network(direccion, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => sinFoto),
      ),
    );
  }
}
