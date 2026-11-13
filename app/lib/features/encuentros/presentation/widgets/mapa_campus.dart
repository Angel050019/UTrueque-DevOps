import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/punto_encuentro.dart';
import '../encuentro_keys.dart';

/// Mapa del campus de la UTSJR (HU-08): la imagen, dónde está cada lugar
/// del catálogo y su ícono. Lo usan la hoja para proponer (para ELEGIR el
/// lugar tocando el mapa) y las tarjetas del chat (minimapa).
///
/// Las posiciones son fracciones del ancho y del alto de la imagen
/// (0 = izquierda o arriba, 1 = derecha o abajo). Es solo para dibujar: el
/// catálogo vive en la base de datos. Un lugar nuevo del catálogo que no
/// esté aquí aparece como botón debajo del mapa.
// TODO(diseño): si cambia la imagen del mapa, hay que volver a medir las posiciones.
abstract final class MapaCampus {
  static const String imagen = 'assets/images/mapa_utsjr.jpg';

  /// Ancho / alto de la imagen (1720 x 1120 px).
  static const double proporcion = 1720 / 1120;

  static const Map<String, Offset> ubicaciones = <String, Offset>{
    'biblioteca': Offset(0.320, 0.4375), // Edificio H
    'cafeteria': Offset(0.401, 0.539), // Número 5
    'centro-cultural': Offset(0.337, 0.629), // Número 1
    'centro-investigacion': Offset(0.233, 0.461), // Número 2
    'edificio-k': Offset(0.091, 0.723),
    'explanada': Offset(0.502, 0.786),
    'acceso': Offset(0.535, 0.902),
    'gimnasio': Offset(0.721, 0.396), // Número 4
    'cancha': Offset(0.709, 0.116), // Número 3
  };

  static IconData iconoDe(String id) => switch (id) {
        'biblioteca' => Icons.local_library_rounded,
        'cafeteria' => Icons.local_cafe_rounded,
        'centro-cultural' => Icons.theater_comedy_rounded,
        'centro-investigacion' => Icons.science_rounded,
        'edificio-k' => Icons.apartment_rounded,
        'explanada' => Icons.flag_rounded,
        'acceso' => Icons.shield_rounded,
        'gimnasio' => Icons.sports_basketball_rounded,
        'cancha' => Icons.sports_soccer_rounded,
        _ => Icons.place_rounded,
      };
}

/// Mapa para ELEGIR el lugar: cada lugar del catálogo es un pin que se
/// toca. El elegido crece, se pone verde menta y muestra su nombre. Se
/// puede acercar con dos dedos o abrir en pantalla completa.
class MapaCampusInteractivo extends StatelessWidget {
  const MapaCampusInteractivo({super.key, required this.puntos, required this.elegido, required this.onElegir});

  final List<PuntoEncuentro> puntos;
  final PuntoEncuentro? elegido;
  final ValueChanged<PuntoEncuentro> onElegir;

  Future<void> _ampliar(BuildContext context) async {
    final PuntoEncuentro? p = await showDialog<PuntoEncuentro>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: AppColores.primarioOscuro,
        child: _MapaAmpliado(puntos: puntos, elegido: elegido),
      ),
    );
    if (p != null) onElegir(p);
  }

  @override
  Widget build(BuildContext context) {
    final PuntoEncuentro? sel = elegido;
    final List<PuntoEncuentro> fueraDelMapa =
        puntos.where((p) => !MapaCampus.ubicaciones.containsKey(p.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
            boxShadow: const [BoxShadow(color: Color(0x26033B56), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
            child: AspectRatio(
              aspectRatio: MapaCampus.proporcion,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      maxScale: 3,
                      child: _CapaMapa(puntos: puntos, elegidoId: sel?.id, onTap: onElegir, conKeys: true),
                    ),
                  ),
                  if (sel == null)
                    const Positioned(
                      left: 10,
                      top: 10,
                      child: _Globo(texto: 'Toca un punto para elegirlo', icono: Icons.touch_app_rounded),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: AppColores.superficie.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: EncuentroKeys.ampliarMapa,
                        tooltip: 'Ver el mapa en grande',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _ampliar(context),
                        icon: const Icon(Icons.open_in_full_rounded, size: 18, color: AppColores.primario),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _InfoLugar(punto: sel),
        if (fueraDelMapa.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final PuntoEncuentro p in fueraDelMapa)
                ChoiceChip(
                  key: EncuentroKeys.punto(p.id),
                  avatar: Icon(MapaCampus.iconoDe(p.id), size: 18, color: AppColores.primario),
                  label: Text(p.nombre),
                  selected: p.id == sel?.id,
                  onSelected: (_) => onElegir(p),
                  selectedColor: AppColores.primarioSuave,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// El mapa en pantalla completa. Al tocar un pin se cierra y regresa ese
/// lugar.
class _MapaAmpliado extends StatefulWidget {
  const _MapaAmpliado({required this.puntos, required this.elegido});

  final List<PuntoEncuentro> puntos;
  final PuntoEncuentro? elegido;

  @override
  State<_MapaAmpliado> createState() => _MapaAmpliadoState();
}

class _MapaAmpliadoState extends State<_MapaAmpliado> {
  late PuntoEncuentro? _elegido = widget.elegido;

  @override
  Widget build(BuildContext context) {
    final PuntoEncuentro? sel = _elegido;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColores.sobrePrimario),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Mapa del campus',
                    style: AppTexto.titulo(size: 18, color: AppColores.sobrePrimario),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: AspectRatio(
                  aspectRatio: MapaCampus.proporcion,
                  child: _CapaMapa(
                    puntos: widget.puntos,
                    elegidoId: sel?.id,
                    onTap: (p) => setState(() => _elegido = p),
                    conKeys: false,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppMedidas.margen),
            decoration: const BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppMedidas.radioTarjeta)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoLugar(punto: sel),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: sel == null ? null : () => Navigator.of(context).pop(sel),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColores.primario,
                    foregroundColor: AppColores.sobrePrimario,
                    minimumSize: const Size.fromHeight(AppMedidas.altoBoton),
                  ),
                  child: const Text('Elegir este lugar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La imagen del mapa con un pin por cada lugar del catálogo que tiene
/// posición. El elegido se dibuja al final (encima) con su nombre.
class _CapaMapa extends StatelessWidget {
  const _CapaMapa({required this.puntos, required this.elegidoId, required this.onTap, required this.conKeys});

  final List<PuntoEncuentro> puntos;
  final String? elegidoId;
  final ValueChanged<PuntoEncuentro> onTap;

  /// Solo el mapa de la hoja lleva las Keys de los pines (en la vista
  /// ampliada se repetirían).
  final bool conKeys;

  static const double _pin = 40;
  static const double _anchoEtiqueta = 180;

  @override
  Widget build(BuildContext context) {
    final List<PuntoEncuentro> enMapa = puntos.where((p) => MapaCampus.ubicaciones.containsKey(p.id)).toList()
      ..sort((a, b) => (a.id == elegidoId ? 1 : 0).compareTo(b.id == elegidoId ? 1 : 0));
    return LayoutBuilder(
      builder: (context, medidas) {
        final double w = medidas.maxWidth;
        final double h = medidas.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                MapaCampus.imagen,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                semanticLabel: 'Mapa del campus de la UTSJR',
              ),
            ),
            for (final PuntoEncuentro p in enMapa) ...[
              if (p.id == elegidoId)
                Positioned(
                  left: math.max(4.0, math.min(MapaCampus.ubicaciones[p.id]!.dx * w - _anchoEtiqueta / 2, w - _anchoEtiqueta - 4)),
                  top: math.max(4.0, MapaCampus.ubicaciones[p.id]!.dy * h - _pin / 2 - 32),
                  width: _anchoEtiqueta,
                  child: Center(child: _Globo(texto: p.nombre)),
                ),
              Positioned(
                left: MapaCampus.ubicaciones[p.id]!.dx * w - _pin / 2,
                top: MapaCampus.ubicaciones[p.id]!.dy * h - _pin / 2,
                child: PinLugar(
                  key: conKeys ? EncuentroKeys.punto(p.id) : null,
                  puntoId: p.id,
                  nombre: p.nombre,
                  elegido: p.id == elegidoId,
                  onTap: () => onTap(p),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Un pin del mapa: círculo con el ícono del lugar. El área para tocar es
/// de 40 x 40 aunque el círculo se vea más chico.
class PinLugar extends StatelessWidget {
  const PinLugar({super.key, required this.puntoId, required this.nombre, this.elegido = false, this.onTap});

  final String puntoId;
  final String nombre;
  final bool elegido;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: elegido,
      label: nombre,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: _CapaMapa._pin,
          height: _CapaMapa._pin,
          child: Center(
            child: AnimatedScale(
              scale: elegido ? 1.35 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: elegido ? AppColores.acento : AppColores.primario,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColores.superficie, width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Icon(
                  MapaCampus.iconoDe(puntoId),
                  size: 14,
                  color: elegido ? AppColores.primarioOscuro : AppColores.sobrePrimario,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimapa para las tarjetas del chat: un recorte del mapa alrededor del
/// lugar, con su pin. Si el lugar no tiene posición, no dibuja nada.
class MiniMapaCampus extends StatelessWidget {
  const MiniMapaCampus({super.key, required this.puntoId, required this.nombre, this.alto = 110});

  final String puntoId;
  final String nombre;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final Offset? u = MapaCampus.ubicaciones[puntoId];
    if (u == null) return const SizedBox.shrink();
    // Con BoxFit.none y esta alineación, el punto (u) de la imagen queda en
    // el mismo punto relativo del recuadro; ahí se dibuja el pin.
    final Alignment alineacion = Alignment(u.dx * 2 - 1, u.dy * 2 - 1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
      child: SizedBox(
        height: alto,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, medidas) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    MapaCampus.imagen,
                    fit: BoxFit.none,
                    alignment: alineacion,
                    scale: 2.2,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: 'Ubicación de $nombre en el campus',
                  ),
                ),
                Positioned(
                  left: u.dx * medidas.maxWidth - _CapaMapa._pin / 2,
                  top: u.dy * medidas.maxHeight - _CapaMapa._pin / 2,
                  child: PinLugar(puntoId: puntoId, nombre: nombre, elegido: true),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Globo de texto sobre el mapa (nombre del lugar elegido o la indicación).
class _Globo extends StatelessWidget {
  const _Globo({required this.texto, this.icono});

  final String texto;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final IconData? i = icono;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColores.primarioOscuro.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (i != null) ...[
            Icon(i, size: 14, color: AppColores.acento),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTexto.subtitulo(size: 11, color: AppColores.sobrePrimario),
            ),
          ),
        ],
      ),
    );
  }
}

/// Debajo del mapa: el lugar elegido con su referencia, o qué hacer.
class _InfoLugar extends StatelessWidget {
  const _InfoLugar({required this.punto});

  final PuntoEncuentro? punto;

  @override
  Widget build(BuildContext context) {
    final PuntoEncuentro? p = punto;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey<String?>(p?.id),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p == null ? AppColores.fondo : AppColores.primarioSuave,
          borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: p == null ? AppColores.superficie : AppColores.primario,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                p == null ? Icons.touch_app_rounded : MapaCampus.iconoDe(p.id),
                size: 20,
                color: p == null ? AppColores.textoSecundario : AppColores.acento,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: p == null
                  ? Text('Toca un punto del mapa para elegir dónde se verán.', style: AppTexto.cuerpo(size: 13))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombre, style: AppTexto.subtitulo(size: 14)),
                        if (p.referencia.isNotEmpty) Text(p.referencia, style: AppTexto.cuerpo(size: 12)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
