import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../chat/domain/entities/conversacion.dart';
import '../../domain/entities/encuentro.dart';
import '../../domain/entities/punto_encuentro.dart';
import '../../domain/repositories/encuentros_repository.dart';
import '../../domain/usecases/enviar_solicitud_encuentro.dart';
import '../../domain/usecases/obtener_puntos_encuentro.dart';
import '../../domain/validators/horario_encuentro.dart';
import '../cubit/propuesta_encuentro_cubit.dart';
import '../cubit/propuesta_encuentro_state.dart';
import '../encuentro_keys.dart';

/// Hoja "Proponer punto de encuentro" (HU-08, Escenarios 1, 5 y 6).
///
/// Tres pasos: lugar (se toca en el mapa del campus), día y hora (agrupada en
/// mañana, mediodía y tarde). Solo deja elegir un lugar del catálogo
/// oficial, un día de lunes a viernes y un horario permitido. No hay
/// campos para escribir.
///
/// Solo dibuja el estado del [PropuestaEncuentroCubit].
class HojaProponerEncuentro extends StatelessWidget {
  const HojaProponerEncuentro({super.key});

  /// Abre la hoja con su propio Cubit. Devuelve `true` si se envió la
  /// propuesta. Arma los casos de uso con el repositorio y la red que
  /// están en el árbol (ver main.dart).
  static Future<bool> abrir(BuildContext context, {required Conversacion conversacion, Encuentro? encuentroActivo}) async {
    final EncuentrosRepository repositorio = context.read<EncuentrosRepository>();
    final NetworkInfo red = context.read<NetworkInfo>();
    final bool? enviada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppMedidas.radioTarjeta)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => PropuestaEncuentroCubit(
          conversacion: conversacion,
          obtenerPuntos: ObtenerPuntosEncuentro(repositorio, red),
          enviarSolicitud: EnviarSolicitudEncuentro(repositorio, red),
          encuentroActivo: encuentroActivo,
        )..cargar(),
        child: const HojaProponerEncuentro(),
      ),
    );
    return enviada ?? false;
  }

  Future<void> _enviar(BuildContext context) async {
    final bool enviada = await context.read<PropuestaEncuentroCubit>().enviar();
    if (enviada && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropuestaEncuentroCubit, PropuestaEncuentroState>(
      builder: (context, state) {
        final PropuestaEncuentroCubit cubit = context.read<PropuestaEncuentroCubit>();
        return Padding(
          key: EncuentroKeys.hoja,
          padding: EdgeInsets.fromLTRB(
            AppMedidas.margen,
            0,
            AppMedidas.margen,
            AppMedidas.margen + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColores.acentoSuave,
                        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                      ),
                      child: const Icon(Icons.place_rounded, color: AppColores.primario),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Proponer punto de encuentro', style: AppTexto.titulo(size: 20))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Solo zonas seguras dentro de la UTSJR, de lunes a viernes de 7:00 a 20:00.',
                  style: AppTexto.cuerpo(size: 13),
                ),
                const SizedBox(height: 16),
                ..._contenido(context, state, cubit),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _contenido(BuildContext context, PropuestaEncuentroState state, PropuestaEncuentroCubit cubit) {
    if (state.cargando) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(key: EncuentroKeys.hojaCargando, color: AppColores.primario)),
        ),
      ];
    }
    final String? errorCatalogo = state.errorCatalogo;
    if (errorCatalogo != null) {
      return <Widget>[
        Text(errorCatalogo, key: EncuentroKeys.hojaError, style: AppTexto.cuerpo(size: 14, color: AppColores.error)),
        const SizedBox(height: 12),
        SecondaryButton(key: EncuentroKeys.hojaReintentar, texto: 'Reintentar', onPressed: cubit.cargar),
      ];
    }
    final String? error = state.error;
    final PuntoEncuentro? punto = state.punto;
    final DateTime? dia = state.dia;
    final DateTime? hora = state.hora;
    return <Widget>[
      const _Paso(numero: 1, titulo: 'Toca el lugar en el mapa'),
      const SizedBox(height: 10),
      _MapaCampus(puntos: state.puntos, elegido: punto, onElegir: cubit.elegirPunto),
      const SizedBox(height: 20),
      const _Paso(numero: 2, titulo: 'Día'),
      const SizedBox(height: 10),
      if (state.dias.isEmpty)
        Text('No hay días disponibles.', key: EncuentroKeys.hojaSinHorarios, style: AppTexto.cuerpo(size: 14))
      else
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.dias.length,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final DateTime d = state.dias[i];
              return _TarjetaDia(
                key: EncuentroKeys.dia(d),
                dia: d,
                elegido: dia == d,
                onTap: () => cubit.elegirDia(d),
              );
            },
          ),
        ),
      const SizedBox(height: 20),
      const _Paso(numero: 3, titulo: 'Hora'),
      const SizedBox(height: 10),
      _SelectorHora(
        // Al cambiar de día, el selector vuelve a empezar en el primer bloque con horarios.
        key: ValueKey<DateTime?>(dia),
        horas: state.horas,
        elegida: hora,
        onElegir: cubit.elegirHora,
      ),
      if (punto != null && dia != null && hora != null) ...[
        const SizedBox(height: 20),
        _Resumen(punto: punto, dia: dia, hora: hora),
      ],
      if (error != null) ...[
        const SizedBox(height: 12),
        Text(error, key: EncuentroKeys.hojaMensajeError, style: AppTexto.cuerpo(size: 14, color: AppColores.error)),
      ],
      const SizedBox(height: 16),
      PrimaryButton(
        key: EncuentroKeys.enviarPropuesta,
        texto: 'Enviar propuesta',
        cargando: state.enviando,
        onPressed: state.completa ? () => _enviar(context) : null,
      ),
    ];
  }
}

/// Encabezado de cada paso: un círculo con el número y el título.
class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.titulo});

  final int numero;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColores.primario, shape: BoxShape.circle),
          child: Text('$numero', style: AppTexto.subtitulo(size: 12, color: AppColores.sobrePrimario)),
        ),
        const SizedBox(width: 10),
        Text(titulo, style: AppTexto.subtitulo(size: 15)),
      ],
    );
  }
}

/// Dónde está cada lugar en el mapa del campus, como fracción del ancho y
/// del alto de la imagen (0 = izquierda o arriba, 1 = derecha o abajo).
/// Es solo para dibujar; el catálogo vive en la base de datos. Un lugar
/// nuevo del catálogo que no esté aquí aparece abajo del mapa como botón.
// TODO(diseño): si cambia la imagen del mapa, hay que volver a medir estas posiciones.
const Map<String, Offset> _ubicacionEnMapa = <String, Offset>{
  'biblioteca': Offset(0.468, 0.294), // Edificio H
  'cafeteria': Offset(0.555, 0.387),
  'edificio-k': Offset(0.121, 0.628),
  'explanada': Offset(0.718, 0.774),
  'acceso': Offset(0.847, 0.897),
};

/// Ícono de cada lugar del catálogo.
IconData _iconoDe(String id) => switch (id) {
      'biblioteca' => Icons.local_library_rounded,
      'cafeteria' => Icons.local_cafe_rounded,
      'edificio-k' => Icons.apartment_rounded,
      'explanada' => Icons.flag_rounded,
      'acceso' => Icons.shield_rounded,
      _ => Icons.place_rounded,
    };

/// Mapa del campus para ELEGIR el lugar: cada lugar del catálogo es un pin
/// que se toca. El elegido crece, cambia a verde menta y muestra su nombre.
/// Se puede acercar con dos dedos.
class _MapaCampus extends StatelessWidget {
  const _MapaCampus({required this.puntos, required this.elegido, required this.onElegir});

  final List<PuntoEncuentro> puntos;
  final PuntoEncuentro? elegido;
  final ValueChanged<PuntoEncuentro> onElegir;

  static const double _proporcion = 1240 / 892;
  static const double _pin = 44;
  static const double _anchoEtiqueta = 170;

  @override
  Widget build(BuildContext context) {
    final PuntoEncuentro? sel = elegido;
    final List<PuntoEncuentro> enMapa = puntos.where((p) => _ubicacionEnMapa.containsKey(p.id)).toList();
    final List<PuntoEncuentro> fueraDelMapa = puntos.where((p) => !_ubicacionEnMapa.containsKey(p.id)).toList();
    // El elegido se dibuja al final para que quede encima de los demás.
    enMapa.sort((a, b) => (a.id == sel?.id ? 1 : 0).compareTo(b.id == sel?.id ? 1 : 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
            border: Border.all(color: AppColores.borde),
            boxShadow: const [BoxShadow(color: Color(0x1A033B56), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
            child: AspectRatio(
              aspectRatio: _proporcion,
              child: InteractiveViewer(
                maxScale: 3,
                child: LayoutBuilder(
                  builder: (context, medidas) {
                    final double w = medidas.maxWidth;
                    final double h = medidas.maxHeight;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/mapa_utsjr.jpg',
                            fit: BoxFit.cover,
                            semanticLabel: 'Mapa del campus de la UTSJR',
                          ),
                        ),
                        // Velo suave para que los pines resalten sobre el dibujo.
                        Positioned.fill(child: ColoredBox(color: AppColores.primarioOscuro.withValues(alpha: 0.12))),
                        if (sel == null)
                          const Positioned(
                            left: 10,
                            top: 10,
                            child: _Globo(texto: 'Toca un punto para elegirlo', icono: Icons.touch_app_rounded),
                          ),
                        for (final PuntoEncuentro p in enMapa) ...[
                          if (p.id == sel?.id)
                            Positioned(
                              left: math.max(4.0, math.min(_ubicacionEnMapa[p.id]!.dx * w - _anchoEtiqueta / 2, w - _anchoEtiqueta - 4)),
                              top: math.max(4.0, _ubicacionEnMapa[p.id]!.dy * h - _pin / 2 - 30),
                              width: _anchoEtiqueta,
                              child: Center(child: _Globo(texto: p.nombre)),
                            ),
                          Positioned(
                            left: _ubicacionEnMapa[p.id]!.dx * w - _pin / 2,
                            top: _ubicacionEnMapa[p.id]!.dy * h - _pin / 2,
                            child: _PinLugar(
                              key: EncuentroKeys.punto(p.id),
                              punto: p,
                              elegido: p.id == sel?.id,
                              onTap: () => onElegir(p),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
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
                  avatar: Icon(_iconoDe(p.id), size: 18, color: AppColores.primario),
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

/// Un pin del mapa: círculo con el ícono del lugar. El área para tocar es
/// de 44 x 44 aunque el círculo se vea más chico.
class _PinLugar extends StatelessWidget {
  const _PinLugar({super.key, required this.punto, required this.elegido, required this.onTap});

  final PuntoEncuentro punto;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: punto.nombre,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: _MapaCampus._pin,
          height: _MapaCampus._pin,
          child: Center(
            child: AnimatedScale(
              scale: elegido ? 1.3 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: elegido ? AppColores.acento : AppColores.primario,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColores.superficie, width: 2.5),
                  boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Icon(
                  _iconoDe(punto.id),
                  size: 16,
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
                p == null ? Icons.touch_app_rounded : _iconoDe(p.id),
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

/// Un día: abreviatura arriba ("mié") y número abajo ("18").
class _TarjetaDia extends StatelessWidget {
  const _TarjetaDia({super.key, required this.dia, required this.elegido, required this.onTap});

  final DateTime dia;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<String> partes = HorarioEncuentro.formatearDiaCorto(dia).split(' ');
    final String nombre = partes.first;
    final String numero = partes.length > 1 ? partes[1] : '';
    final Color texto = elegido ? AppColores.sobrePrimario : AppColores.texto;
    return Material(
      color: elegido ? AppColores.primario : AppColores.fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        side: BorderSide(color: elegido ? AppColores.primario : AppColores.borde),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(nombre, style: AppTexto.cuerpo(size: 12, color: elegido ? AppColores.acento : AppColores.textoSecundario)),
              Text(numero, style: AppTexto.subtitulo(size: 18, color: texto)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloques del día para no mostrar todas las horas sueltas.
enum _Bloque {
  manana('Mañana', '7:00 - 11:30', 0, 12),
  mediodia('Mediodía', '12:00 - 15:30', 12, 16),
  tarde('Tarde', '16:00 - 20:00', 16, 24);

  const _Bloque(this.nombre, this.rango, this.desde, this.hasta);

  final String nombre;
  final String rango;

  /// Hora de inicio (incluida) y de fin (sin incluir), en hora de la universidad.
  final int desde;
  final int hasta;

  bool contiene(DateTime hora) {
    final int h = int.parse(HorarioEncuentro.formatearHora(hora).split(':').first);
    return h >= desde && h < hasta;
  }
}

/// Selector de hora: primero el bloque (mañana, mediodía o tarde) y después
/// solo las horas de ese bloque, en una cuadrícula de cuatro columnas.
class _SelectorHora extends StatefulWidget {
  const _SelectorHora({super.key, required this.horas, required this.elegida, required this.onElegir});

  final List<DateTime> horas;
  final DateTime? elegida;
  final ValueChanged<DateTime> onElegir;

  @override
  State<_SelectorHora> createState() => _SelectorHoraState();
}

class _SelectorHoraState extends State<_SelectorHora> {
  late _Bloque _bloque = _bloqueInicial();

  _Bloque _bloqueInicial() {
    final DateTime? elegida = widget.elegida;
    if (elegida != null) {
      for (final _Bloque b in _Bloque.values) {
        if (b.contiene(elegida)) return b;
      }
    }
    for (final _Bloque b in _Bloque.values) {
      if (widget.horas.any(b.contiene)) return b;
    }
    return _Bloque.manana;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.horas.isEmpty) {
      return Text('Elige un día para ver los horarios.', style: AppTexto.cuerpo(size: 14));
    }
    final List<DateTime> visibles = widget.horas.where(_bloque.contiene).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColores.fondo,
            borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
            border: Border.all(color: AppColores.borde),
          ),
          child: Row(
            children: [
              for (final _Bloque b in _Bloque.values)
                Expanded(
                  child: _PestanaBloque(
                    bloque: b,
                    elegido: b == _bloque,
                    habilitado: widget.horas.any(b.contiene),
                    onTap: () => setState(() => _bloque = b),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (visibles.isEmpty)
          Text('Ya no hay horarios en este bloque.', style: AppTexto.cuerpo(size: 14))
        else
          LayoutBuilder(
            builder: (context, medidas) {
              const double espacio = 8;
              final double ancho = (medidas.maxWidth - espacio * 3) / 4;
              return Wrap(
                spacing: espacio,
                runSpacing: espacio,
                children: [
                  for (final DateTime h in visibles)
                    _BotonHora(
                      key: EncuentroKeys.hora(h),
                      ancho: ancho,
                      hora: h,
                      elegida: widget.elegida == h,
                      onTap: () => widget.onElegir(h),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// Una pestaña del selector de bloque.
class _PestanaBloque extends StatelessWidget {
  const _PestanaBloque({required this.bloque, required this.elegido, required this.habilitado, required this.onTap});

  final _Bloque bloque;
  final bool elegido;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titulo = !habilitado
        ? AppColores.borde
        : elegido
            ? AppColores.sobrePrimario
            : AppColores.texto;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: elegido ? AppColores.primario : Colors.transparent,
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo - 4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo - 4),
        onTap: habilitado ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(bloque.nombre, style: AppTexto.subtitulo(size: 13, color: titulo)),
              Text(
                bloque.rango,
                style: AppTexto.cuerpo(
                  size: 11,
                  color: !habilitado
                      ? AppColores.borde
                      : elegido
                          ? AppColores.acento
                          : AppColores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un horario, del mismo ancho que los demás.
class _BotonHora extends StatelessWidget {
  const _BotonHora({super.key, required this.ancho, required this.hora, required this.elegida, required this.onTap});

  final double ancho;
  final DateTime hora;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: 42,
      child: Material(
        color: elegida ? AppColores.primario : AppColores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: elegida ? AppColores.primario : AppColores.borde),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(
            child: Text(
              HorarioEncuentro.formatearHora(hora),
              style: AppTexto.subtitulo(size: 14, color: elegida ? AppColores.sobrePrimario : AppColores.texto),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resumen de lo elegido, antes de enviar.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.punto, required this.dia, required this.hora});

  final PuntoEncuentro punto;
  final DateTime dia;
  final DateTime hora;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColores.acentoSuave,
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        border: Border.all(color: AppColores.acento),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: AppColores.primario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(punto.nombre, style: AppTexto.subtitulo(size: 14)),
                Text(
                  '${HorarioEncuentro.formatearDia(dia)} · ${HorarioEncuentro.formatearHora(hora)}',
                  style: AppTexto.cuerpo(size: 13, color: AppColores.texto),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
