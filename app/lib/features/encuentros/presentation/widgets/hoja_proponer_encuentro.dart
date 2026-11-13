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
import 'mapa_campus.dart';

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
      MapaCampusInteractivo(puntos: state.puntos, elegido: punto, onElegir: cubit.elegirPunto),
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
