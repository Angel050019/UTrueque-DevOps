import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/aviso_pantalla.dart';
import '../../../../core/widgets/filtros_texto.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/usuario.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../perfil/domain/entities/perfil.dart';
import '../../../perfil/domain/repositories/perfil_repository.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';
import '../../../publicaciones/domain/entities/categoria.dart';
import '../../../publicaciones/domain/entities/filtros_feed.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import '../../../publicaciones/presentation/avisos_publicaciones.dart';
import '../../../publicaciones/presentation/pages/detalle_publicacion_page.dart';
import '../../../publicaciones/presentation/widgets/tarjeta_publicacion.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../cubit/opciones_filtro.dart';
import '../feed_keys.dart';
import '../widgets/hoja_filtros.dart';

/// Feed principal (HU-04) con búsqueda y filtros (HU-05).
///
/// Arriba: saludo, acceso a "Mi perfil", buscador, botón de filtros de
/// división y carrera, y chips ("Mi carrera" y categorías). Abajo: la lista
/// de publicaciones con scroll infinito, "jalar para actualizar" y sus
/// estados de carga, vacío, sin resultados, error y sin conexión. Al tocar
/// una tarjeta se abre su detalle.
///
/// Solo dibuja el estado del [FeedCubit]; la lógica vive en el Cubit y en
/// los casos de uso.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  /// Texto del buscador (es parte de la pantalla; el Cubit decide cuándo
  /// buscar).
  final TextEditingController _busqueda = TextEditingController();

  /// Perfil del estudiante (nombre y foto). Mientras carga es null.
  Perfil? _perfil;

  /// Evita mostrar el correo un instante antes de que llegue el nombre.
  bool _cargado = false;

  /// HU-06, Escenario 14: cambios en publicaciones (reservada, vendida,
  /// editada o borrada desde "Mis publicaciones" o el Detalle).
  StreamSubscription<CambioPublicacion>? _cambios;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    final FeedCubit cubit = context.read<FeedCubit>();
    _cambios = context
        .read<AvisosPublicaciones>()
        .cambios
        .listen((cambio) => cubit.sincronizar(cambio.id, cambio.publicacion));
  }

  @override
  void dispose() {
    _cambios?.cancel();
    _busqueda.dispose();
    super.dispose();
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

  /// "Limpiar filtros" (HU-05, Escenario 7): también borra el buscador.
  void _limpiarFiltros() {
    _busqueda.clear();
    context.read<FeedCubit>().limpiarFiltros();
  }

  void _borrarBusqueda() {
    _busqueda.clear();
    context.read<FeedCubit>().buscarAhora('');
  }

  @override
  Widget build(BuildContext context) {
    final Usuario? usuario = context.read<AuthRepository>().usuarioActual;
    final String nombre = _primerNombre(_perfil?.nombreMostrar, usuario);
    final FeedCubit cubit = context.read<FeedCubit>();

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
              // TODO(diseño): buscador y botón de filtros (HU-05).
              Row(
                children: [
                  Expanded(
                    child: _Buscador(
                      controller: _busqueda,
                      onChanged: cubit.escribirBusqueda,
                      onSubmitted: cubit.buscarAhora,
                      onBorrar: _borrarBusqueda,
                    ),
                  ),
                  const SizedBox(width: 10),
                  BlocBuilder<FeedCubit, FeedState>(
                    buildWhen: (anterior, actual) =>
                        anterior.filtros.filtraPorDivisionOCarrera !=
                        actual.filtros.filtraPorDivisionOCarrera,
                    builder: (context, state) => _BotonFiltros(
                      activo: state.filtros.filtraPorDivisionOCarrera,
                      onTap: () => mostrarHojaFiltros(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // TODO(diseño): chips de "Mi carrera" y categorías (HU-05).
              BlocBuilder<FeedCubit, FeedState>(
                buildWhen: (anterior, actual) =>
                    anterior.filtros != actual.filtros || anterior.opciones != actual.opciones,
                builder: (context, state) => _ChipsFiltros(
                  filtros: state.filtros,
                  opciones: state.opciones,
                  miCarreraActiva: cubit.miCarreraActiva,
                  onMiCarrera: cubit.alternarMiCarrera,
                  onCategoria: cubit.elegirCategoria,
                  onQuitarDivisionYCarrera: () => cubit.aplicarDivisionYCarrera(),
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<FeedCubit, FeedState>(
                buildWhen: (anterior, actual) =>
                    anterior.filtros.hayFiltros != actual.filtros.hayFiltros,
                builder: (context, state) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.filtros.hayFiltros ? 'Resultados' : 'Publicaciones recientes',
                        style: AppTexto.subtitulo(size: 17),
                      ),
                    ),
                    if (state.filtros.hayFiltros)
                      TextButton(
                        key: FeedKeys.limpiarFiltrosBoton,
                        onPressed: _limpiarFiltros,
                        style: TextButton.styleFrom(foregroundColor: AppColores.primario),
                        child: const Text('Limpiar filtros'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: _ListaFeed(onLimpiarFiltros: _limpiarFiltros)),
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

/// Buscador por palabras (HU-05, Escenario 2). Busca solo al dejar de
/// escribir (eso lo decide el Cubit) o al presionar "buscar" en el teclado.
class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onBorrar,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppMedidas.radioBoton),
      borderSide: const BorderSide(color: AppColores.borde),
    );
    return TextField(
      key: FeedKeys.buscador,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      // SEGURIDAD: validación de entrada: solo letras, números y espacios, y
      // máximo 100 caracteres (la base también quita los signos y recorta).
      inputFormatters: [
        ...FiltrosTexto.busqueda,
        LengthLimitingTextInputFormatter(FiltrosFeed.maximoCaracteres),
      ],
      style: AppTexto.cuerpo(color: AppColores.texto),
      decoration: InputDecoration(
        hintText: 'Busca libros, calculadoras, batas…',
        hintStyle: AppTexto.cuerpo(),
        filled: true,
        fillColor: AppColores.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColores.textoSecundario),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, valor, _) => valor.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  key: FeedKeys.borrarBusquedaBoton,
                  tooltip: 'Borrar búsqueda',
                  icon: const Icon(Icons.close_rounded, color: AppColores.textoSecundario),
                  onPressed: onBorrar,
                ),
        ),
        border: borde,
        enabledBorder: borde,
        focusedBorder: borde.copyWith(
          borderSide: const BorderSide(color: AppColores.primario, width: 1.5),
        ),
      ),
    );
  }
}

/// Botón que abre la hoja de filtros de división y carrera. Se marca en
/// azul cuando hay uno de esos filtros puesto.
class _BotonFiltros extends StatelessWidget {
  const _BotonFiltros({required this.activo, required this.onTap});

  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Filtrar por división y carrera',
      child: Material(
        color: activo ? AppColores.primario : AppColores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMedidas.radioBoton),
          side: activo ? BorderSide.none : const BorderSide(color: AppColores.borde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: FeedKeys.filtrosBoton,
          onTap: onTap,
          child: SizedBox(
            width: 50,
            height: 50,
            child: Icon(
              Icons.tune_rounded,
              color: activo ? AppColores.acento : AppColores.primario,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chips de filtros: "Mi carrera" (si el perfil tiene carrera), la división
/// o carrera elegida en la hoja (con su "x"), "Todo" y cada categoría.
class _ChipsFiltros extends StatelessWidget {
  const _ChipsFiltros({
    required this.filtros,
    required this.opciones,
    required this.miCarreraActiva,
    required this.onMiCarrera,
    required this.onCategoria,
    required this.onQuitarDivisionYCarrera,
  });

  final FiltrosFeed filtros;
  final OpcionesFiltro opciones;
  final bool miCarreraActiva;
  final VoidCallback onMiCarrera;
  final ValueChanged<int?> onCategoria;
  final VoidCallback onQuitarDivisionYCarrera;

  /// Texto del chip de división o carrera elegida en la hoja.
  String? get _textoAcademico {
    if (!filtros.filtraPorDivisionOCarrera || miCarreraActiva) return null;
    final String? carrera = opciones.nombreCarrera(filtros.carreraId);
    if (carrera != null) return carrera;
    return opciones.nombreDivision(filtros.divisionId) ?? 'División y carrera';
  }

  @override
  Widget build(BuildContext context) {
    final String? textoAcademico = _textoAcademico;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (opciones.miCarrera != null)
            _Chip(
              key: FeedKeys.miCarreraChip,
              texto: 'Mi carrera',
              icono: Icons.school_rounded,
              activo: miCarreraActiva,
              onTap: onMiCarrera,
            ),
          if (textoAcademico != null)
            _Chip(
              key: FeedKeys.filtroAcademicoChip,
              texto: textoAcademico,
              icono: Icons.close_rounded,
              activo: true,
              onTap: onQuitarDivisionYCarrera,
            ),
          _Chip(
            key: FeedKeys.filtro('Todo'),
            texto: 'Todo',
            activo: filtros.categoriaId == null,
            onTap: () => onCategoria(null),
          ),
          for (final Categoria categoria in opciones.categorias)
            _Chip(
              key: FeedKeys.filtro(categoria.nombre),
              texto: categoria.nombre,
              activo: filtros.categoriaId == categoria.id,
              onTap: () => onCategoria(categoria.id),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.texto,
    required this.activo,
    required this.onTap,
    this.icono,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final Color color = activo ? AppColores.sobrePrimario : AppColores.texto;
    final IconData? iconoChip = icono;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: activo ? AppColores.primario : AppColores.superficie,
        shape: StadiumBorder(
          side: activo ? BorderSide.none : const BorderSide(color: AppColores.borde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconoChip != null) ...[
                  Icon(iconoChip, size: 16, color: activo ? AppColores.acento : AppColores.primario),
                  const SizedBox(width: 6),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    texto,
                    overflow: TextOverflow.ellipsis,
                    style: AppTexto.cuerpo(size: 13, peso: FontWeight.w500, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista del Feed con sus estados (HU-04, Escenarios 1 a 6; HU-05,
/// Escenarios 6, 8 y 9).
class _ListaFeed extends StatelessWidget {
  const _ListaFeed({required this.onLimpiarFiltros});

  final VoidCallback onLimpiarFiltros;

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
      // Cambiar solo las opciones de los filtros no redibuja la lista.
      buildWhen: (anterior, actual) =>
          anterior.runtimeType != actual.runtimeType || anterior.conOpciones(actual.opciones) != actual,
      builder: (context, state) {
        if (state is FeedError) {
          return AvisoPantalla(
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
        if (state is FeedSinResultados) {
          // TODO(diseño): ilustración de "sin resultados".
          return RefreshIndicator(
            color: AppColores.primario,
            onRefresh: cubit.actualizar,
            child: AvisoPantalla(
              key: FeedKeys.sinResultados,
              icono: Icons.search_off_rounded,
              titulo: 'Sin resultados',
              texto: FeedSinResultados.mensaje,
              accion: PrimaryButton(
                key: FeedKeys.limpiarFiltrosSinResultadosBoton,
                texto: 'Limpiar filtros',
                onPressed: onLimpiarFiltros,
              ),
            ),
          );
        }
        if (state is FeedVacio) {
          // TODO(diseño): ilustración del Feed vacío.
          return RefreshIndicator(
            color: AppColores.primario,
            onRefresh: cubit.actualizar,
            child: const AvisoPantalla(
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
