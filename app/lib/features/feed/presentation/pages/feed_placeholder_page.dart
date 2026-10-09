import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/en_desarrollo_page.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/usuario.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../perfil/domain/entities/perfil.dart';
import '../../../perfil/domain/repositories/perfil_repository.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import '../../../publicaciones/presentation/cubit/publicaciones_recientes_cubit.dart';
import '../../../publicaciones/presentation/publicacion_keys.dart';
import '../../../publicaciones/presentation/widgets/tarjeta_publicacion.dart';

/// Placeholder temporal del Feed principal.
/// El Feed real (HU-05) llega en un sprint posterior; por ahora muestra el
/// saludo, el buscador y los filtros (sin funcionalidad), da acceso a
/// "Mi perfil" desde el avatar y, desde HU-03, la lista sencilla de
/// "Publicaciones recientes" ([PublicacionesRecientesCubit]).
class FeedPlaceholderPage extends StatefulWidget {
  const FeedPlaceholderPage({super.key});

  @override
  State<FeedPlaceholderPage> createState() => _FeedPlaceholderPageState();
}

class _FeedPlaceholderPageState extends State<FeedPlaceholderPage> {
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
      // HU-03: acceso a "Publicar artículo".
      floatingActionButton: FloatingActionButton.extended(
        key: PublicacionKeys.feedPublicarBoton,
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
                      key: const Key('feed_mi_perfil_boton'),
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
              const Expanded(child: _PublicacionesRecientes()),
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

/// Lista de publicaciones recientes con sus estados de carga, vacío y error.
class _PublicacionesRecientes extends StatelessWidget {
  const _PublicacionesRecientes();

  @override
  Widget build(BuildContext context) {
    final PublicacionesRecientesCubit cubit = context.read<PublicacionesRecientesCubit>();
    return BlocBuilder<PublicacionesRecientesCubit, RecientesState>(
      builder: (context, state) {
        if (state is RecientesError) {
          return _Aviso(
            key: PublicacionKeys.feedError,
            icono: Icons.cloud_off_rounded,
            titulo: 'No pudimos cargar las publicaciones',
            texto: state.mensaje,
            accion: PrimaryButton(
              key: PublicacionKeys.feedReintentarBoton,
              texto: 'Reintentar',
              onPressed: cubit.cargar,
            ),
          );
        }
        if (state is RecientesCargadas) {
          if (state.publicaciones.isEmpty) {
            return const _Aviso(
              key: PublicacionKeys.feedVacio,
              icono: Icons.swap_horiz_rounded,
              titulo: 'Aún no hay publicaciones',
              texto: 'Toca "Publicar" para ofrecer el primer artículo a tus compañeros.',
            );
          }
          return RefreshIndicator(
            color: AppColores.primario,
            onRefresh: cubit.cargar,
            child: ListView.separated(
              key: PublicacionKeys.feedLista,
              // Espacio abajo para que el botón "Publicar" no tape la última.
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: state.publicaciones.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final Publicacion publicacion = state.publicaciones[i];
                return TarjetaPublicacion(
                  publicacion: publicacion,
                  onTap: () => EnDesarrolloPage.abrir(
                    context,
                    titulo: 'Detalle de la publicación',
                    mensaje: 'Muy pronto podrás ver todas las fotos de "${publicacion.titulo}", '
                        'su descripción completa y contactar a quien lo publica.',
                    sprint: 'Sprint 4',
                  ),
                );
              },
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(
            key: PublicacionKeys.feedCargando,
            color: AppColores.primario,
          ),
        );
      },
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
    return ListView(
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
