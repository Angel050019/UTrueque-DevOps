import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/aviso_pantalla.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/publicacion.dart';
import '../avisos_publicaciones.dart';
import '../cubit/mis_publicaciones_cubit.dart';
import '../cubit/mis_publicaciones_state.dart';
import '../mis_publicaciones_keys.dart';
import '../widgets/hoja_gestionar_publicacion.dart';
import '../widgets/tarjeta_publicacion.dart';
import 'detalle_publicacion_page.dart';

/// "Mis publicaciones" (HU-06, issue #1). Se abre desde "Mi perfil".
///
/// Dos pestañas: Activas (Disponibles y Reservadas) y Finalizadas
/// (Vendidas, el historial). Scroll infinito, "jalar para actualizar" y
/// estados de carga, vacío, error y sin conexión. Cada publicación activa
/// tiene "Gestionar" (Reservar, Volver a Disponible, Vender, Editar y
/// Borrar); al tocar la tarjeta se abre su detalle.
///
/// Solo dibuja el estado del [MisPublicacionesCubit].
class MisPublicacionesPage extends StatefulWidget {
  const MisPublicacionesPage({super.key});

  @override
  State<MisPublicacionesPage> createState() => _MisPublicacionesPageState();
}

class _MisPublicacionesPageState extends State<MisPublicacionesPage> {
  /// Cuánto falta para el final de la lista para pedir la siguiente página.
  static const double _distanciaParaCargarMas = 400;

  StreamSubscription<CambioPublicacion>? _cambios;

  @override
  void initState() {
    super.initState();
    // Escenario 14: si una publicación cambia (aquí, en el Detalle o al
    // editar), la lista se actualiza sola.
    final MisPublicacionesCubit cubit = context.read<MisPublicacionesCubit>();
    _cambios = context
        .read<AvisosPublicaciones>()
        .cambios
        .listen((cambio) => cubit.sincronizar(cambio.id, cambio.publicacion));
  }

  @override
  void dispose() {
    _cambios?.cancel();
    super.dispose();
  }

  void _abrirDetalle(BuildContext context, Publicacion publicacion) {
    DetallePublicacionPage.abrir(
      context,
      id: publicacion.id,
      alCambiar: context.read<MisPublicacionesCubit>().sincronizar,
    );
  }

  Future<void> _publicar(BuildContext context) async {
    final MisPublicacionesCubit cubit = context.read<MisPublicacionesCubit>();
    await Navigator.of(context).pushNamed(AppRoutes.publicarArticulo);
    // Al regresar se recarga por si publicó algo.
    await cubit.actualizar();
  }

  void _escuchar(BuildContext context, MisPublicacionesState state) {
    if (state is MisPublicacionesCargado && state.aviso != null) {
      mostrarMensaje(context, state.aviso!, esError: true);
      context.read<MisPublicacionesCubit>().avisoMostrado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MisPublicacionesCubit cubit = context.read<MisPublicacionesCubit>();
    return Scaffold(
      key: MisPublicacionesKeys.pantalla,
      body: SafeArea(
        child: BlocConsumer<MisPublicacionesCubit, MisPublicacionesState>(
          listener: _escuchar,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BarraSuperior(titulo: 'Mis publicaciones'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 4, AppMedidas.margen, 12),
                  child: _Pestanas(
                    finalizadas: state.finalizadas,
                    onCambiar: (finalizadas) => cubit.cambiarPestana(finalizadas: finalizadas),
                  ),
                ),
                Expanded(child: _contenido(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, MisPublicacionesState state) {
    final MisPublicacionesCubit cubit = context.read<MisPublicacionesCubit>();
    const EdgeInsets margen = EdgeInsets.fromLTRB(AppMedidas.margen, 24, AppMedidas.margen, 24);
    if (state is MisPublicacionesError) {
      // TODO(diseño): ilustración de error y de sin conexión.
      return RefreshIndicator(
        color: AppColores.primario,
        onRefresh: cubit.actualizar,
        child: AvisoPantalla(
          key: MisPublicacionesKeys.error,
          icono: state.sinConexion ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
          titulo: 'No pudimos cargar tus publicaciones',
          texto: state.mensaje,
          margen: margen,
          accion: PrimaryButton(
            key: MisPublicacionesKeys.reintentarBoton,
            texto: 'Reintentar',
            onPressed: cubit.cargar,
          ),
        ),
      );
    }
    if (state is MisPublicacionesVacio) {
      // TODO(diseño): ilustración de "Mis publicaciones" vacía.
      return RefreshIndicator(
        color: AppColores.primario,
        onRefresh: cubit.actualizar,
        child: AvisoPantalla(
          key: MisPublicacionesKeys.vacio,
          icono: state.finalizadas ? Icons.history_rounded : Icons.inventory_2_outlined,
          titulo: state.mensaje,
          texto: state.finalizadas
              ? 'Aquí verás los artículos que marques como Vendidos.'
              : 'Publica un artículo para que tus compañeros lo vean.',
          margen: margen,
          accion: state.finalizadas
              ? null
              : PrimaryButton(
                  key: MisPublicacionesKeys.publicarBoton,
                  texto: 'Publicar artículo',
                  onPressed: () => _publicar(context),
                ),
        ),
      );
    }
    if (state is MisPublicacionesCargado) {
      return RefreshIndicator(
        color: AppColores.primario,
        onRefresh: cubit.actualizar,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notificacion) {
            if (notificacion.metrics.extentAfter < _distanciaParaCargarMas) {
              cubit.cargarMas();
            }
            return false;
          },
          child: ListView.separated(
            key: MisPublicacionesKeys.lista,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 0, AppMedidas.margen, 24),
            // Una fila extra al final: cargando más, error o fin de la lista.
            itemCount: state.publicaciones.length + 1,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == state.publicaciones.length) {
                return _FinDeLista(state: state, onReintentar: cubit.cargarMas);
              }
              final Publicacion publicacion = state.publicaciones[i];
              return _MiPublicacion(
                publicacion: publicacion,
                onAbrir: () => _abrirDetalle(context, publicacion),
                onGestionar: () => gestionarPublicacion(context, publicacion),
              );
            },
          ),
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(
        key: MisPublicacionesKeys.cargando,
        color: AppColores.primario,
      ),
    );
  }
}

/// Pestañas Activas / Finalizadas.
// TODO(diseño): pestañas según Figma.
class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.finalizadas, required this.onCambiar});

  final bool finalizadas;
  final ValueChanged<bool> onCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColores.primarioSuave,
        borderRadius: BorderRadius.circular(AppMedidas.radioBoton),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Pestana(
              key: MisPublicacionesKeys.activasTab,
              texto: 'Activas',
              activa: !finalizadas,
              onTap: () => onCambiar(false),
            ),
          ),
          Expanded(
            child: _Pestana(
              key: MisPublicacionesKeys.finalizadasTab,
              texto: 'Finalizadas',
              activa: finalizadas,
              onTap: () => onCambiar(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({super.key, required this.texto, required this.activa, required this.onTap});

  final String texto;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activa ? AppColores.primario : Colors.transparent,
      borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: AppTexto.subtitulo(
              size: 14,
              color: activa ? AppColores.sobrePrimario : AppColores.primario,
            ),
          ),
        ),
      ),
    );
  }
}

/// Una publicación propia: la tarjeta y, si no está finalizada, el botón
/// "Gestionar".
// TODO(diseño): tarjeta de "Mis publicaciones" según Figma.
class _MiPublicacion extends StatelessWidget {
  const _MiPublicacion({
    required this.publicacion,
    required this.onAbrir,
    required this.onGestionar,
  });

  final Publicacion publicacion;
  final VoidCallback onAbrir;
  final VoidCallback onGestionar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TarjetaPublicacion(publicacion: publicacion, onTap: onAbrir),
        if (!publicacion.estado.esFinal)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: MisPublicacionesKeys.gestionar(publicacion.id),
              onPressed: onGestionar,
              style: TextButton.styleFrom(
                foregroundColor: AppColores.primario,
                textStyle: AppTexto.subtitulo(size: 14),
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Gestionar'),
            ),
          ),
      ],
    );
  }
}

/// Lo que se ve al final de la lista: cargando más, error o fin.
class _FinDeLista extends StatelessWidget {
  const _FinDeLista({required this.state, required this.onReintentar});

  final MisPublicacionesCargado state;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final String? error = state.errorMas;
    if (error != null) {
      return Padding(
        key: MisPublicacionesKeys.errorMas,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(error, textAlign: TextAlign.center, style: AppTexto.cuerpo(size: 13)),
            TextButton(
              key: MisPublicacionesKeys.reintentarMasBoton,
              onPressed: onReintentar,
              style: TextButton.styleFrom(foregroundColor: AppColores.primario),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (state.hayMas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              key: MisPublicacionesKeys.cargandoMas,
              strokeWidth: 2.5,
              color: AppColores.primario,
            ),
          ),
        ),
      );
    }
    return const SizedBox(key: MisPublicacionesKeys.finDeLista, height: 8);
  }
}
