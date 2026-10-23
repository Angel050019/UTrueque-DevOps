import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../../../core/utils/formato_precio.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/aviso_pantalla.dart';
import '../../../../core/widgets/en_desarrollo_page.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/publicacion.dart';
import '../cubit/detalle_publicacion_cubit.dart';
import '../cubit/detalle_publicacion_state.dart';
import '../detalle_keys.dart';
import '../widgets/etiqueta_publicacion.dart';

/// Qué hacer cuando el Detalle descubre el estado actual de la publicación:
/// [actual] es la publicación como está hoy, o `null` si ya se borró.
typedef AlCambiarPublicacion = void Function(String id, Publicacion? actual);

/// Datos que recibe la ruta del Detalle.
class DetallePublicacionArgs {
  const DetallePublicacionArgs({required this.id, this.alCambiar});

  final String id;
  final AlCambiarPublicacion? alCambiar;
}

/// Detalle de la publicación (HU-04, Escenarios 7 a 10).
///
/// Muestra todas las fotos en un carrusel, el título, el precio o la
/// modalidad, el estado (con su aviso si está Reservada o Vendida), la
/// fecha, la descripción y el perfil público del dueño. "Contactar al
/// vendedor" abre "En desarrollo" (chat, Sprint 7); si la publicación es
/// mía, se muestra "Es tu publicación" y "Gestionar publicación"
/// (Sprint 6).
///
/// Solo dibuja el estado del [DetallePublicacionCubit].
class DetallePublicacionPage extends StatelessWidget {
  const DetallePublicacionPage({super.key, this.alCambiar});

  /// Avisa al Feed si la publicación cambió o se borró.
  final AlCambiarPublicacion? alCambiar;

  /// Abre el Detalle de la publicación con ese [id].
  static Future<void> abrir(
    BuildContext context, {
    required String id,
    AlCambiarPublicacion? alCambiar,
  }) {
    return Navigator.of(context).pushNamed<void>(
      AppRoutes.detallePublicacion,
      arguments: DetallePublicacionArgs(id: id, alCambiar: alCambiar),
    );
  }

  void _escuchar(BuildContext context, DetalleState state) {
    final DetallePublicacionCubit cubit = context.read<DetallePublicacionCubit>();
    if (state is DetalleNoEncontrado) {
      alCambiar?.call(cubit.idPublicacion, null);
    } else if (state is DetalleCargado) {
      alCambiar?.call(cubit.idPublicacion, state.publicacion);
      final String? aviso = state.aviso;
      if (aviso != null) {
        mostrarMensaje(context, aviso, esError: true);
        cubit.avisoMostrado();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DetallePublicacionCubit cubit = context.read<DetallePublicacionCubit>();
    return Scaffold(
      key: DetalleKeys.pantalla,
      body: SafeArea(
        child: BlocConsumer<DetallePublicacionCubit, DetalleState>(
          listener: _escuchar,
          builder: (context, state) {
            final Widget contenido;
            Widget? barraInferior;
            if (state is DetalleCargado) {
              contenido = RefreshIndicator(
                color: AppColores.primario,
                onRefresh: cubit.cargar,
                child: _Contenido(state: state),
              );
              barraInferior = _Acciones(state: state);
            } else if (state is DetalleNoEncontrado) {
              contenido = AvisoPantalla(
                key: DetalleKeys.noEncontrado,
                icono: Icons.search_off_rounded,
                titulo: state.mensaje,
                texto: 'Es posible que su dueño la haya borrado.',
                accion: PrimaryButton(
                  key: DetalleKeys.volverFeedBoton,
                  texto: 'Volver al Feed',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              );
            } else if (state is DetalleError) {
              contenido = AvisoPantalla(
                key: DetalleKeys.error,
                icono: Icons.cloud_off_rounded,
                titulo: 'No pudimos abrir la publicación',
                texto: state.mensaje,
                accion: PrimaryButton(
                  key: DetalleKeys.reintentarBoton,
                  texto: 'Reintentar',
                  onPressed: cubit.cargar,
                ),
              );
            } else {
              contenido = const Center(
                child: CircularProgressIndicator(
                  key: DetalleKeys.cargando,
                  color: AppColores.primario,
                ),
              );
            }
            return Column(
              children: [
                const BarraSuperior(titulo: 'Detalle de la publicación'),
                Expanded(child: contenido),
                if (barraInferior != null) barraInferior,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Fotos, datos de la publicación y perfil del dueño.
class _Contenido extends StatelessWidget {
  const _Contenido({required this.state});

  final DetalleCargado state;

  String get _precioOModalidad {
    final Publicacion publicacion = state.publicacion;
    final double? precio = publicacion.precio;
    if (publicacion.modalidad == Modalidad.venta && precio != null) {
      return formatearPrecio(precio);
    }
    return publicacion.modalidad.etiqueta;
  }

  @override
  Widget build(BuildContext context) {
    final Publicacion publicacion = state.publicacion;
    final DateTime? creada = publicacion.creadaEn;
    final String? aviso = publicacion.estado.aviso;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Carrusel(urls: publicacion.fotosUrls),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 18, AppMedidas.margen, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (publicacion.categoriaNombre != null)
                    EtiquetaPublicacion(
                      texto: publicacion.categoriaNombre!,
                      fondo: AppColores.primarioSuave,
                      color: AppColores.primario,
                    ),
                  EtiquetaPublicacion.estado(publicacion.estado, key: DetalleKeys.estado),
                  if (state.esMia)
                    const EtiquetaPublicacion(
                      key: DetalleKeys.esMiaEtiqueta,
                      texto: 'Es tu publicación',
                      fondo: AppColores.primario,
                      color: AppColores.sobrePrimario,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                publicacion.titulo,
                key: DetalleKeys.titulo,
                style: AppTexto.titulo(size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                _precioOModalidad,
                key: DetalleKeys.precioOModalidad,
                style: AppTexto.titulo(size: 20, color: AppColores.primario),
              ),
              if (aviso != null) ...[
                const SizedBox(height: 14),
                Container(
                  key: DetalleKeys.avisoEstado,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColores.errorSuave,
                    borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColores.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          aviso,
                          style: AppTexto.cuerpo(size: 14, color: AppColores.error, peso: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (creada != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Publicado el ${formatearFecha(creada)}',
                  key: DetalleKeys.fecha,
                  style: AppTexto.cuerpo(size: 13),
                ),
              ],
              const SizedBox(height: 20),
              Text('Descripción', style: AppTexto.subtitulo(size: 16)),
              const SizedBox(height: 6),
              Text(
                publicacion.descripcion,
                key: DetalleKeys.descripcion,
                style: AppTexto.cuerpo(size: 15, color: AppColores.texto),
              ),
              const SizedBox(height: 24),
              Text('Publicado por', style: AppTexto.subtitulo(size: 16)),
              const SizedBox(height: 8),
              _TarjetaDueno(publicacion: publicacion),
            ],
          ),
        ),
      ],
    );
  }
}

/// Carrusel con todas las fotos y el indicador "1 de N".
// TODO(diseño): carrusel según Figma (puntos, esquinas, botón de regreso encima).
class _Carrusel extends StatefulWidget {
  const _Carrusel({required this.urls});

  final List<String> urls;

  @override
  State<_Carrusel> createState() => _CarruselState();
}

class _CarruselState extends State<_Carrusel> {
  int _actual = 0;

  @override
  Widget build(BuildContext context) {
    const Widget sinFoto = ColoredBox(
      color: AppColores.primarioSuave,
      child: Center(child: Icon(Icons.image_outlined, size: 56, color: AppColores.primario)),
    );
    final List<String> urls = widget.urls;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (urls.isEmpty)
            sinFoto
          else
            PageView.builder(
              key: DetalleKeys.carrusel,
              itemCount: urls.length,
              onPageChanged: (pagina) => setState(() => _actual = pagina),
              itemBuilder: (context, i) => Image.network(
                urls[i],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => sinFoto,
                loadingBuilder: (context, child, progreso) => progreso == null
                    ? child
                    : const ColoredBox(
                        color: AppColores.primarioSuave,
                        child: Center(
                          child: CircularProgressIndicator(color: AppColores.primario),
                        ),
                      ),
              ),
            ),
          if (urls.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                key: DetalleKeys.indicadorFotos,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColores.texto.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_actual + 1} de ${urls.length}',
                  style: AppTexto.cuerpo(size: 12, color: AppColores.sobrePrimario, peso: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Perfil público del dueño: foto, nombre, división y carrera.
// TODO(diseño): tarjeta del dueño según Figma.
class _TarjetaDueno extends StatelessWidget {
  const _TarjetaDueno({required this.publicacion});

  final Publicacion publicacion;

  @override
  Widget build(BuildContext context) {
    final String nombre = publicacion.duenoNombre ?? 'Estudiante de la UTSJR';
    final List<String> academico = [
      publicacion.duenoCarrera,
      publicacion.duenoDivision,
    ].whereType<String>().toList(growable: false);
    return Container(
      key: DetalleKeys.dueno,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
        border: Border.all(color: AppColores.borde),
      ),
      child: Row(
        children: [
          AvatarPerfil(fotoUrl: publicacion.duenoFotoUrl, nombre: nombre, radio: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: AppTexto.subtitulo(size: 15)),
                for (final String linea in academico)
                  Text(linea, style: AppTexto.cuerpo(size: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de abajo: "Contactar al vendedor" o, si es mía, "Gestionar
/// publicación". Los dos abren "En desarrollo" por ahora.
// TODO(diseño): botón fijo de abajo según Figma.
class _Acciones extends StatelessWidget {
  const _Acciones({required this.state});

  final DetalleCargado state;

  @override
  Widget build(BuildContext context) {
    final Widget boton;
    if (state.esMia) {
      boton = SecondaryButton(
        key: DetalleKeys.gestionarBoton,
        texto: 'Gestionar publicación',
        onPressed: () => EnDesarrolloPage.abrir(
          context,
          titulo: 'Gestionar publicación',
          mensaje: 'Muy pronto podrás editar tu publicación, marcarla como '
              'Reservada o Vendida, o borrarla.',
          sprint: 'Sprint 6',
        ),
      );
    } else {
      boton = PrimaryButton(
        key: DetalleKeys.contactarBoton,
        texto: 'Contactar al vendedor',
        // Reservada o Vendida: no se puede contactar (patrón State).
        onPressed: state.puedeContactar
            ? () => EnDesarrolloPage.abrir(
                  context,
                  titulo: 'Chat',
                  mensaje: 'Muy pronto podrás escribirle a quien publicó el '
                      'artículo para ponerse de acuerdo.',
                  sprint: 'Sprint 7',
                )
            : null,
      );
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 8, AppMedidas.margen, 12),
        child: boton,
      ),
    );
  }
}
