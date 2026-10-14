import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/usuario.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../perfil/domain/entities/perfil.dart';
import '../../../perfil/domain/repositories/perfil_repository.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import '../../../publicaciones/presentation/pages/detalle_publicacion_page.dart';
import '../../../publicaciones/presentation/widgets/tarjeta_publicacion.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../feed_keys.dart';

/// Feed principal (HU-04).
///
/// Arriba: saludo, acceso a "Mi perfil", buscador y filtros (estos dos
/// todavía sin funcionar: llegan en el Sprint 5, HU-05). Abajo: la lista
/// de publicaciones con scroll infinito, "jalar para actualizar" y sus
/// estados de carga, vacío, error y sin conexión. Al tocar una tarjeta se
/// abre su detalle.
///
/// Solo dibuja el estado del [FeedCubit]; la lógica vive en el Cubit y en
/// los casos de uso.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const List<String> _filtros = ['Todo', 'Libros', 'Calculadoras', 'Batas'];

  /// Perfil del estudiante (nombre y foto). Mientras carga es null.
  Perfil? _perfil;

  /// Evita mostrar el correo un instante antes de que llegue el nombre.
  bool _cargado = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final Perfil perfil = await context.read<PerfilRepository>().obtenerPerfilPropio();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Si falla (por ejemplo, sin internet) se usa el correo como respaldo.
    } finally {
      if (mounted) setState(() => _cargado = true);
    }
  }

  Future<void> _irAMiPerfil() async {
    await Navigator.of(context).pushNamed(AppRoutes.miPerfil);
    // Al regresar se recarga por si el estudiante editó su nombre o foto.
    await _cargarPerfil();
  }

  @override
  Widget build(BuildContext context) {
    final Usuario? usuario = context.read<AuthRepository>().usuarioActual;
    final String nombre = _primerNombre(_perfil?.nombreMostrar, usuario);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: FeedKeys.publicarBoton,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.publicarArticulo),
        backgroundColor: AppColores.primario,
        foregroundColor: AppColores.sobrePrimario,
        icon: const Icon(Icons.add_rounded, color: AppColores.acento),
        label: Text('Publicar', style: AppTexto.subtitulo(size: 15, color: AppColores.sobrePrimario)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_cargado ? 'Hola, $nombre' : 'Hola', style: AppTexto.titulo(size: 24)),
                        Text('¿Qué necesitas hoy?', style: AppTexto.cuerpo(size: 14)),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Mi perfil',
                    child: InkWell(
                      key: FeedKeys.miPerfilBoton,
                      customBorder: const CircleBorder(),
                      onTap: _irAMiPerfil,
                      child: AvatarPerfil(
                        fotoUrl: _perfil?.fotoUrl,
                        nombre: _perfil?.nombreMostrar ?? nombre,
                        radio: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // TODO(diseño): buscador. Funciona hasta el Sprint 5 (HU-05).
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColores.superficie,
                  borderRadius: BorderRadius.circular(AppMedidas.radioBoton),
                  border: Border.all(color: AppColores.borde),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColores.textoSecundario),
                    const SizedBox(width: 10),
                    Text('Busca libros, calculadoras, batas…', style: AppTexto.cuerpo()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // TODO(diseño): filtros. Funcionan hasta el Sprint 5 (HU-05).
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final String filtro in _filtros)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _Filtro(texto: filtro, activo: filtro == _filtros.first),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Publicaciones recientes', style: AppTexto.subtitulo(size: 17)),
              const SizedBox(height: 10),
              const Expanded(child: _ListaFeed()),
            ],
          ),
        ),
      ),
    );
  }

  /// Primer nombre del perfil; si aún no carga, el del usuario o el correo.
  static String _primerNombre(String? nombrePerfil, Usuario? usuario) {
    for (final String? nombre in [nombrePerfil, usuario?.nombreMostrar]) {
      if (nombre != null && nombre.trim().isNotEmpty) {
        return nombre.trim().split(RegExp(r'\s+')).first;
      }
    }
    final String correo = usuario?.correo ?? '';
    return correo.contains('@') ? correo.split('@').first : 'estudiante';
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({required this.texto, required this.activo});

  final String texto;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? AppColores.primario : AppColores.superficie,
        borderRadius: BorderRadius.circular(999),
        border: activo ? null : Border.all(color: AppColores.borde),
      ),
      child: Text(
        texto,
        style: AppTexto.cuerpo(
          size: 13,
          peso: FontWeight.w500,
          color: activo ? AppColores.sobrePrimario : AppColores.texto,
        ),
      ),
    );
  }
}

/// Lista del Feed con sus estados (HU-04, Escenarios 1 a 6).
class _ListaFeed extends StatelessWidget {
  const _ListaFeed();

  /// Cuando quedan menos de estos píxeles por recorrer se pide la
  /// siguiente página, así el estudiante casi nunca ve el spinner.
  static const double _distanciaParaCargarMas = 400;

  void _abrirDetalle(BuildContext context, Publicacion publicacion) {
    DetallePublicacionPage.abrir(
      context,
      id: publicacion.id,
      // Si al verla resulta que se vendió o se borró, se quita del Feed.
      alCambiar: context.read<FeedCubit>().sincronizar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FeedCubit cubit = context.read<FeedCubit>();
    return BlocConsumer<FeedCubit, FeedState>(
      listenWhen: (anterior, actual) =>
          actual is FeedCargado &&
          actual.aviso != null &&
          (anterior is! FeedCargado || anterior.aviso != actual.aviso),
      listener: (context, state) {
        final String? aviso = state is FeedCargado ? state.aviso : null;
        if (aviso == null) return;
        mostrarMensaje(context, aviso, esError: true);
        cubit.avisoMostrado();
      },
      builder: (context, state) {
        if (state is FeedError) {
          return _Aviso(
            key: FeedKeys.error,
            icono: state.sinConexion ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            titulo: state.sinConexion ? 'Sin conexión' : 'Algo salió mal',
            texto: state.mensaje,
            accion: PrimaryButton(
              key: FeedKeys.reintentarBoton,
              texto: 'Reintentar',
              onPressed: cubit.cargar,
            ),
          );
        }
        if (state is FeedVacio) {
          // TODO(diseño): ilustración del Feed vacío.
          return RefreshIndicator(
            color: AppColores.primario,
            onRefresh: cubit.actualizar,
            child: const _Aviso(
              key: FeedKeys.vacio,
              icono: Icons.swap_horiz_rounded,
              titulo: 'Aún no hay publicaciones',
              texto: '¡Sé el primero en publicar!',
            ),
          );
        }
        if (state is FeedCargado) {
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
                key: FeedKeys.lista,
                physics: const AlwaysScrollableScrollPhysics(),
                // Espacio abajo para que el botón "Publicar" no tape la última.
                padding: const EdgeInsets.only(bottom: 88),
                // Una fila extra al final: cargando más, error o fin de la lista.
                itemCount: state.publicaciones.length + 1,
                separatorBuilder: (context, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i == state.publicaciones.length) {
                    return _FinDeLista(state: state, onReintentar: cubit.cargarMas);
                  }
                  final Publicacion publicacion = state.publicaciones[i];
                  return TarjetaPublicacion(
                    publicacion: publicacion,
                    onTap: () => _abrirDetalle(context, publicacion),
                  );
                },
              ),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(
            key: FeedKeys.cargando,
            color: AppColores.primario,
          ),
        );
      },
    );
  }
}

/// Última fila de la lista: spinner mientras carga la siguiente página,
/// error con botón para reintentar o "Ya viste todas las publicaciones."
class _FinDeLista extends StatelessWidget {
  const _FinDeLista({required this.state, required this.onReintentar});

  final FeedCargado state;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final String? error = state.errorMas;
    if (error != null) {
      return Padding(
        key: FeedKeys.errorMas,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(error, textAlign: TextAlign.center, style: AppTexto.cuerpo(size: 13)),
            TextButton(
              key: FeedKeys.reintentarMasBoton,
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
              key: FeedKeys.cargandoMas,
              strokeWidth: 2.5,
              color: AppColores.primario,
            ),
          ),
        ),
      );
    }
    return Padding(
      key: FeedKeys.finDeLista,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Ya viste todas las publicaciones.',
        textAlign: TextAlign.center,
        style: AppTexto.cuerpo(size: 13),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    // Es una lista para que "jalar para actualizar" también funcione aquí.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 88),
      children: [
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: AppColores.primarioSuave,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 52, color: AppColores.primario),
          ),
        ),
        const SizedBox(height: 16),
        Text(titulo, textAlign: TextAlign.center, style: AppTexto.subtitulo(size: 18)),
        const SizedBox(height: 8),
        Text(texto, textAlign: TextAlign.center, style: AppTexto.cuerpo(size: 14)),
        if (accion != null) ...[const SizedBox(height: 20), accion!],
      ],
    );
  }
}
