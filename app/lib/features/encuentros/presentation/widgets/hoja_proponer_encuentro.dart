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
/// Solo deja elegir un lugar del catálogo oficial, un día de lunes a
/// viernes y un horario permitido. No hay campos para escribir.
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
            20,
            AppMedidas.margen,
            AppMedidas.margen + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Proponer punto de encuentro', style: AppTexto.titulo(size: 20)),
                const SizedBox(height: 4),
                Text(
                  'Solo se permiten zonas seguras dentro de la UTSJR, de lunes a viernes de 7:00 a 20:00.',
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
    return <Widget>[
      Text('Lugar', style: AppTexto.etiqueta()),
      const SizedBox(height: 6),
      for (final PuntoEncuentro p in state.puntos)
        _OpcionLugar(punto: p, elegido: state.punto?.id == p.id, onTap: () => cubit.elegirPunto(p)),
      const SizedBox(height: 16),
      Text('Día', style: AppTexto.etiqueta()),
      const SizedBox(height: 6),
      if (state.dias.isEmpty)
        Text('No hay días disponibles.', key: EncuentroKeys.hojaSinHorarios, style: AppTexto.cuerpo(size: 14))
      else
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.dias.length,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final DateTime d = state.dias[i];
              return ChoiceChip(
                key: EncuentroKeys.dia(d),
                label: Text(HorarioEncuentro.formatearDiaCorto(d)),
                selected: state.dia == d,
                onSelected: (_) => cubit.elegirDia(d),
                selectedColor: AppColores.primarioSuave,
              );
            },
          ),
        ),
      const SizedBox(height: 16),
      Text('Hora', style: AppTexto.etiqueta()),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final DateTime h in state.horas)
            ChoiceChip(
              key: EncuentroKeys.hora(h),
              label: Text(HorarioEncuentro.formatearHora(h)),
              selected: state.hora == h,
              onSelected: (_) => cubit.elegirHora(h),
              selectedColor: AppColores.primarioSuave,
            ),
        ],
      ),
      if (error != null) ...[
        const SizedBox(height: 12),
        Text(error, key: EncuentroKeys.hojaMensajeError, style: AppTexto.cuerpo(size: 14, color: AppColores.error)),
      ],
      const SizedBox(height: 20),
      PrimaryButton(
        key: EncuentroKeys.enviarPropuesta,
        texto: 'Enviar propuesta',
        cargando: state.enviando,
        onPressed: state.completa ? () => _enviar(context) : null,
      ),
    ];
  }
}

/// Un lugar del catálogo.
// TODO(diseño): opciones de lugar según Figma.
class _OpcionLugar extends StatelessWidget {
  const _OpcionLugar({required this.punto, required this.elegido, required this.onTap});

  final PuntoEncuentro punto;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: elegido ? AppColores.primarioSuave : AppColores.fondo,
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        child: InkWell(
          key: EncuentroKeys.punto(punto.id),
          borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  elegido ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: AppColores.primario,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(punto.nombre, style: AppTexto.subtitulo(size: 15)),
                      if (punto.referencia.isNotEmpty) Text(punto.referencia, style: AppTexto.cuerpo(size: 13)),
                    ],
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
